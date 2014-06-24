//
// 

#import "MultiImage.h"


@implementation MultiImage
{
    NSMutableArray *_images;
    float _baseQuality;
    float _aspect;
    int _baseWidth;
    int _baseHeight;
    NSString *_imageWightHeightParamURLFormat;
}

- (BOOL)isAspectKnown
{
    return _aspect > 0.01;
}

- (CGFloat)aspect
{
    if (self.isAspectKnown) {
        return _aspect;
    }
    return 1;
}

- (void)addImageURL:(NSURL *)url forWitdh:(NSUInteger)width height:(NSUInteger)height
{
    if (!url)return;

    NSAssert([url isKindOfClass:[NSURL class]], @"Invalid url");

    if (!_images)_images = [NSMutableArray arrayWithCapacity:1];

    ImageCollectionData *data = [ImageCollectionData new];

    data.width = width;
    data.height = height;
    data.url = url;
    data.diagonal = sqrtf(width * width + height * height);

    if (!self.isAspectKnown) {
        _aspect = ((CGFloat) width) / height;
    }

    [_images addObject:data];
}

- (id)initWithURL:(NSURL *)url
{
    NSAssert([url isKindOfClass:[NSURL class]], @"Invalid url");

    self = [super init];
    if (self) {

        [self addImageURL:url quality:1];

    }
    return self;
}

- (void)addImageURL:(NSURL *)url quality:(CGFloat)quality
{
    if (!url)return;

    NSAssert([url isKindOfClass:[NSURL class]], @"Invalid url");

    if (!_images) {
        _images = [NSMutableArray arrayWithCapacity:1];
    }

    ImageCollectionData *data = [ImageCollectionData new];

    data.width = (NSUInteger) (_baseWidth * quality);
    data.height = (NSUInteger) (_baseHeight * quality);
    data.url = url;
    data.quality = quality;
    data.diagonal = sqrtf(data.width * data.width + data.height * data.height);

    [_images addObject:data];
}

- (NSUInteger)count
{
    return _images.count;
}

- (NSURL *)previewURL
{
    if (!_images.count)return nil;
    return [_images[0] url];
}

- (void)setBaseQuality:(float)quality forWitdh:(int)width height:(int)height
{
    _baseQuality = quality;
    _baseWidth = width;
    _baseHeight = height;
    if (!self.isAspectKnown) {
        _aspect = ((CGFloat) width) / height;
    }
}

- (ImageCollectionData *)bestImageForWidth:(CGFloat)width height:(CGFloat)height
{
    if(_imageWightHeightParamURLFormat) {
        ImageCollectionData *data = [ImageCollectionData new];
        data.width = (NSUInteger) width;
        data.height = (NSUInteger) height;
        data.url = [NSURL URLWithString:[NSString stringWithFormat:_imageWightHeightParamURLFormat,(NSUInteger)width,(NSUInteger)height]];
        return data;
    }

    for (ImageCollectionData *image in _images) {
        if(image.width >= width && image.height >= height) {
            return image;
        }
    }

    CGFloat d = sqrtf(width * width + height * height);
    CGFloat minDiff = CGFLOAT_MAX;
    ImageCollectionData *data = nil;

    for (ImageCollectionData *image in _images) {
        CGFloat diff = fabsf(image.diagonal - d);
        if (diff < minDiff) {
            minDiff = diff;
            data = image;
        }
    }
    return data;
}

- (ImageCollectionData *)bestAviableImage
{
    return [self bestImageForWidth:40000 height:40000];
}

- (void)addImageURL:(NSURL *)url forSize:(int)size
{
    [self addImageURL:url forWitdh:size height:size];
}

- (void)addImage:(UIImage *)image
{

    if (!_images) {
        _images = [NSMutableArray arrayWithCapacity:1];
    }

    ImageCollectionData *data = [ImageCollectionData new];

    data.width = image.size.width;
    data.height = image.size.height;
    data.quality = 1;
    data.image = image;
    [_images addObject:data];
}

- (void)setImageWightHeightURLFormat:(NSString *)format {
    _imageWightHeightParamURLFormat = format;
}
@end