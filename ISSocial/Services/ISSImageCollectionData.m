//
// 



#import "UIImageView+WebCache.h"
#import "MultiImage.h"

@interface ISSImageCollectionData ()
@property(nonatomic, copy) UIImage *(^imageObtainingBlock)();
@end

@implementation ISSImageCollectionData {
    NSString *_identificationString;
}

- (void)updateImageForImageView:(UIImageView *)view {
    if (_url) {
        [view setImageWithURL:_url placeholderImage:view.image];
    }
    else {
        view.image = nil;
    }
}

- (void)loadImageWithCompletion:(void (^)(UIImage *, NSError *))completion {
    UIImage *readyImage = [self fetchImage];
    if (readyImage) {
        completion(readyImage, nil);
        return;
    }

    id <SDWebImageOperation> operation =
            [SDWebImageManager.sharedManager downloadWithURL:self.url
                                                     options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {


                        completion(image, error);
                    }];

}

- (BOOL)isValid {
    return self.url || self.image;
}

- (NSString *)identificationString {
    if (_identificationString) {
        return _identificationString;
    }
    if (self.url) {
        return self.url.absoluteString;
    }
    return nil;
}

- (UIImage *)fetchImage {
    if (self.image) {
        return self.image;
    }
    if (self.imageObtainingBlock) {
        return self.imageObtainingBlock();
    }
    return nil;
}

+ (instancetype)imageDataWithIdentificationString:(NSString *)identificationString obtainingBlock:(UIImage *(^)())obtainingBlock {
    ISSImageCollectionData *data = [self new];
    data->_identificationString = identificationString;
    data.imageObtainingBlock = obtainingBlock;
    return data;
}

@end