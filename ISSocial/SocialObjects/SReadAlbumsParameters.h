//
//

#import <Foundation/Foundation.h>
#import "SObject.h"

@protocol SReadAlbumsParameters <SObject>

@property(nonatomic, copy) NSNumber *loadImage;
@property(nonatomic, copy) NSNumber *loadAllPhotosMetaAlbum;
@end

@interface SReadAlbumsParameters : SObject <SReadAlbumsParameters>
@end