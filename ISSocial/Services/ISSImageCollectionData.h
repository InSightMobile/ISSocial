//
//

@interface ISSImageCollectionData : NSObject

@property(nonatomic) NSUInteger width;
@property(nonatomic) NSUInteger height;
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic) CGFloat quality;
@property(nonatomic) float diagonal;

- (void)updateImageForImageView:(UIImageView *)view;

- (void)loadImageWithCompletion:(void (^)(UIImage *, NSError *))completion;

- (BOOL)isValid;

- (NSString *)identificationString;

- (UIImage *)fetchImage;

+ (instancetype)imageDataWithIdentificationString:(NSString *)identificationString obtainingBlock:(UIImage* (^)())obtainingBlock;

@end

