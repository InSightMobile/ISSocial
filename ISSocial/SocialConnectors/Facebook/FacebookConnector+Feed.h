//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "FacebookConnector.h"

@interface FacebookConnector (Feed)

- (SObject *)parseComments:(id)response forObject:(SObject *)object;
@end