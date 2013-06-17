//
// 



#import "VKRequest.h"
#import "SUserData.h"
#import "VkontakteConnector+UserData.h"
#import "SMessageData.h"
#import "VkontakteConnector+Pull.h"
#import "NSString+StripHTML.h"

typedef enum _VKUpdatesCodes
{
    VKMessageAddedUpdateCode = 4,


} VKUpdatesCodes;

static const BOOL const kVKMessageFlagOutbox = 2;

@implementation VkontakteConnector (Pull)
- (void)processPullUpdates:(NSArray *)updatesData
{
    SObject *messageUpdates = nil;
    SObject *userUpdates = nil;

    for (NSArray *item in updatesData) {

        int code = [item[0] intValue];
        int flags = 0;
        NSString *messageId = nil;
        NSString *userId = nil;
        NSString *text = nil;
        NSString *subject = nil;
        NSDictionary *attachments = nil;
        NSDate *date = nil;

        SMessageData *messageData = nil;

        switch (code) {
            case VKMessageAddedUpdateCode: {
                //4,$message_id,$flags,$from_id,$timestamp,$subject,$text,$attachments -- добавление нового сообщения
                flags = [item[2] intValue];
                userId = [item[3] stringValue];
                subject = item[5];
                attachments = item[7];

                messageData = [[SMessageData alloc] initWithHandler:self];

                messageData.objectId = [item[1] stringValue];;
                messageData.message = [item[6] stripHtml];
                messageData.date = [NSDate dateWithTimeIntervalSince1970:[item[4] doubleValue]];
                messageData.messageCompanion = [self dataForUserId:userId];

                if (flags & kVKMessageFlagOutbox) {
                    messageData.isOutgoing = @YES;
                    messageData.messageAuthor = [self currentUserData];
                }
                else {
                    messageData.isUnread = @YES;
                    messageData.messageAuthor = [self dataForUserId:userId];
                }
                // parse attachments
            }
                break;
        }

        if (messageData) {
            if (!messageUpdates) {
                messageUpdates = [SObject objectCollectionWithHandler:self];
            }
            [messageUpdates addSubObject:messageData];
        }
    }

    if (messageUpdates) {
        NSMutableArray *receivers = [self.pullOperation[@"messages"] copy];
        self.pullOperation[@"messages"] = nil;

        for (SObject *receiver in receivers) {
            [receiver.operation update:messageUpdates];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessagesNotification object:messageUpdates];
    }
}

- (void)updatePull
{
    SObject *pullOperation = self.pullOperation;

    NSMutableDictionary *params = pullOperation[@"pullParams"];

    NSString *url = [NSString stringWithFormat:@"http://%@?act=a_check&key=%@&ts=%@&wait=25&mode=2",
                                               params[@"server"], params[@"key"], params[@"ts"]];

    VKRequest *req = [VKRequest requestWithURL:url parameters:nil];

    [req startWithCompletionHandler:^(VKRequestOperation *connection, id response, NSError *error) {

        if (error) {
            NSLog(@"error = %@", error);
            [self startPull];
        }
        else {
            NSLog(@"response = %@", response);

            if (response[@"failed"]) {
                [self startPull];
            }
            else {
                params[@"ts"] = response[@"ts"];
                NSArray *updates = response[@"updates"];
                if (updates.count) {
                    [self processPullUpdates:updates];
                }
                [self updatePull];
            }
        }

    }];
}

- (void)startPull
{
    SObject *pullOperation = self.pullOperation;

    if (!pullOperation) {
        pullOperation = [self operationWithObject:nil];
        self.pullOperation = pullOperation;
    }
    else {
        return;
    }

    VKRequest *req = [VKRequest requestMethod:@"messages.getLongPollServer" parameters:nil];
    [req startWithCompletionHandler:^(VKRequestOperation *connection, id response, NSError *error) {
        if (error) {

        }
        else {
            NSLog(@"response = %@", response);
            pullOperation[@"pullParams"] = [response mutableCopy];
            [self updatePull];
        }
    }];
}

- (void)addPullReceiver:(SObject *)reseiverOperation forArea:(NSString *)area
{
    [self startPull];

    NSMutableArray *receivers = self.pullOperation[area];
    if (!receivers) {
        receivers = [NSMutableArray arrayWithCapacity:1];
        self.pullOperation[area] = receivers;
    }
    [receivers addObject:reseiverOperation];
}
@end