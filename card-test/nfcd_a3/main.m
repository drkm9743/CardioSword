// nfcd_a3 — NFC Card Emulation Daemon for CardioDS
// Target : iOS 15+, arm64
// Exploit: DarkSword / lara (kernel r/w + sandbox escape required)
//
// Socket protocol  /var/run/a3nfcd.socket  (one command per connection):
//
//   LOAD_UID <hexUID>                  → OK | ERR <msg>
//   LOAD_ATS <hexATS>                  → OK | ERR <msg>
//   APDU_RESP <selectHex> <respHex>    → OK | ERR <msg>
//   CLEAR_CARD                         → OK
//   STATUS                             → READY | EMULATING
//
// The daemon stores card parameters and uses the private CoreNFC HCE
// API (com.apple.private.nfc entitlement) to emulate the card.
// System nfcd is intentionally NOT killed — private HCE classes inside
// CoreNFC.framework still route through it for hardware access.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wundeclared-selector"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <sys/stat.h>
#import <pthread.h>
#import <signal.h>
#import <unistd.h>
#import <errno.h>
#import <string.h>

#pragma clang diagnostic pop

// ─────────────────────────── Constants ───────────────────────────────

#define SOCKET_PATH  "/var/run/a3nfcd.socket"
#define MAX_UID      10
#define MAX_ATS      64
#define MAX_PAIRS    64
#define MAX_APDU     512

// ─────────────────────────── Card state ──────────────────────────────

static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

typedef struct {
    uint8_t b[MAX_APDU];
    size_t  n;
} Bytes;

static struct {
    Bytes uid;
    Bytes ats;
    struct { Bytes sel; Bytes rsp; } pairs[MAX_PAIRS];
    int   pair_count;
    BOOL  emulating;
} g_card;

// Retained HCE session (ARC manages lifetime via __strong).
static __strong id g_hce = nil;

// ─────────────────────────── Private HCE ─────────────────────────────
//
// iOS CoreNFC.framework contains private HCE class(es) enabled by the
// com.apple.private.nfc entitlement.  Exact class names vary by iOS
// version, so we probe a priority list at runtime and fall back to a
// class-dump scan of all loaded images if nothing matches.

static void hce_stop(void) {
    if (!g_hce) return;
    @try {
        for (NSString *sn in @[@"invalidate", @"deactivate", @"stopEmulation"]) {
            SEL s = NSSelectorFromString(sn);
            if ([g_hce respondsToSelector:s]) {
                [g_hce performSelector:s];
                break;
            }
        }
    } @catch (...) {}
    g_hce = nil;
}

// Use NSInvocation to call a class-method with arbitrary object args.
// Returns the result, or nil on failure / missing selector.
static id class_invoke(Class cls, SEL sel, NSArray *args) {
    if (![cls respondsToSelector:sel]) return nil;
    @try {
        NSMethodSignature *sig = [cls methodSignatureForSelector:sel];
        if (!sig) return nil;
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:cls];
        [inv setSelector:sel];
        for (NSUInteger i = 0; i < args.count; i++) {
            id arg = args[i];
            if ([arg isKindOfClass:[NSNull class]]) {
                id nil_arg = nil;
                [inv setArgument:&nil_arg atIndex:(NSInteger)(i + 2)];
            } else {
                [inv setArgument:&arg atIndex:(NSInteger)(i + 2)];
            }
        }
        [inv invoke];
        __unsafe_unretained id ret = nil;
        [inv getReturnValue:&ret];
        return ret;   // ARC retains when assigned to strong variable
    } @catch (NSException *e) {
        NSLog(@"[nfcd_a3] class_invoke %@ threw: %@", NSStringFromSelector(sel), e);
        return nil;
    }
}

