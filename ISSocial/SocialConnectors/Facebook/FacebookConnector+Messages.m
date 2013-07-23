//
// 

#import <BlocksKit/NSObject+BlocksKit.h>
#import "FacebookConnector+Messages.h"
#import "XMPPXFacebookPlatformAuthentication.h"
#import "FBSession.h"
#import "DDLog.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"
#import "SMessageData.h"
#import "XMPPJID.h"
#import "SUserData.h"
#import "FacebookConnector+UserData.h"
#import "SMessageThread.h"
#import "FBAccessTokenData.h"
#import "XMPPPresence.h"
//#import "XMPPRoster.h"
//#import "XMPPRosterMemoryStorage.h"
#import "NSDate+Facebook.h"
//#import "XMPPReconnect.h"
#import "XMPPStream.h"


static const NSTimeInterval kTimeout  = 30;

@implementation FacebookConnector (Messages)

- (void)xmppConnect
{
    NSError* error = nil;
    if (!self.xmppStream) {

        self.xmppStream = [[XMPPStream alloc] initWithFacebookAppId:[[FBSession activeSession] appID]];
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];

        [self.xmppStream connectWithTimeout:kTimeout error:&error];

        //XMPPRosterMemoryStorage *storage = [[XMPPRosterMemoryStorage alloc] init];
        //XMPPRoster *roster = [[XMPPRoster alloc] initWithRosterStorage:storage];
        //[roster activate:self.xmppStream];

        //XMPPReconnect *reconnect = [[XMPPReconnect alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        //[reconnect activate:self.xmppStream];
    }
    else {
        [self.xmppStream connectWithTimeout:kTimeout error:&error];
    }
}

- (void)xmppReconnect
{
    [self.xmppStream disconnect];
    self.xmppStream = nil;

    [self performBlock:^(id sender) {
        [self xmppConnect];
    }       afterDelay:4];
}

- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    if (![xmppStream isSecure]) {
        //self.viewController.statusLabel.text = @"XMPP STARTTLS...";
        NSError *error = nil;
        BOOL result = [xmppStream secureConnection:&error];

        if (result == NO) {
            DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
            //self.viewController.statusLabel.text = @"XMPP STARTTLS failed";
        }

    }
    else {
        //self.viewController.statusLabel.text = @"XMPP X-FACEBOOK-PLATFORM SASL...";
        NSError *error = nil;
        BOOL result =
                [xmppStream authenticateWithFacebookAccessToken:[FBSession activeSession].accessTokenData.accessToken error:&error];

        if (result == NO) {
            DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
            //self.viewController.statusLabel.text = @"XMPP authentication failed";
        }
    }
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    //self.viewController.statusLabel.text = @"XMPP STARTTLS...";
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)xmppStream
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    //self.viewController.statusLabel.text = @"XMPP authenticated";
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@ - error: %@", THIS_FILE, THIS_METHOD, error);
    //self.viewController.statusLabel.text = @"XMPP authentication failed";
    [self xmppReconnect];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"xmppStreamDidDisconnect %@", error);
    //self.viewController.statusLabel.text = @"XMPP disconnected";
    [self xmppReconnect];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"xmppStreamdidNotRegister %@", error);
    //self.viewController.statusLabel.text = @"XMPP disconnected";
    [self xmppReconnect];
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{

}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"message = %@", presence);
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{

    NSLog(@"message = %@", message);

    if ([message isChatMessageWithBody]) {
        NSXMLElement*body = [message elementForName:@"body"];
        NSString *messageBody = body.stringValue;
        NSString *fromId = message.from.user;

        fromId = [fromId substringFromIndex:1];

        SUserData *from = [self dataForUserId:fromId];

        SMessageData *messageData = [[SMessageData alloc] initWithHandler:self];
        messageData.message = messageBody;
        messageData.messageCompanion = from;
        messageData.date = [NSDate date];
        messageData.messageAuthor = from;

        SObject *reseivedMessages = [SObject objectCollectionWithHandler:self];
        [reseivedMessages addSubObject:messageData];


        NSArray *operations = [self.messageReceivers copy];
        [self.messageReceivers removeAllObjects];
        for (SObject *reseiver in operations) {
            [reseiver.operation update:reseivedMessages];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessagesNotification object:reseivedMessages];
    }
}

- (SMessageData *)parseMessageData:(NSDictionary *)messageData
{
    NSString *objectId = messageData[@"id"];
    if (messageData[@"message_id"]) {
        objectId = messageData[@"message_id"];
    }
    SMessageData *message = (id) [self mediaObjectForId:objectId type:@"message"];

    message.message = messageData[@"message"];
    if (messageData[@"body"]) {
        message.message = messageData[@"body"];
    }

    SUserData *user = nil;
    if ([messageData[@"from"] isKindOfClass:[NSDictionary class]]) {
        user = [self dataForUserId:messageData[@"from"][@"id"] name:messageData[@"from"][@"name"]];
    }

    if (messageData[@"author_id"]) {
        user = [self dataForUserId:[messageData[@"author_id"] stringValue]];
    }

    message.date = [NSDate dateWithFacebookString:messageData[@"created_time"]];
    message.messageAuthor = user;
    message.messageCompanion = user;

    if ([user.objectId isEqualToString:self.currentUserData.objectId]) {
        message.isOutgoing = @YES;
    }

    if (messageData[@"attachment"]) {


    }

    return message;
}

