//
// 



#import <Foundation/Foundation.h>
#import "OdnoklassnikiConnector.h"

@interface OdnoklassnikiConnector (Users)
- (SUserData *)dataForUserId:(NSString *)userId;

- (void)updateUserData:(NSArray *)usersData operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completion;
@end