static BOOL hce_start(void) {
    hce_stop();
    if (g_card.uid.n == 0) return NO;

    // ── 1. Locate HCE class ───────────────────────────────────────────
    static NSString * const kCandidates[] = {
        @"NFCHostCardEmulationSession",
        @"_NFCHostCardEmulationSession",
        @"NFCCardEmulationSession",
        @"NFCHCESession",
        nil
    };
    Class cls = nil;
    for (int i = 0; kCandidates[i] != nil; i++) {
        cls = NSClassFromString(kCandidates[i]);
        if (cls) { NSLog(@"[nfcd_a3] HCE class: %@", kCandidates[i]); break; }
    }
    if (!cls) {
        // Scan all loaded ObjC classes for anything HCE-like
        unsigned int n = 0;
        Class *all = objc_copyClassList(&n);
        for (unsigned int i = 0; i < n && !cls; i++) {
            NSString *name = NSStringFromClass(all[i]);
            if (([name hasPrefix:@"NFC"] || [name hasPrefix:@"_NFC"]) &&
                ([name containsString:@"HCE"]    ||
                 [name containsString:@"Emulat"] ||
                 [name containsString:@"CardEmu"])) {
                NSLog(@"[nfcd_a3] Discovered candidate: %@", name);
                cls = all[i];
            }
        }
        free(all);
    }
    if (!cls) {
        NSLog(@"[nfcd_a3] No HCE class found – NFC emulation unavailable");
        return NO;
    }

    // ── 2. Build parameters ───────────────────────────────────────────
    NSData *uid = [NSData dataWithBytes:g_card.uid.b length:g_card.uid.n];
    NSData *ats = g_card.ats.n
        ? [NSData dataWithBytes:g_card.ats.b length:g_card.ats.n]
        : nil;
    NSMutableDictionary *apduMap = [NSMutableDictionary new];
    for (int i = 0; i < g_card.pair_count; i++) {
        NSData *s = [NSData dataWithBytes:g_card.pairs[i].sel.b length:g_card.pairs[i].sel.n];
        NSData *r = [NSData dataWithBytes:g_card.pairs[i].rsp.b length:g_card.pairs[i].rsp.n];
        apduMap[s] = r;
    }

    // ── 3. Create session (try factory methods in descending arg count) ─
    struct { NSString *sn; NSArray *args; } tries[] = {
        { @"sessionWithUID:ats:apduResponses:", @[uid, ats ?: [NSNull null], apduMap] },
        { @"sessionWithUID:ats:",               @[uid, ats ?: [NSNull null]] },
        { @"sessionWithUID:",                   @[uid] },
    };
    id session = nil;
    for (size_t i = 0; i < sizeof(tries)/sizeof(*tries) && !session; i++) {
        SEL sel = NSSelectorFromString(tries[i].sn);
        session = class_invoke(cls, sel, tries[i].args);
    }
    if (!session) {
        @try { session = [[cls alloc] init]; } @catch (...) { session = nil; }
    }
    if (!session) {
        NSLog(@"[nfcd_a3] HCE session creation failed");
        return NO;
    }
    g_hce = session;

    // ── 4. Activate ───────────────────────────────────────────────────
    for (NSString *sn in @[@"activate", @"start", @"startEmulation", @"startSession"]) {
        SEL s = NSSelectorFromString(sn);
        if ([session respondsToSelector:s]) {
            @try { [session performSelector:s]; } @catch (...) {}
            NSLog(@"[nfcd_a3] Activated via -%@", sn);
            break;
        }
    }
    NSLog(@"[nfcd_a3] HCE session active UID=%lu bytes", (unsigned long)g_card.uid.n);
    return YES;
}

// ────────────────────────── Hex decode ───────────────────────────────

static ssize_t hex_decode(const char *s, uint8_t *out, size_t cap) {
    size_t len = strlen(s);
    if (len & 1) return -1;
    size_t n = len / 2;
    if (n > cap) return -1;
    for (size_t i = 0; i < n; i++) {
        char hi = s[i*2], lo = s[i*2+1];
        int H = (hi>='0'&&hi<='9') ? hi-'0' : (hi>='a'&&hi<='f') ? hi-'a'+10 : (hi>='A'&&hi<='F') ? hi-'A'+10 : -1;
        int L = (lo>='0'&&lo<='9') ? lo-'0' : (lo>='a'&&lo<='f') ? lo-'a'+10 : (lo>='A'&&lo<='F') ? lo-'A'+10 : -1;
        if (H < 0 || L < 0) return -1;
        out[i] = (uint8_t)((H << 4) | L);
    }
    return (ssize_t)n;
}

// ──────────────────────── Command dispatch ────────────────────────────

