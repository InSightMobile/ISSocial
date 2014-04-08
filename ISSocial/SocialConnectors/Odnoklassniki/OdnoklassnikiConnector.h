//
//  OdnoklassnikiConnector.h
//  socials
//
//  Created by yar on 20.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "AccessSocialConnector.h"
#import "OKSession.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class Odnoklassniki;
@class SUserData;
@class AFHTTPClient;
@class SPhotoAlbumData;

@interface OdnoklassnikiConnector : AccessSocialConnector

+ (OdnoklassnikiConnector *)instance;

@property(nonatomic, strong) SUserData *currentUserData;

@property(nonatomic, strong) AFHTTPRequestOperationManager *client;

@property(nonatomic, strong) SPhotoAlbumData *defaultAlbum;
@property(nonatomic, copy) NSString *defaultAlbumId;

- (void)simpleMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

@end
