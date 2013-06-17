//
// 



#import "UIImageView+WebCache.h"
#import "MultiImage.h"

@implementation ImageCollectionData

- (void)updateImageForImageView:(UIImageView *)view
{
    if (_url)
        [view setImageWithURL:_url placeholderImage:view.image];
    else
        view.image = nil;
}

- (void)loadImageWithCompletion:(void (^)(UIImage *, NSError *))completion
{
    if (self.image) {
        completion(self.image, nil);
        return;
    }


    id <SDWebImageOperation> operation =
            [SDWebImageManager.sharedManager downloadWithURL:self.url
                                                     options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {


                completion(image, error);
            }];

}

- (BOOL)isValid
{
    return self.url || self.image;
}
@end