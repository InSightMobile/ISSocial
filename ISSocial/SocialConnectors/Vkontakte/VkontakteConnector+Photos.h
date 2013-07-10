//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@class SPhotoData;

@interface VkontakteConnector (Photos)
- (SObject *)parsePhotos:(NSArray *)response;

- (SPhotoData *)parsePhotoResponse:(NSDictionary *)response;

- (void)uploadPhoto:(SPhotoData *)params album:(NSString *)album operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completionn;

- (void)uploadMessagePhoto:(SPhotoData *)params operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completionn;

- (void)uploadPhoto:(SPhotoData *)params uploadServer:(NSString *)uploadServer saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completionn;

- (void)uploadPhoto:(SPhotoData *)params toURL:(NSString *)URL saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completionn:(CompletionBlock)completionn;
@end