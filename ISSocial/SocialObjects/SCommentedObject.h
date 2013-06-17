//
// 




#import "SObject.h"

#ifndef __SCommentedObject_H_
#define __SCommentedObject_H_

@protocol SCommentedObject <SObject>

@property(nonatomic, strong) NSNumber *commentsCount;
@property(nonatomic, strong) NSNumber *canAddComment;
@property(nonatomic, strong) NSNumber *likesCount;
@property(nonatomic, strong) NSNumber *canAddLike;
@property(nonatomic, strong) NSNumber *userLikes;

@end

#endif //__SCommentedObject_H_
