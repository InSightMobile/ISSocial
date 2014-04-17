//
// 

#import "NSDate+Odnoklassniki.h"
#import "OdnoklassnikiConnector+Users.h"
#import "SMessageThread.h"
#import "OdnoklassnikiConnector+Messages.h"
#import "SUserData.h"
#import "NSObject+PerformBlockInBackground.h"

@implementation OdnoklassnikiConnector (Messages)

- (SObject *)markMessagesAsRead:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        SMessageData *message = nil;
        for (SMessageData *messageData in params.subObjects) {
            if (messageData.isUnread.boolValue) {
                message = messageData;
            }
        }
        if (!message) {
            [operation complete:[SObject successful]];
            return;
        }

        [self simpleMethod:@"messages.markAsRead" parameters:@{@"msg_id" : message.objectId} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            [operation complete:[SObject successful]];
        }];
    }];
}

- (SObject *)readDialogs:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"messages.getConversations" parameters:@{@"return_last_msg" : @"true"} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *conversations = [SObject objectCollectionWithHandler:self];
            SObject *messages = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *conv in response) {

                SMessageThread *thread = [SMessageThread objectWithHandler:self];

                SMessageData *lastMessage = [SMessageData objectWithHandler:self];

                thread.lastMessage = lastMessage;

                lastMessage.message = conv[@"last_msg_text"];
                lastMessage.messageCompanion = [self dataForUserId:conv[@"friend_uid"]];
                lastMessage.date = [NSDate dateWithOdnoklassnikiString:conv[@"last_msg_time"]];

                thread.date = lastMessage.date;
                thread.objectId = conv[@"friend_uid"];

                [conversations addSubObject:thread];
                [messages addSubObject:lastMessage];
            }

            [self updateUserData:[messages.subObjects valueForKey:@"messageCompanion"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:conversations];
            }];
        }];
    }];
}

- (SObject *)postMessage:(SMessageData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"messages.send" parameters:@{@"friend_uid" : params.messageCompanion.objectId, @"text" : params.message} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SMessageData *messageData = [params copyWithHandler:self];
            messageData.date = [NSDate date];

            [operation complete:messageData];
        }];
    }];
}


- (SObject *)readMessageHistory:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self readMessagesForTread:(SMessageThread *) params completion:completion];
}

- (SObject *)readMessageUpdates:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        SObject *updateParams = [params copyWithHandler:self];
        updateParams.operation = operation;

        [self iss_performBlock:^(id sender) {

            if ([[(id) updateParams mediaType] isEqualToString:@"user"]) {
                [self readMessageHistory:updateParams completion:^(SObject *object) {

                    [operation complete:object];
                }];
            }
            else {
                [self readMessagesForTread:updateParams completion:^(SObject *object) {

                    [operation complete:object];
                }];
            }

        }           afterDelay:kMessagesUpdateRate];
    }];
}

- (SObject *)readMessagesForTread:(SMessageThread *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *parameters = @{@"friend_uid" : params.objectId, @"first" : [@0 stringValue]};

        [self simpleMethod:@"messages.getList" parameters:parameters operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            if (![response isKindOfClass:[NSArray class]]) {
                [operation completeWithFailure];
                return;
            }

            SObject *messages = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *data in response) {
                SMessageData *message = [SMessageData objectWithHandler:self];

                message.objectId = data[@"msg_id"];
                message.date = [NSDate dateWithOdnoklassnikiString:data[@"time"]];
                message.message = data[@"text"];
                message.messageCompanion = [self dataForUserId:data[@"friend_uid"]];
                message.isOutgoing = @([data[@"direction"] isEqualToString:@"outgoing"]);

                if (message.isOutgoing.boolValue) {
                    message.messageAuthor = self.currentUserData;
                }
                else {
                    message.messageAuthor = message.messageCompanion;
                }
                [messages addSubObject:message];
            }

            [self updateUserData:[messages.subObjects valueForKey:@"messageCompanion"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:messages];
            }];
        }];
    }];
}

@end