//


#import <Foundation/Foundation.h>
#import "ISSVKRequest.h"

@class AFHTTPClient;
@class ISSVKSession;

typedef enum {
    ISSVKSessionStateOpen,
    ISSVKSessionStateClosedLoginFailed,
    ISSVKSessionStateClosed

} ISSVKSessionState;


typedef void (^VKSessionStateHandler)(ISSVKSession *session,
        ISSVKSessionState status,
        NSError *error);

@interface ISSVKSession : NSObject
@property(nonatomic, strong) AFHTTPClient *client;


@property(nonatomic, strong, readonly) NSString *accessToken;
@property(nonatomic, copy, readonly) NSString *userId;

@property(nonatomic, copy) NSString *clientId;

@property(nonatomic) ISSVKSessionState state;

+ (ISSVKSession *)activeSession;

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(VKSessionStateHandler)handler;

- (void)reopenSessionWithCompletionHandler:(VKSessionStateHandler)handler;

+ (VKRequestOperation *)uploadDataTo:(NSString *)uploadURL fromURL:(NSURL *)fileUrl name:(NSString *)name fileName:(NSString *)filename mime:(NSString *)mime handler:(VKRequestHandler)handler;

- (void)closeAndClearTokenInformation;

+ (void)sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData handler:(VKRequestHandler)handler;


@end
