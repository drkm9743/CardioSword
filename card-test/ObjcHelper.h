

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/sysctl.h>

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Private)
- (BOOL)writeToCPBitmapFile:(NSString *)filename flags:(NSInteger)flags;
@end

@interface ObjcHelper : NSObject
-(NSNumber *)getDeviceSubType;
-(void)updateDeviceSubType:(NSInteger)deviceSubType;
-(void)imageToCPBitmap:(UIImage *)img path:(NSString *)path;
-(void)respring;
-(void)refreshWalletServices;
-(UIImage *)getImageFromData:(NSString *)path;
-(void)saveImage:(UIImage *)image atPath:(NSString *)path;
-(NSArray<NSString *> *)kfsListDirectory:(NSString *)path;
-(int64_t)kfsFileSizeNC:(NSString *)path;
-(NSData * _Nullable)kfsReadFile:(NSString *)path maxSize:(int64_t)maxSize;
-(NSArray<NSString *> *)directListDirectory:(NSString *)path;
-(NSData * _Nullable)directReadFile:(NSString *)path maxSize:(int64_t)maxSize;
-(NSDictionary<NSString *, NSNumber *> *)runtimeEntitlementFlags;
-(BOOL)isLikelyLiveContainerGuest;

// MARK: - NFC daemon management
/// Kill the system nfcd process.
-(void)stopNFCDaemon;
/// Launch the custom nfcd binary at `path`. Returns YES if spawned successfully.
-(BOOL)startNFCDaemonAtPath:(NSString *)path;
/// Returns YES if a process named "nfcd_a3" is currently running.
-(BOOL)isCustomNFCDaemonRunning;
/// Load a card into the running nfcd via Unix socket.
/// apduResponses keys = SELECT APDU hex strings, values = response Data.
/// Returns YES if all commands were sent successfully.
-(BOOL)nfcdLoadCardUID:(NSData *)uid
                   ats:(NSData * _Nullable)ats
         apduResponses:(NSDictionary<NSString *, NSData *> *)apduResponses;
/// Clear the active card from the running nfcd.
-(void)nfcdClearCard;
@end

NS_ASSUME_NONNULL_END
