#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <dirent.h>
#import <fcntl.h>
#import <limits.h>
#import <sys/stat.h>
#import <unistd.h>
#import <sys/socket.h>
#import <sys/un.h>

#import "ObjcHelper.h"
#import "kexploit/kfs.h"

void enumerateProcessesUsingBlock(void (^enumerator)(pid_t pid, NSString* executablePath, BOOL* stop));
void killall(NSString* processName);

typedef const struct CF_BRIDGED_TYPE(id) __SecTask *SecTaskRef;
extern SecTaskRef SecTaskCreateFromSelf(CFAllocatorRef allocator);
extern CFTypeRef _Nullable SecTaskCopyValueForEntitlement(SecTaskRef task, CFStringRef entitlement, CFErrorRef _Nullable * _Nullable error);
#ifndef PROC_PIDPATHINFO_MAXSIZE
#define PROC_PIDPATHINFO_MAXSIZE (4 * PATH_MAX)
#endif

static NSNumber * _Nullable cardioBoolFromEntitlementValue(CFTypeRef _Nullable value) {
    if (value == NULL) {
        return nil;
    }

    NSNumber *result = nil;
    CFTypeID typeID = CFGetTypeID(value);
    if (typeID == CFBooleanGetTypeID()) {
        result = @(CFBooleanGetValue((CFBooleanRef)value));
    } else if (typeID == CFNumberGetTypeID()) {
        result = @(((__bridge NSNumber *)value).boolValue);
    } else if (typeID == CFStringGetTypeID()) {
        NSString *string = [(__bridge NSString *)value lowercaseString];
        if ([string isEqualToString:@"true"] || [string isEqualToString:@"yes"] || [string isEqualToString:@"1"]) {
            result = @YES;
        } else if ([string isEqualToString:@"false"] || [string isEqualToString:@"no"] || [string isEqualToString:@"0"]) {
            result = @NO;
        }
    }

    CFRelease(value);
    return result;
}

@implementation ObjcHelper

-(NSNumber *)getDeviceSubType {
    NSString *plistFullPath = [@"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/" stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFullPath];
    
    NSMutableDictionary *artWork = plistDict[@"CacheExtra"][@"oPeik/9e8lQWMszEjbPzng"];
    
    return artWork[@"ArtworkDeviceSubType"];
}

-(void)updateDeviceSubType:(NSInteger)deviceSubType {
    NSString *plistFullPath = [@"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/" stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFullPath];
    
    [plistDict[@"CacheExtra"][@"oPeik/9e8lQWMszEjbPzng"] setObject:[NSNumber numberWithInteger: deviceSubType] forKey:@"ArtworkDeviceSubType"];
    [plistDict writeToFile:plistFullPath atomically:YES];
}

-(void)imageToCPBitmap:(UIImage *)img path:(NSString *)path {
    [img writeToCPBitmapFile:path flags:1];
}

-(void)respring {
    killall(@"SpringBoard");
    exit(0);
}

-(void)refreshWalletServices {
    killall(@"passd");
    killall(@"walletd");
    killall(@"PassbookUIService");
    // Daemons auto-relaunch. No need to kill SpringBoard or exit.
}

-(UIImage *)getImageFromData:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage imageWithData:data];
    
    return image;
}

-(void)saveImage:(UIImage *)image atPath:(NSString *)path {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
}

-(NSArray<NSString *> *)kfsListDirectory:(NSString *)path {
    if (path.length == 0 || !kfs_can_listdir()) {
        return @[];
    }

    kfs_entry_t *entries = NULL;
    int count = 0;
    int rc = kfs_listdir(path.UTF8String, &entries, &count);
    if (rc != 0 || entries == NULL || count <= 0) {
        if (entries != NULL) {
            kfs_free_listing(entries);
        }
        return @[];
    }

    NSMutableArray<NSString *> *results = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (int i = 0; i < count; i++) {
        NSString *name = [NSString stringWithUTF8String:entries[i].name];
        if (name.length > 0) {
            [results addObject:name];
        }
    }

    kfs_free_listing(entries);
    return results;
}

-(int64_t)kfsFileSizeNC:(NSString *)path {
    if (path.length == 0) return -1;
    return kfs_file_size_nc(path.UTF8String);
}

-(NSArray<NSString *> *)directListDirectory:(NSString *)path {
    if (path.length == 0) {
        return @[];
    }

    DIR *dir = opendir(path.fileSystemRepresentation);
    if (dir == NULL) {
        return @[];
    }

    NSMutableArray<NSString *> *results = [NSMutableArray array];
    struct dirent *entry = NULL;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.' &&
            (entry->d_name[1] == '\0' || (entry->d_name[1] == '.' && entry->d_name[2] == '\0'))) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:entry->d_name];
        if (name.length > 0) {
            [results addObject:name];
        }
    }

    closedir(dir);
    return results;
}

