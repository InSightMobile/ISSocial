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
@class SLinkData;


FOUNDATION_EXPORT NSString *const kNewMessagesNotification;
FOUNDATION_EXPORT NSString *const kNewMessagesUnreadStatusChanged;

@protocol SocialConnector <NSObject>

@optional

// messages
- (SObject *)readDialogs:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readMessagesForTread:(SMessageThread *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)markMessagesAsRead:(SMessageThread *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readMessageHistory:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readMessages:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readUnreadMessages:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadDialogs:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadMessagesForTread:(SMessageThread *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadMessageHistory:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadMessages:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)postMessage:(SMessageData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readMessageUpdates:(SObject *)params completion:(SObjectCompletionBlock)completion;

// audio
- (SObject *)readAudio:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)searchAudio:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadAudio:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addAudio:(SAudioData *)params completion:(SObjectCompletionBlock)completion;

// video
- (SObject *)addVideo:(SVideoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readVideo:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadVideo:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readVideoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadVideoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addVideoComment:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addVideoLike:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)removeVideoLike:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readVideoLikes:(SVideoData *)params completion:(SObjectCompletionBlock)completion;

// News
- (SObject *)readNews:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)searchNews:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadNews:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readNewsComments:(SNewsEntry *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadNewsComments:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)addNewsComment:(SCommentData *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)addNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)removeNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion;

// Users & friends
- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readUserFriendsOnline:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readUserFriendRequests:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadUserFriendRequests:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)acceptUserFriendRequest:(SUserData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)rejectUserFriendRequest:(SUserData *)params completion:(SObjectCompletionBlock)completion;


//Feed
- (SObject *)readFeed:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadFeed:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)postToFeed:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)removeFeedEntry:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion;


- (SObject *)readFeedComments:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadFeedComments:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)addFeedComment:(SCommentData *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)addFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion;

- (SObject *)removeFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion;

// Photos
- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addPhoto:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)publishPhoto:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)publish:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addPhotoToAlbum:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readPhotoAlbums:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadPhotoAlbums:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readPhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)cachedReadPhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addPhotoComment:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addPhotoLike:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)removePhotoLike:(SCommentData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)readPhotoLikes:(SPhotoData *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)addLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion;

- (SObject *)removeLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion;

- (SObject *)readLinkLikes:(SLinkData *)link completion:(SObjectCompletionBlock)completion;

// Session
- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion;

@end

#define PROCESS_CONNECTOR_PROTOCOL \
    {id r = [super implementSocialConnectorCallProtocol:params completion:completion];if(r)return r;}


@interface SocialConnector : NSObject <SocialConnector>

@property(nonatomic) NSSet *supportedSpecifications;

- (SObject *)readCached:(SEL)selector params:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)implementSocialConnectorCallProtocol:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (SObject *)operationWithObject:(SObject *)params completion:(SObjectCompletionBlock)completion processor:(void (^)(SocialConnectorOperation *))processor;

- (SObject *)processSocialConnectorProtocol:(SObject *)params completion:(SObjectCompletionBlock)completion operation:(SEL)selector;

- (NSString *)connectorCode;

- (UIImage *)connectorImage;

- (NSString *)connectorName;

- (NSInteger)connectorPriority;

- (NSInteger)connectorDisplayPriority;

- (SocialConnectorOperation *)operationWithParent:(SocialConnectorOperation *)operation;

- (SObject *)operationWithObject:(SObject *)object;

- (SObject *)operationWithObject:(SObject *)params completion:(SObjectCompletionBlock)completion;

@property(strong, nonatomic) SObject *connectorState;

- (SUserData *)currentUserData;

@property(readonly, nonatomic) BOOL isLoggedIn;

@property(nonatomic) BOOL handleCache;

- (BOOL)isSupported:(SEL)pSelector;

@property(nonatomic) int pageSize;


- (BOOL)meetsSpecification:(NSString *)string;

@end
