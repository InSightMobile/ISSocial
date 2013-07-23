//
//  FacebookConnector.h
//  socials
//
//  Created by yar on 18.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "AccessSocialConnector.h"

@class XMPPStream;
@class SUserData;
@class SPhotoAlbumData;


@interface FacebookConnector : AccessSocialConnector

@property(nonatomic, strong) XMPPStream *xmppStream;
@property(nonatomic) NSInteger xmppStreamStatus;

+ (FacebookConnector *)instance;

- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)method params:(NSDictionary *)params operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethodWithURL:(NSString *)urlString operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simplePost:(NSString *)method object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)httpMethod path:(NSString *)path params:(NSDictionary *)params object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleQuery:(NSString *)query operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleRequest:(NSString *)method path:(NSString *)path object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)checkAuthorizationFor:(NSArray *)permissions operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)authorizeWithPublishPermissions:(NSArray *)permissions completion:(SObjectCompletionBlock)completion;


- (SObject *)operationWithObject:(SObject *)object;

@property(retain, nonatomic) SUserData *currentUserData;


@property(nonatomic, strong) NSMutableArray *messageReceivers;
@property(nonatomic, strong) SPhotoAlbumData *wallAlbum;
@end