-(NSData * _Nullable)kfsReadFile:(NSString *)path maxSize:(int64_t)maxSize {
    if (path.length == 0 || maxSize <= 0) return nil;

    int64_t fsize = kfs_file_size_nc(path.UTF8String);
    if (fsize <= 0) fsize = maxSize;
    if (fsize > maxSize) fsize = maxSize;

    void *buf = calloc(1, (size_t)fsize);
    if (!buf) return nil;

    int64_t n = kfs_read(path.UTF8String, buf, (size_t)fsize, 0);
    if (n <= 0) {
        free(buf);
        return nil;
    }

    NSData *data = [NSData dataWithBytes:buf length:(NSUInteger)n];
    free(buf);
    return data;
}

-(NSData * _Nullable)directReadFile:(NSString *)path maxSize:(int64_t)maxSize {
    if (path.length == 0 || maxSize <= 0) {
        return nil;
    }

    int fd = open(path.fileSystemRepresentation, O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        return nil;
    }

    NSMutableData *data = [NSMutableData data];
    const size_t chunkSize = 64 * 1024;
    uint8_t buffer[chunkSize];
    int64_t remaining = maxSize;

    while (remaining > 0) {
        size_t requested = (size_t)MIN((int64_t)sizeof(buffer), remaining);
        ssize_t readCount = read(fd, buffer, requested);
        if (readCount <= 0) {
            break;
        }

        [data appendBytes:buffer length:(NSUInteger)readCount];
        remaining -= readCount;
    }

    close(fd);
    return data.length > 0 ? data : nil;
}

-(NSDictionary<NSString *, NSNumber *> *)runtimeEntitlementFlags {
    SecTaskRef task = SecTaskCreateFromSelf(kCFAllocatorDefault);
    if (task == NULL) {
        return @{};
    }

    NSArray<NSString *> *keys = @[
        @"com.apple.private.security.no-sandbox",
        @"com.apple.private.security.no-container",
        @"com.apple.private.security.container-required",
        @"platform-application"
    ];

    NSMutableDictionary<NSString *, NSNumber *> *flags = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    for (NSString *key in keys) {
        NSNumber *value = cardioBoolFromEntitlementValue(
            SecTaskCopyValueForEntitlement(task, (__bridge CFStringRef)key, NULL)
        );
        if (value != nil) {
            flags[key] = value;
        }
    }

    CFRelease(task);
    return flags;
}

-(BOOL)isLikelyLiveContainerGuest {
    return [[NSBundle mainBundle] pathForResource:@"LCAppInfo" ofType:@"plist"] != nil;
}

// MARK: - TSUtil

void enumerateProcessesUsingBlock(void (^enumerator)(pid_t pid, NSString* executablePath, BOOL* stop)) {
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    int count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            NSString* executablePath = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
            
            BOOL stop = NO;
            enumerator(pid, executablePath, &stop);
            if(stop) {
                free(buffer);
                break;
            }
        }
        free(buffer);
        }
    }
    free(info);
}

void killall(NSString* processName) {
    enumerateProcessesUsingBlock(^(pid_t pid, NSString* executablePath, BOOL* stop) {
        if([executablePath.lastPathComponent isEqualToString:processName]) {
            kill(pid, SIGTERM);
        }
    });
}
// MARK: - NFC daemon helpers (file-scope C)

// Dynamic socket path — computed from NSTemporaryDirectory when daemon is launched
// so both the app process and the sandboxed nfcd_a3 child can reach it.
static NSString *g_a3NFCDSocketPath = nil;
static const NSTimeInterval kA3NFCDSocketTimeout = 3.0;

static NSString *a3_socket_path(void) {
    return g_a3NFCDSocketPath ?: @"/var/run/a3nfcd.socket";
}

static NSString * _Nullable a3_nfcd_send_command(NSString *command) {
    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) return nil;

    struct timeval tv;
    tv.tv_sec  = (int)kA3NFCDSocketTimeout;
    tv.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strlcpy(addr.sun_path, a3_socket_path().UTF8String, sizeof(addr.sun_path));

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(sock);
        return nil;
    }

    NSString *line = [command stringByAppendingString:@"\n"];
    const char *buf = line.UTF8String;
    ssize_t sent = write(sock, buf, strlen(buf));
    if (sent <= 0) { close(sock); return nil; }

    char rbuf[512] = {0};
    ssize_t n = read(sock, rbuf, sizeof(rbuf) - 1);
    close(sock);
    if (n <= 0) return nil;

    NSString *resp = [NSString stringWithUTF8String:rbuf];
    return [resp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *a3_data_to_hex(NSData *data) {
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02X", bytes[i]];
    }
    return hex;
}

-(void)stopNFCDaemon {
    // Kill only the previous nfcd_a3 instance (our daemon), NOT the system nfcd.
    // The system nfcd must remain running — the private CoreNFC HCE classes inside
    // CoreNFC.framework still route through it for NFC hardware access.
    killall(@"nfcd_a3");
    usleep(200000); // 0.2 s
    g_a3NFCDSocketPath = nil;
}

