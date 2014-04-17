//
// 



#import <Foundation/Foundation.h>

@class SocialConnector;


@interface ISSAuthorisationInfo : NSObject
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *provider;
@property(nonatomic, strong) SocialConnector *handler;
@end