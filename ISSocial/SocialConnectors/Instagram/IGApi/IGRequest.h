//
// 



#import <Foundation/Foundation.h>


@class AFHTTPClient;
@class AFHTTPRequestOperation;
@class IGSession;

typedef AFHTTPRequestOperation IGRequestOperation;

typedef void (^IGRequestHandler)(IGRequestOperation *connection,
        id result,
        NSError *error);

@interface IGRequest : NSObject

@property(nonatomic, copy) NSString *method;


+ (IGRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters;

- (IGRequestOperation *)startWithCompletionHandler:(IGRequestHandler)completion;
@end