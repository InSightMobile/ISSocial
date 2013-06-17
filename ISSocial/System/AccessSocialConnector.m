//
// Created by yarry on 26.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SocialConnector.h"
#import "AccessSocialConnector.h"


@implementation AccessSocialConnector
{

    NSMutableDictionary *_media;
    NSCache *_cache;
}

- (id)init
{
    self = [super init];
    if (self) {
        _media = [NSMutableDictionary dictionary];
        _cache = [NSCache new];
        _cache.countLimit = 1000;
    }
    return self;
}

- (id <SMediaObject>)mediaObjectForId:(NSString *)objectId type:(NSString *)mediaType
{
    if (!mediaType.length) {
        mediaType = @"object";
    }

    id <SMediaObject> ref;
    if (!objectId.length) {
        ref = (id) [SObject objectWithHandler:self];
        ref.mediaType = mediaType;
        return ref;
    }

    NSString *key = [mediaType stringByAppendingString:objectId];

    ref = [_cache objectForKey:key];
    if (ref) {
        return ref;
    }

    NSMutableDictionary *dict = _media[mediaType];
    if (!dict) {
        dict = (__bridge_transfer NSMutableDictionary *) CFDictionaryCreateMutable(nil, 0,
                &kCFTypeDictionaryKeyCallBacks, nil);
        _media[mediaType] = dict;
    }
    ref = dict[objectId];
    if (!ref) {
        ref = (id <SMediaObject>) [SObject objectWithHandler:self];
        ref.referencingDictionary = dict;
        ref.mediaType = mediaType;
        ref.objectId = objectId;
        dict[objectId] = ref;
    }
    [_cache setObject:ref forKey:key];
    return ref;
}

- (SObject *)addPagingData:(SObject *)result to:(SObject *)data
{
    SObject *currentData = [data copyWithHandler:self];
    [currentData.subObjects addObjectsFromArray:result.subObjects];
    currentData.pagingData = result.pagingData;
    currentData.isPagable = result.isPagable;
    return currentData;
}

- (NSString *)defaultAlbumName {
    return @"SocNetsBox";
}

@end