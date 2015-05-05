//
//  VkontakteConnector+News.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "AccessSocialConnector.h"
#import "VKSdk.h"

@class AFHTTPClient;
@class SCommentData;


@interface VkontakteConnector : AccessSocialConnector <VKSdkDelegate>

+ (VkontakteConnector *)instance;

- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)executeRequest:(VKRequest *)request operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor retries:(NSInteger)retries;

- (NSError *)processVKError:(NSError *)error;


@property(nonatomic, copy) NSString *userId;

@property(nonatomic, strong) SObject *pullOperation;

@property(nonatomic, strong) id permissions;

@property(nonatomic, strong) NSMutableDictionary *countryCodesById;



@end