- (SObject *)readMessagesForTread:(SMessageThread *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:[NSString stringWithFormat:@"%@", params.objectId] operation:operation processor:^(id response) {
            [operation complete:[self parseMessages:response[@"comments"]]];
        }];

        /*

        NSString *fql = [NSString stringWithFormat:@"SELECT attachment,body,author_id,created_time,message_id "
                                                           "FROM message WHERE thread_id = %@", params.objectId];

        [self simpleQuery:fql operation:operation processor:^(id response) {

            [operation complete:[self parseMessages:response]];
        }];
        */

    }];
}

- (SObject *)parseMessages:(SObject *)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];
    NSLog(@"response = %@", response);

    for (NSDictionary *info in response[@"data"]) {
        if ([info isKindOfClass:[NSDictionary class]]) {
            SMessageData *messageData = [self parseMessageData:info];
            [result addSubObject:messageData];
        }
    }

    if (response[@"paging"] && response[@"paging"][@"next"]) {
        result.pagingData = response[@"paging"][@"next"];
        result.pagingSelector = @selector(readMessagesPage:completion:);
        result.isPagable = @YES;
    }
    return result;
}


- (SObject *)readMessagesPage:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethodWithURL:params.pagingData operation:operation processor:^(id result) {
            SObject *object = [self parseMessages:result];
            SObject *currentData = [params copyWithHandler:self];
            [currentData.subObjects addObjectsFromArray:object.subObjects];
            currentData.pagingData = object.pagingData;
            currentData.isPagable = object.isPagable;
            [operation complete:currentData];
        }];
    }];
}

- (SObject *)readDialogs:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"me/inbox" operation:operation processor:^(id responce) {

            NSLog(@"responce = %@", responce);

            SObject *threads = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *thread in responce[@"data"]) {

                SMessageThread *messageThread = [[SMessageThread alloc] initWithHandler:self];

                messageThread.objectId = thread[@"id"];

                SMessageData *message = [[SMessageData alloc] initWithHandler:self];
                NSMutableArray *participiants = [NSMutableArray array];

                for (NSDictionary *to in thread[@"to"][@"data"]) {
                    [participiants addObject:[self dataForUserId:to[@"id"] name:to[@"name"]]];
                }

                messageThread.messages = [self parseMessages:thread[@"comments"]];

                NSArray *comments = thread[@"comments"][@"data"];
                if (comments.count) {
                    NSDictionary *messageData = comments[comments.count - 1];
                    message.message = messageData[@"message"];
                    SUserData
                            *user = [self dataForUserId:messageData[@"from"][@"id"] name:messageData[@"from"][@"name"]];
                    if ([user.objectId isEqualToString:self.currentUserData.objectId]) {
                        message.isOutgoing = @YES;
                    }
                    else {
                        message.messageCompanion = user;
                    }
                }

                if (messageThread.messages.subObjects.count) {
                    message = [messageThread.messages.subObjects lastObject];
                }

                if (!message.messageCompanion) {

                    SUserData *companion = nil;
                    for (SUserData *participiant in participiants) {

                        if (![participiant.objectId isEqualToString:self.currentUserData.objectId]) {
                            companion = participiant;
                        }
                    }
                    if (!companion && participiants.count > 0) {
                        companion = participiants[0];
                    }
                    message.messageCompanion = companion;

                    message.thread = messageThread;
                }
                messageThread.lastMessage = message;
                messageThread.date = message.date;

                [threads addSubObject:messageThread];
            }
            [operation complete:threads];
        }];
    }];
}

- (SObject *)readMessageUpdates:(SObject *)params completion:(SObjectCompletionBlock)completion
{

    SObject *operation = [self operationWithObject:params completion:completion];
    [self addMessageReceiver:operation.copy];
    return operation;
}


- (SObject *)postMessage:(SMessageData *)params completion:(SObjectCompletionBlock)completion
{

    NSString *messageStr = [params.message copy];

    XMPPJID *jid =
            [XMPPJID jidWithUser:[NSString stringWithFormat:@"-%@", params.messageCompanion.objectId] domain:@"chat.facebook.com" resource:nil];

    if ([messageStr length] > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];

        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:[jid full]];
        [message addChild:body];

        NSLog(@"message = %@", message.compactXMLString);

        XMPPElementReceipt *receipt;

        [self.xmppStream sendElement:message andGetReceipt:&receipt];

        SMessageData *sentMessage = [params copyWithHandler:self];
        sentMessage.isOutgoing = @YES;
        sentMessage.messageAuthor = self.currentUserData;
        sentMessage.date = [NSDate date];

        completion(sentMessage);
        return sentMessage;
    }
    else {
        completion([SObject failed]);
        return [SObject failed];
    }
}

- (void)addMessageReceiver:(SObject *)reseiverOperation
{
    if (!self.messageReceivers) {
        self.messageReceivers = [NSMutableArray arrayWithCapacity:1];
    }
    [self.messageReceivers addObject:reseiverOperation];
}

@end