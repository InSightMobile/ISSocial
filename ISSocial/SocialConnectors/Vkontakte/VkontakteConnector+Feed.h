//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@interface VkontakteConnector (Feed)
- (SObject *)parsePagingResponce:(id)response paging:(SObject *)paging processor:(SObject * (^)(id))processor;

- (NSArray *)parseAttachments:(NSArray *)attachmentsResponse;

- (void)updateAttachments:(NSArray *)attachments operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completion;

- (NSString *)processToText:(NSString *)source;

- (NSString *)processToHTML:(NSString *)source;

- (SCommentData *)parseCommentEntries:(NSArray *)response object:(SObject *)object paging:(SObject *)paging;

- (void)uploadAttachments:(NSArray *)attachments destination:(NSString *)destination operation:(SocialConnectorOperation *)operation completion:(void (^)(NSArray *))completion;
@end