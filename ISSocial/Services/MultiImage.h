//
// 

#import <Foundation/Foundation.h>
#include "ISSImageCollectionData.h"

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

- (ISSImageCollectionData *)bestImageForWidth:(CGFloat)width height:(CGFloat)height;

- (ISSImageCollectionData *)bestImagexForWidth:(CGFloat)width height:(CGFloat)height;

- (ISSImageCollectionData *)bestAviableImage;

- (void)addImageURL:(NSURL *)url forSize:(int)size;

- (void)addImage:(UIImage *)image;

- (void)addImageData:(ISSImageCollectionData *)imageData;

- (void)setImageWightHeightURLFormat:(NSString *)format;

@end