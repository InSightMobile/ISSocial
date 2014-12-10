//
// 



#import <Foundation/Foundation.h>
#import "SObject.h"

@class SocialConnector;

@interface ISSFeedConsolidation : NSObject

@property(nonatomic, strong) SObject *dataSource;

@property(nonatomic, copy) NSString *sorkKey;

@property(nonatomic) BOOL ascending;

- (SObject *)loadDataWithConnector:(SocialConnector *)connector params:(SObject *)params operation:(SEL)operation sortingKey:(NSString *)key ascending:(BOOL)ascending completion:(SObjectCompletionBlock)completion;


- (SObject *)loadDataMoreContentWithCompletion:(SObjectCompletionBlock)completion;

- (NSArray *)consolidatedContent;

@end