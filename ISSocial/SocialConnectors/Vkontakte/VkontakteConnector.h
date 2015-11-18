//
//  VkontakteConnector+News.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "AccessSocialConnector.h"


@class AFHTTPClient,VKRequest;

@interface VkontakteConnector : AccessSocialConnector 

+ (VkontakteConnector *)instance;

- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)executeRequest:(VKRequest *)request operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor retries:(NSInteger)retries;

- (NSError *)processVKError:(NSError *)error;

@property(nonatomic, copy) NSString *userId;

@property(nonatomic, strong) SObject *pullOperation;

@property(nonatomic, strong) id permissions;

@property(nonatomic, strong) NSMutableDictionary *countryCodesById;

- (SObject *)operationWithObject:(SObject *)object;

- (void)startPull;

- (void)addPullReceiver:(SObject *)reseiverOperation forArea:(NSString *)area;

- (SObject *)parseUserData:(NSDictionary *)userInfo;

- (SCommentData *)parseCommentEntry:(NSDictionary *)entryData;

- (SVideoData *)parseVideoResponse:(NSDictionary *)info;

- (void)readLikes:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;

- (void)addLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;

- (void)removeLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;


@end
