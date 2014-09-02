//
// 

#import <Foundation/Foundation.h>
#include "ImageCollectionData.h"

@interface MultiImage : NSObject

@property(nonatomic, readonly) CGFloat aspect;
@property(nonatomic) BOOL defaultImage;


- (BOOL)isAspectKnown;

- (void)addImageURL:(NSURL *)url forWitdh:(NSUInteger)width height:(NSUInteger)height;

- (id)initWithURL:(NSURL *)url;

- (instancetype)initWithWightHeightURLFormat:(NSString *)imageWightHeightParamURLFormat;


- (void)addImageURL:(NSURL *)url quality:(CGFloat)quality;

- (NSUInteger)count;

- (NSURL *)previewURL;

- (void)setBaseQuality:(float)d forWitdh:(int)width height:(int)height;

- (ImageCollectionData *)bestImageForWidth:(CGFloat)width height:(CGFloat)height;

- (ImageCollectionData *)bestImagexForWidth:(CGFloat)width height:(CGFloat)height;

- (ImageCollectionData *)bestAviableImage;

- (void)addImageURL:(NSURL *)url forSize:(int)size;

- (void)addImage:(UIImage *)image;
- (void)addImageData:(ImageCollectionData *)imageData;

- (void)setImageWightHeightURLFormat:(NSString *)format;

@end