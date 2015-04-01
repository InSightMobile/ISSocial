//
// Created by yarry on 26.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SocialConnector.h"
#import "AccessSocialConnector.h"
#import "ISSocial/ISSocial.h"


@implementation AccessSocialConnector {

    NSMutableDictionary *_media;
    NSCache *_cache;
    NSInteger _priority;
}


- (id)init {
    self = [super init];
    if (self) {
        _media = [NSMutableDictionary dictionary];
        _cache = [NSCache new];
        _cache.countLimit = 1000;
    }
    return self;
}

- (id <SMediaObject>)mediaObjectForId:(NSString *)objectId type:(NSString *)mediaType {
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

- (SObject *)addPagingData:(SObject *)result to:(SObject *)data {
    SObject *currentData = [data copyWithHandler:self];
    [currentData.subObjects addObjectsFromArray:result.subObjects];
    currentData.pagingData = result.pagingData;
    currentData.isPagable = result.isPagable;
    return currentData;
}

- (NSString *)defaultAlbumName {
    return _defaultAlbumName ?: @"Album";
}

- (NSInteger)connectorPriority {
    return _priority;
}

- (void)setConnectorPriority:(NSInteger)priority {
    _priority = priority;
}


- (void)setupSettings:(NSDictionary *)settings {
    if (settings[@"Priority"]) {
        [self setConnectorPriority:[settings[@"Priority"] integerValue]];
    }
    if (settings[@"DefaultAlbum"]) {
        [self setDefaultAlbumName:settings[@"DefaultAlbum"]];
    }
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return NO;
}

+ (id)instance {

    AccessSocialConnector *connector = [[ISSocial defaultInstance] connectorNamed:[self connectorCode]];
    return connector;
}

- (NSString *)connectorCode {
    Class x = self.class;
    if ([x respondsToSelector:@selector(connectorCode)]) {
        return [x connectorCode];
    }
    return nil;
}

- (void)handleDidBecomeActive {

}


- (SObject *)closeSessionAndClearCredentials:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self closeSession:params completion:completion];
}

@end