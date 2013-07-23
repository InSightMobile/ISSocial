//
//  SocialConnector.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SMediaObject.h"
#import "SocialConnectorOperation.h"

@class SFeedEntry;
@class SMessageEntry;
@class SUserData;
@class SVideoData;
@class SPhotoData;
@class SocialConnector;
@class SPhotoAlbumData;
@class SCommentData;
@class SMessageData;
@class SNewsEntry;
@class SMessageThread;
@class SAudioData;


FOUNDATION_EXPORT NSString *const kNewMessagesNotification;
FOUNDATION_EXPORT NSString *const kNewMessagesUnreadStatusChanged;

@protocol SocialConnector <NSObject>

@optional

// messages
- (SObject *)readDialogs:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)readMessagesForTread:(SMessageThread *)params completion:(CompletionBlock)completion;

- (SObject *)markMessagesAsRead:(SMessageThread *)params completion:(CompletionBlock)completion;

- (SObject *)readMessageHistory:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)readMessages:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)readUnreadMessages:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadDialogs:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadMessagesForTread:(SMessageThread *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadMessageHistory:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadMessages:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)postMessage:(SMessageData *)params completion:(CompletionBlock)completion;

- (SObject *)readMessageUpdates:(SObject *)params completion:(CompletionBlock)completion;

// audio
- (SObject *)readAudio:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)searchAudio:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadAudio:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)addAudio:(SAudioData *)params completion:(CompletionBlock)completion;

// video
- (SObject *)addVideo:(SVideoData *)params completion:(CompletionBlock)completion;

- (SObject *)readVideo:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadVideo:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)readVideoComments:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadVideoComments:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)addVideoComment:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)addVideoLike:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)removeVideoLike:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)readVideoLikes:(SVideoData *)params completion:(CompletionBlock)completion;

// News
- (SObject *)readNews:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)searchNews:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadNews:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)readNewsComments:(SNewsEntry *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadNewsComments:(SFeedEntry *)feed completion:(CompletionBlock)completion;

- (SObject *)addNewsComment:(SCommentData *)feed completion:(CompletionBlock)completion;

- (SObject *)addNewsLike:(SNewsEntry *)feed completion:(CompletionBlock)completion;

- (SObject *)removeNewsLike:(SNewsEntry *)feed completion:(CompletionBlock)completion;

// Users & friends
- (SObject *)readUserData:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)readUserFriends:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)readUserFriendsOnline:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)readUserFriendRequests:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadUserData:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadUserFriends:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadUserFriendRequests:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)acceptUserFriendRequest:(SUserData *)params completion:(CompletionBlock)completion;

- (SObject *)rejectUserFriendRequest:(SUserData *)params completion:(CompletionBlock)completion;


//Feed
- (SObject *)readFeed:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadFeed:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)postToFeed:(SFeedEntry *)params completion:(CompletionBlock)completion;

- (SObject *)removeFeedEntry:(SFeedEntry *)params completion:(CompletionBlock)completion;


- (SObject *)readFeedComments:(SFeedEntry *)feed completion:(CompletionBlock)completion;

- (SObject *)cachedReadFeedComments:(SFeedEntry *)feed completion:(CompletionBlock)completion;

- (SObject *)addFeedComment:(SCommentData *)feed completion:(CompletionBlock)completion;

- (SObject *)addFeedLike:(SFeedEntry *)feed completion:(CompletionBlock)completion;

- (SObject *)removeFeedLike:(SFeedEntry *)feed completion:(CompletionBlock)completion;

// Photos
- (SObject *)readPhotos:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadPhotos:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)addPhoto:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)publishPhoto:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)addPhotoToAlbum:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)readPhotoAlbums:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadPhotoAlbums:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadPhotosFromAlbum:(SPhotoAlbumData *)params completion:(CompletionBlock)completion;

- (SObject *)readPhotoComments:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)cachedReadPhotoComments:(SPhotoData *)params completion:(CompletionBlock)completion;

- (SObject *)addPhotoComment:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)addPhotoLike:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)removePhotoLike:(SCommentData *)params completion:(CompletionBlock)completion;

- (SObject *)readPhotoLikes:(SPhotoData *)params completion:(CompletionBlock)completion;

// Session
- (SObject *)openSession:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)closeSession:(SObject *)params completion:(CompletionBlock)completion;

@end

#define PROCESS_CONNECTOR_PROTOCOL \
    {id r = [super implementSocialConnectorCallProtocol:params completion:completion];if(r)return r;}


@interface SocialConnector : NSObject <SocialConnector>

@property(nonatomic) NSSet *supportedSpecifications;

- (SObject *)readCached:(SEL)selector params:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)implementSocialConnectorCallProtocol:(SObject *)params completion:(CompletionBlock)completion;

- (SObject *)operationWithObject:(SObject *)params completion:(CompletionBlock)completion processor:(void (^)(SocialConnectorOperation *))processor;

- (SObject *)processSocialConnectorProtocol:(SObject *)params completion:(CompletionBlock)completion operation:(SEL)selector;

- (NSString *)connectorCode;

- (UIImage *)connectorImage;

- (NSString *)connectorName;

- (NSInteger)connectorPriority;

- (NSInteger)connectorDisplayPriority;

- (SocialConnectorOperation *)operationWithParent:(SocialConnectorOperation *)operation;

- (SObject *)operationWithObject:(SObject *)object;

- (SObject *)operationWithObject:(SObject *)params completion:(CompletionBlock)completion;

@property(strong, nonatomic) SObject *connectorState;

- (SUserData *)currentUserData;

@property(readonly, nonatomic) BOOL isLoggedIn;

@property(nonatomic) BOOL handleCache;

- (BOOL)isSupported:(SEL)pSelector;

@property(nonatomic) int pageSize;


- (BOOL)meetsSpecification:(NSString *)string;

@end
