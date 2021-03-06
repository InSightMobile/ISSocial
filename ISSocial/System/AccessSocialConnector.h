//
// Created by yarry on 26.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SocialConnector.h"

static NSString *const kAllowUserUIKey = @"allowUserUI";

@class AccessSocialConnector;

@protocol AccessSocialConnector <SocialConnector>
@optional
+ (id)instance;

+ (NSString *)connectorCode;
@end

@interface AccessSocialConnector : SocialConnector <AccessSocialConnector>
- (id <SMediaObject>)mediaObjectForId:(NSString *)objectId type:(NSString *)mediaType;

- (SObject *)addPagingData:(SObject *)result to:(SObject *)data;

@property(nonatomic) NSString *defaultAlbumName;

- (void)setupSettings:(NSDictionary *)settings;


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation;

+ (id)instance;

- (void)handleDidBecomeActive;


@end