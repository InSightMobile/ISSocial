//
// 



#import <Foundation/Foundation.h>
#import "SObject.h"

@class SocialConnector;


@interface FeedConsolidation : NSObject

@property(nonatomic, strong) SObject *dataSource;

@property(nonatomic, copy) NSString *sorkKey;

@property(nonatomic) BOOL ascending;

- (SObject *)loadDataWithConnector:(SocialConnector *)connector params:(SObject *)params operation:(SEL)operation sortingKey:(NSString *)key ascending:(BOOL)ascending completion:(CompletionBlock)completion;


- (SObject *)loadDataMoreContentWithCompletion:(CompletionBlock)completion;

- (NSArray *)consolidatedContent;

@end