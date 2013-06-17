//
// Created by yar on 27.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface BlockOperationQueue : NSOperationQueue


@property(nonatomic, retain) NSError *error;

- (void)setCompletionHandler:(void (^)(NSError *))completion;

- (void)failWithError:(NSError *)error;
@end