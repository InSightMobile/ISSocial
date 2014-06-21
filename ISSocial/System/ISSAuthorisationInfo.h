//
// 



#import <Foundation/Foundation.h>

@class SocialConnector;


@interface ISSAuthorisationInfo : NSObject <NSCoding>
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *accessTokenSecret;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *provider;
@property(nonatomic, strong) SocialConnector *handler;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;
@end