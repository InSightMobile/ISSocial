//
// 

#import "VkontakteConnector+News.h"
#import "VkontakteConnector+Messages.h"
#import "SMessageData.h"
#import "VkontakteConnector+UserData.h"
#import "SUserData.h"
#import "VkontakteConnector+Feed.h"
#import "SMessageThread.h"
#import "NSString+StripHTML.h"
#import "NSArray+BlocksKit.h"
#import "SPhotoData.h"

@implementation VkontakteConnector (Messages)

- (SMessageData *)parseMessageData:(NSDictionary *)info
{
    NSLog(@"info = %@", info);

    NSString *objectId = [info[@"mid"] stringValue];

    SMessageData *messageData = (id) [self mediaObjectForId:objectId type:@"message"];

    messageData.message = [info[@"body"] stripHtml];
    messageData.date = [NSDate dateWithTimeIntervalSince1970:[info[@"date"] doubleValue]];
    messageData.attachments = [self parseAttachments:info[@"attachments"]];

    messageData.isUnread = @([info[@"read_state"] intValue] == 0);

    if (messageData.isUnread.boolValue) {
        NSLog(@"messageData = %@", messageData);
    }


    SUserData *userData = [self dataForUserId:[info[@"uid"] stringValue]];
    messageData.messageCompanion = userData;

    messageData.isOutgoing = @([info[@"out"] boolValue]);

    if (messageData.isOutgoing.boolValue) {
        messageData.messageAuthor = self.currentUserData;
    }
    else {
        messageData.messageAuthor = userData;
    }

    return messageData;
}

- (SObject *)readMessageUpdates:(SObject *)params completion:(CompletionBlock)completion
{
    SObject *operation = [self operationWithObject:params completion:completion];
    [self addPullReceiver:operation.copy forArea:@"messages"];
    return operation;
}

- (SObject *)postMessage:(SMessageData *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self uploadAttachments:params.attachments destination:@"message" operation:operation completion:^(NSArray *attachments) {

            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

            parameters[@"uids"] = params.messageCompanion.objectId;

            if (params.message.length) {
                parameters[@"message"] = params.message;
            }

            if (attachments.count) {
                NSString *attach = [[attachments map:^id(id <SMultimediaObject> obj) {
                    return [NSString stringWithFormat:@"%@%@", obj.mediaType, obj.objectId];
                }] componentsJoinedByString:@","];

                parameters[@"attachment"] = attach;
            }

            [self simpleMethod:@"messages.send" parameters:parameters operation:operation processor:^(id response) {

                NSLog(@"response = %@", response);

                if ([response isKindOfClass:[NSArray class]] && [response count] > 0) {
                    response = response[0];
                }

                [self simpleMethod:@"messages.getById" parameters:@{@"mid" : response} operation:operation processor:^(id response) {

                    for (NSDictionary *info in response) {

                        if ([info isKindOfClass:[NSDictionary class]]) {
                            SMessageData *messageData = [self parseMessageData:info];
                            [operation complete:messageData];
                            return;
                        }
                    }
                    [operation completeWithFailure];
                }];
            }];
        }];
    }];
}

- (SObject *)readMessagesForTread:(SMessageThread *)params completion:(CompletionBlock)completion
{
    return [self readMessageHistory:params.messageCompanion completion:completion];
}

- (SObject *)markMessagesAsRead:(SMessageThread *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *mids = [[[params.subObjects select:^BOOL(SMessageData *obj) {
            return obj.isUnread.boolValue;
        }] valueForKey:@"objectId"] componentsJoinedByString:@","];

        if (!mids.length) {
            [operation complete:[SObject successful]];
            return;
        }

        [self simpleMethod:@"messages.markAsRead" parameters:@{@"mids" : mids} operation:operation processor:^(id response) {
            [operation complete:[SObject successful]];

            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessagesUnreadStatusChanged object:nil];
        }];
    }];
}

- (SObject *)pageMessageHistory:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = [(SUserData *) params objectId];

        [self simpleMethod:@"messages.getHistory" parameters:@{@"uid" : userId, @"offset" : params.pagingData} operation:operation processor:^(id response) {

            SObject *result = [self parseMessages:response paging:params];
            [self updateUserData:[result.subObjects valueForKey:@"messageCompanion"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:[self addPagingData:result to:params]];
            }];

        }];
    }];
}

- (SObject *)readMessageHistory:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = [(SUserData *) params objectId];

        [self simpleMethod:@"messages.getHistory" parameters:@{@"uid" : userId} operation:operation processor:^(id response) {

            SObject *result = [self parseMessages:response paging:nil];
            [(SUserData *) result setObjectId:userId];
            [self updateUserData:[result.subObjects valueForKey:@"messageCompanion"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:result];
            }];

        }];
    }];
}

- (SObject *)parseMessages:(id)response paging:(SObject *)paging
{
    SObject *result = [SObject objectCollectionWithHandler:self];
    NSLog(@"response = %@", response);
    int count = 0;

    for (NSDictionary *info in response) {

        if ([info isKindOfClass:[NSDictionary class]]) {
            SMessageData *messageData = [self parseMessageData:info];
            [result addSubObject:messageData];
        }
        else if ([info isKindOfClass:[NSNumber class]]) {
            count = [(id) info intValue];
        }
    }

    int totalCount = result.subObjects.count;
    if (paging) {
        totalCount += [paging.pagingData intValue];
    }

    if (count > totalCount) {
        result.isPagable = @YES;
    }
    result.pagingSelector = @selector(pageMessageHistory:completion:);
    result.pagingData = @(totalCount);

    return result;
}

- (SObject *)readDialogs:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"messages.getDialogs" parameters:nil operation:operation processor:^(id response) {
            SObject *result = [SObject objectCollectionWithHandler:self];
            SObject *threads = [SObject objectCollectionWithHandler:self];
            for (NSDictionary *info in response) {
                SMessageThread *messageThread = [[SMessageThread alloc] initWithHandler:self];
                if ([info isKindOfClass:[NSDictionary class]]) {
                    SMessageData *messageData = [self parseMessageData:info];
                    [result addSubObject:messageData];
                    messageThread.lastMessage = messageData;
                    messageThread.date = messageData.date;
                    messageThread.messageCompanion = messageData.messageCompanion;
                    [threads addSubObject:messageThread];
                }
            }
            [self updateUserData:[result.subObjects valueForKey:@"messageCompanion"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:threads];
            }];
        }];
    }];
}

- (SObject *)readMessages:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"messages.get" parameters:nil operation:operation processor:^(id response) {

            SObject *result = [SObject objectCollectionWithHandler:self];
            NSLog(@"response = %@", response);

            for (NSDictionary *info in response) {

                if ([info isKindOfClass:[NSDictionary class]]) {
                    SMessageData *messageData = [self parseMessageData:info];
                    [result addSubObject:messageData];
                }
            }

            [self updateUserData:[result.subObjects valueForKey:kNewMessagesNotification] operation:operation completion:^(SObject *updateResult) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)readUnreadMessages:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"messages.get" parameters:@{@"filters" : @"1"} operation:operation processor:^(id response) {

            SObject *result = [SObject objectCollectionWithHandler:self];
            NSLog(@"response = %@", response);

            int totalCount = 0;

            for (id info in response) {

                if ([info isKindOfClass:[NSDictionary class]]) {
                    SMessageData *messageData = [self parseMessageData:info];
                    [result addSubObject:messageData];
                }
                else if ([info isKindOfClass:[NSNumber class]]) {
                    totalCount = [info intValue];
                }
            }
            result.totalCount = @(totalCount);
            [operation complete:result];
        }];
    }];
}

@end