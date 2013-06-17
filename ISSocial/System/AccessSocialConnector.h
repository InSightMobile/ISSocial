//
// Created by yarry on 26.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SocialConnector.h"


@interface AccessSocialConnector : SocialConnector
- (id <SMediaObject>)mediaObjectForId:(NSString *)objectId type:(NSString *)mediaType;

- (SObject *)addPagingData:(SObject *)result to:(SObject *)data;

- (NSString *)defaultAlbumName;
@end