static void dispatch_command(int fd, const char *cmd) {
    char resp[256] = "ERR unknown\n";
    pthread_mutex_lock(&g_lock);

    if (strncmp(cmd, "LOAD_UID ", 9) == 0) {
        ssize_t n = hex_decode(cmd + 9, g_card.uid.b, MAX_UID);
        if (n < 0) {
            strlcpy(resp, "ERR bad UID hex\n", sizeof(resp));
        } else {
            g_card.uid.n    = (size_t)n;
            g_card.emulating = hce_start();
            strlcpy(resp, "OK\n", sizeof(resp));
        }

    } else if (strncmp(cmd, "LOAD_ATS ", 9) == 0) {
        ssize_t n = hex_decode(cmd + 9, g_card.ats.b, MAX_ATS);
        if (n < 0) strlcpy(resp, "ERR bad ATS hex\n", sizeof(resp));
        else       { g_card.ats.n = (size_t)n; strlcpy(resp, "OK\n", sizeof(resp)); }

    } else if (strncmp(cmd, "APDU_RESP ", 10) == 0) {
        const char *rest = cmd + 10;
        const char *sp   = strchr(rest, ' ');
        if (!sp || g_card.pair_count >= MAX_PAIRS) {
            strlcpy(resp, "ERR overflow\n", sizeof(resp));
        } else {
            size_t sl = (size_t)(sp - rest);
            if (sl >= MAX_APDU * 2) {
                strlcpy(resp, "ERR select too long\n", sizeof(resp));
            } else {
                char sbuf[MAX_APDU * 2 + 1] = {0};
                memcpy(sbuf, rest, sl);
                int idx = g_card.pair_count;
                ssize_t sn = hex_decode(sbuf,  g_card.pairs[idx].sel.b, MAX_APDU);
                ssize_t rn = hex_decode(sp+1, g_card.pairs[idx].rsp.b, MAX_APDU);
                if (sn < 0 || rn < 0) {
                    strlcpy(resp, "ERR bad APDU hex\n", sizeof(resp));
                } else {
                    g_card.pairs[idx].sel.n = (size_t)sn;
                    g_card.pairs[idx].rsp.n = (size_t)rn;
                    g_card.pair_count++;
                    strlcpy(resp, "OK\n", sizeof(resp));
                }
            }
        }

    } else if (strcmp(cmd, "CLEAR_CARD") == 0) {
        hce_stop();
        memset(&g_card, 0, sizeof(g_card));
        strlcpy(resp, "OK\n", sizeof(resp));

    } else if (strcmp(cmd, "STATUS") == 0) {
        strlcpy(resp, g_card.emulating ? "EMULATING\n" : "READY\n", sizeof(resp));
    }

    pthread_mutex_unlock(&g_lock);
    write(fd, resp, strlen(resp));
}

// ─────────────────────────── Client thread ───────────────────────────

static void *client_fn(void *arg) {
    int fd = (int)(intptr_t)arg;
    char buf[2048];
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';
        // Trim trailing CR/LF
        for (char *p = buf + strlen(buf) - 1; p >= buf && (*p=='\r'||*p=='\n'); p--)
            *p = '\0';
        dispatch_command(fd, buf);
    }
    close(fd);
    return NULL;
}

// ─────────────────────────── Entry point ─────────────────────────────

// Resolved socket path — may be overridden via $A3NFCD_SOCKET env var.
// The parent (ObjcHelper) passes NSTemporaryDirectory()-based path so
// both the spawning process (after sandbox escape) and this sandboxed
// child process can reach the same socket.
static char g_socket_path[PATH_MAX] = SOCKET_PATH;

int main(void) {
    signal(SIGPIPE, SIG_IGN);
    signal(SIGCHLD, SIG_IGN);

    @autoreleasepool {
        // Accept socket path override from parent process.
        const char *envPath = getenv("A3NFCD_SOCKET");
        if (envPath && strlen(envPath) > 0 && strlen(envPath) < sizeof(g_socket_path)) {
            strlcpy(g_socket_path, envPath, sizeof(g_socket_path));
        }

        NSLog(@"[nfcd_a3] v1.0 start pid=%d uid=%d socket=%s",
              getpid(), getuid(), g_socket_path);

        unlink(g_socket_path);

        int srv = socket(AF_UNIX, SOCK_STREAM, 0);
        if (srv < 0) {
            NSLog(@"[nfcd_a3] socket: %s", strerror(errno));
            return 1;
        }

        int one = 1;
        setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));

        struct sockaddr_un sa;
        memset(&sa, 0, sizeof(sa));
        sa.sun_family = AF_UNIX;
        strlcpy(sa.sun_path, g_socket_path, sizeof(sa.sun_path));

        if (bind(srv, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
            NSLog(@"[nfcd_a3] bind: %s", strerror(errno));
            close(srv);
            return 1;
        }

        // World-writable so the app process (any uid) can connect
        chmod(g_socket_path, 0777);

        if (listen(srv, 8) < 0) {
            NSLog(@"[nfcd_a3] listen: %s", strerror(errno));
            close(srv);
            return 1;
        }

        NSLog(@"[nfcd_a3] Listening on %s", g_socket_path);

        for (;;) {
            int cli = accept(srv, NULL, NULL);
            if (cli < 0) {
                if (errno == EINTR) continue;
                NSLog(@"[nfcd_a3] accept: %s", strerror(errno));
                break;
            }
            pthread_t t;
            pthread_attr_t ta;
            pthread_attr_init(&ta);
            pthread_attr_setdetachstate(&ta, PTHREAD_CREATE_DETACHED);
            pthread_create(&t, &ta, client_fn, (void *)(intptr_t)cli);
            pthread_attr_destroy(&ta);
        }

        close(srv);
    }
    return 0;
}
