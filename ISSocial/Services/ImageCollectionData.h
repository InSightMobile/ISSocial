//
// 


#ifndef __ImageCollectionData_H_
#define __ImageCollectionData_H_

@interface ImageCollectionData : NSObject

@property(nonatomic) NSUInteger width;
@property(nonatomic) NSUInteger height;
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic) CGFloat quality;
@property(nonatomic) float diagonal;

- (void)updateImageForImageView:(UIImageView *)view;

- (void)loadImageWithCompletion:(void (^)(UIImage *, NSError *))completion;

- (BOOL)isValid;
@end

#endif //__ImageCollectionData_H_
