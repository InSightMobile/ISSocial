//
//  SocialConnector.m
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SocialConnector.h"
#import "CacheManager.h"
#import "SUserData.h"

NSString *const kNewMessagesNotification = @"NewMessageNotification";
NSString *const kNewMessagesUnreadStatusChanged = @"kNewMessagesUnreadStatusChanged";

@interface SocialConnector ()

@property(strong, nonatomic) SUserData *currentUserData;

@end

@implementation SocialConnector


- (id)init
{
    self = [super init];
    if (self) {
        _connectorState = [SObject object];
        _handleCache = YES;
        _pageSize = 50;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL selector = [anInvocation selector];

    int numberOfArguments = anInvocation.methodSignature.numberOfArguments;

    NSString *selectorName = NSStringFromSelector(selector);

    if (numberOfArguments == 4 && [selectorName hasSuffix:@":completion:"]) {
        __unsafe_unretained SObject *param;
        __unsafe_unretained SObjectCompletionBlock block;

        [anInvocation getArgument:&param atIndex:2];
        [anInvocation getArgument:&block atIndex:3];

        SObject *result = nil;

        if (self.handleCache && [selectorName hasPrefix:@"cachedRead"]) {

            NSString *newSelectorName = [@"read" stringByAppendingString:[selectorName substringFromIndex:10]];

            SEL newSelector = NSSelectorFromString(newSelectorName);

            result = [self readCached:newSelector params:param completion:block];
        }
        else {
            result = [self processSocialConnectorProtocol:param completion:block operation:anInvocation.selector];
        }

        [anInvocation setReturnValue:&result];
        return;
    }
    [super forwardInvocation:anInvocation];
}

- (SObject *)readCached:(SEL)selector params:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [[CacheManager instance] cashedReadWithConnector:self
                                                  operation:selector
                                                     params:params
                                                        ttl:0
                                                 completion:completion];
}


- (SObject *)defaultOperation:(SObject *)defaultOperation completion:(SObjectCompletionBlock)completion
{

    return [SObject failed:completion];
}

- (SObject *)implementSocialConnectorCallProtocol:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return nil;
}

- (SObject *)processSocialConnectorProtocol:(SObject *)params completion:(SObjectCompletionBlock)completion operation:(SEL)selector
{
    SObject *obj = [SObject objectWithState:SObjectStateUnsupported];
    if (completion)completion(obj);
    return obj;
}

- (NSString *)connectorCode
{
    return nil;
}

- (UIImage *)connectorImage
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_ava.png", self.connectorCode]];
}


- (NSString *)connectorName
{
   return NSLocalizedString(self.connectorCode, nil);
}

- (NSInteger)connectorPriority
{
    return 0;
}

- (NSInteger)connectorDisplayPriority
{
    return 0;
}


- (SocialConnectorOperation *)operationWithParent:(SocialConnectorOperation *)operation
{
    SocialConnectorOperation *op = [[SocialConnectorOperation alloc] initWithHandler:self parent:operation];
    return op;
}

- (SObject *)operationWithObject:(SObject *)object
{
    SocialConnectorOperation *op = [self operationWithParent:object.operation];
    return op.object;
}

- (SObject *)operationWithObject:(SObject *)params
                      completion:(SObjectCompletionBlock)completion
{
    SObject *operationObject = [self operationWithObject:params];
    SocialConnectorOperation *op = operationObject.operation;

    op.completionHandler = completion;
    __block SocialConnectorOperation *weakOp = op;
    op.completion = ^(SObject *result) {
        [weakOp complete:result];
    };
    return operationObject;
}

- (SObject *)operationWithObject:(SObject *)params
                      completion:(SObjectCompletionBlock)completion
                       processor:(void (^)(SocialConnectorOperation *op))processor
{
    if (params.state == SObjectStateUnsupported) {
        if (completion)completion([SObject successful]);
        return [SObject successful];
    }
    SObject *operationObject = [self operationWithObject:params completion:completion];
    [operationObject.operation start];

    processor(operationObject.operation);
    return operationObject;
}


- (BOOL)isLoggedIn
{
    return NO;
}

- (BOOL)isSupported:(SEL)pSelector
{
    if ([self respondsToSelector:pSelector]) {
        SObject *result =
                [self performSelector:pSelector withObject:[SObject objectWithState:SObjectStateUnsupported] withObject:nil];
        return result && result.state != SObjectStateUnsupported;
    }
    else {
        return NO;
    }
}

- (BOOL)meetsSpecification:(NSString *)spec
{
    if ([self.supportedSpecifications containsObject:spec]) {
        return YES;
    }

    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@:completion:", spec]);
    return [self isSupported:sel];
}

@end
