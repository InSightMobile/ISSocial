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
    BOOL _sorted;
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
    if (!url) {
        return;
    }

    NSAssert([url isKindOfClass:[NSURL class]], @"Invalid url");

    if (!_images) {
        _images = [NSMutableArray arrayWithCapacity:1];
    }

    ImageCollectionData *data = [ImageCollectionData new];

    data.width = width;
    data.height = height;
    data.url = url;
    data.diagonal = sqrtf(width * width + height * height);

    if (!self.isAspectKnown) {
        _aspect = ((CGFloat) width) / height;
    }

    [self addImageData:data];
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

- (CGFloat)baseQuality
{
    return _baseQuality > 0 ? _baseQuality : 1.0f;
}

- (void)addImageURL:(NSURL *)url quality:(CGFloat)quality
{
    if (!url) {
        return;
    }

    NSAssert([url isKindOfClass:[NSURL class]], @"Invalid url");

    if (!_images) {
        _images = [NSMutableArray arrayWithCapacity:1];
    }

    ImageCollectionData *data = [ImageCollectionData new];

    data.width = (NSUInteger) (_baseWidth / self.baseQuality * quality);
    data.height = (NSUInteger) (_baseHeight / self.baseQuality * quality);
    data.url = url;
    data.quality = quality;
    data.diagonal = sqrtf(data.width * data.width + data.height * data.height);


    [self addImageData:data];
}

- (NSUInteger)count
{
    return _images.count;
}

- (NSURL *)previewURL
{
    if (!_images.count) {
        return nil;
    }
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
    if (_imageWightHeightParamURLFormat) {
        ImageCollectionData *data = [ImageCollectionData new];
        data.width = (NSUInteger) width;
        data.height = (NSUInteger) height;
        data.url = [NSURL URLWithString:[NSString stringWithFormat:_imageWightHeightParamURLFormat, (NSUInteger) width, (NSUInteger) height]];
        return data;
    }

    [self sortIfNeeded];

    for (ImageCollectionData *image in _images) {
        if (image.width >= width && image.height >= height) {
            return image;
        }
    }

    CGFloat diagonal = sqrtf(width * width + height * height);
    CGFloat minDiff = CGFLOAT_MAX;
    ImageCollectionData *data = nil;

    for (ImageCollectionData *image in _images) {
        if(image.diagonal >= diagonal) {
            CGFloat diff = fabsf(image.diagonal - diagonal);
            if (diff < minDiff) {
                minDiff = diff;
                data = image;
            }
        }
    }

    if(!data) {
        return _images.lastObject;
    }

    return data;
}

- (void)sortIfNeeded
{
    if (_sorted) {
        return;
    }
    [_images sortUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"quality" ascending:YES],
            [NSSortDescriptor sortDescriptorWithKey:@"diagonal" ascending:YES]]];
    _sorted = YES;
}

- (ImageCollectionData *)bestAviableImage
{
    [self sortIfNeeded];
    return [_images lastObject];
}

- (void)addImageURL:(NSURL *)url forSize:(int)size
{
    [self addImageURL:url forWitdh:size height:size];
}

- (void)addImage:(UIImage *)image
{
    ImageCollectionData *data = [ImageCollectionData new];

    data.width = (NSUInteger) image.size.width;
    data.height = (NSUInteger) image.size.height;
    data.quality = 1;
    data.image = image;

    [self addImageData:data];
}

- (void)addImageData:(ImageCollectionData *)imageData
{
    if (!_images) {
        _images = [NSMutableArray arrayWithCapacity:1];
    }

    [_images addObject:imageData];
    _sorted = NO;
}


- (void)setImageWightHeightURLFormat:(NSString *)format
{
    _imageWightHeightParamURLFormat = format;
}

- (instancetype)initWithWightHeightURLFormat:(NSString *)imageWightHeightParamURLFormat
{
    self = [super init];
    if (self) {
        _imageWightHeightParamURLFormat = imageWightHeightParamURLFormat;
    }

    return self;
}

@end