-(BOOL)startNFCDaemonAtPath:(NSString *)path {
    if (path.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"[ObjcHelper] nfcd_a3 not found at: %@", path);
        return NO;
    }

    // Compute socket path in NSTemporaryDirectory — writable by both the
    // parent (after sandbox escape) and the sandboxed child process.
    NSString *socketPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"a3nfcd.socket"];
    [[NSFileManager defaultManager] removeItemAtPath:socketPath error:nil]; // remove stale socket
    g_a3NFCDSocketPath = socketPath;
    NSLog(@"[ObjcHelper] nfcd_a3 socket path: %@", socketPath);

    // Ensure the binary is executable.
    const char *cPath = path.fileSystemRepresentation;
    chmod(cPath, 0755);

    // Pass the socket path to the child via an environment variable.
    NSString *socketEnv = [NSString stringWithFormat:@"A3NFCD_SOCKET=%@", socketPath];
    char * const envp[] = { (char *)socketEnv.UTF8String, NULL };
    char * const argv[] = { (char *)cPath, NULL };

    // ── Attempt 1: spawn with root persona (requires platform-application ent.) ──
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_CLOEXEC_DEFAULT);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t pid = 0;
    int rc = posix_spawn(&pid, cPath, NULL, &attr, argv, envp);
    posix_spawnattr_destroy(&attr);

    if (rc != 0) {
        NSLog(@"[ObjcHelper] persona spawn failed (%d: %s) — retrying without persona", rc, strerror(rc));

        // ── Attempt 2: plain spawn as mobile ──
        posix_spawnattr_t plain_attr;
        posix_spawnattr_init(&plain_attr);
        posix_spawnattr_setflags(&plain_attr, POSIX_SPAWN_CLOEXEC_DEFAULT);
        rc = posix_spawn(&pid, cPath, NULL, &plain_attr, argv, envp);
        posix_spawnattr_destroy(&plain_attr);

        if (rc != 0) {
            NSLog(@"[ObjcHelper] plain spawn also failed: %d (%s)", rc, strerror(rc));
            return NO;
        }
        NSLog(@"[ObjcHelper] nfcd_a3 spawned (plain mobile) pid=%d", (int)pid);
    } else {
        NSLog(@"[ObjcHelper] nfcd_a3 spawned (root persona) pid=%d", (int)pid);
    }

    // Wait for socket to appear (up to 3 s).
    for (int i = 0; i < 30; i++) {
        usleep(100000); // 0.1 s
        if ([[NSFileManager defaultManager] fileExistsAtPath:socketPath]) {
            NSLog(@"[ObjcHelper] nfcd_a3 socket ready after %d00ms", i + 1);
            return YES;
        }
    }
    NSLog(@"[ObjcHelper] nfcd_a3 socket did not appear within 3s (path=%@)", socketPath);
    return NO;
}

-(BOOL)isCustomNFCDaemonRunning {
    __block BOOL found = NO;
    enumerateProcessesUsingBlock(^(pid_t pid, NSString *executablePath, BOOL *stop) {
        if ([executablePath.lastPathComponent isEqualToString:@"nfcd_a3"]) {
            found = YES;
            *stop = YES;
        }
    });
    return found;
}

-(BOOL)nfcdLoadCardUID:(NSData *)uid
                   ats:(NSData * _Nullable)ats
         apduResponses:(NSDictionary<NSString *, NSData *> *)apduResponses {
    if (uid.length == 0) return NO;

    NSString *uidHex = a3_data_to_hex(uid);
    NSString *uidResp = a3_nfcd_send_command([NSString stringWithFormat:@"LOAD_UID %@", uidHex]);
    if (![uidResp hasPrefix:@"OK"]) {
        NSLog(@"[ObjcHelper] LOAD_UID failed: %@", uidResp);
        return NO;
    }

    if (ats.length > 0) {
        NSString *atsHex = a3_data_to_hex(ats);
        NSString *atsResp = a3_nfcd_send_command([NSString stringWithFormat:@"LOAD_ATS %@", atsHex]);
        if (![atsResp hasPrefix:@"OK"]) {
            NSLog(@"[ObjcHelper] LOAD_ATS failed: %@", atsResp);
            // Non-fatal: some cards have no ATS.
        }
    }

    for (NSString *selectHex in apduResponses) {
        NSData *respData = apduResponses[selectHex];
        NSString *respHex = a3_data_to_hex(respData);
        NSString *cmd = [NSString stringWithFormat:@"APDU_RESP %@ %@", selectHex, respHex];
        NSString *resp = a3_nfcd_send_command(cmd);
        if (![resp hasPrefix:@"OK"]) {
            NSLog(@"[ObjcHelper] APDU_RESP failed for %@: %@", selectHex, resp);
        }
    }

    return YES;
}

-(void)nfcdClearCard {
    a3_nfcd_send_command(@"CLEAR_CARD");
}
@end
