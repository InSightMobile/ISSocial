//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@class SPhotoData;

static NSString *const kWallAlbum = @"@wall";

static NSString *const kMessageAlbum = @"@message";

@interface VkontakteConnector (Photos)
- (SObject *)parsePhotos:(NSArray *)response;

- (SPhotoData *)parsePhotoResponse:(NSDictionary *)response;

- (void)uploadPhoto:(SPhotoData *)params album:(NSString *)album operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn;

- (void)uploadMessagePhoto:(SPhotoData *)params operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn;

- (void)uploadPhoto:(SPhotoData *)params uploadServer:(NSString *)uploadServer saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn;

- (void)uploadPhoto:(SPhotoData *)params toURL:(NSString *)URL saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn;

- (void)savePhoto:(SPhotoData *)params saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation uploadResult:(id)uploadResult completion:(SObjectCompletionBlock)completionn;
@end