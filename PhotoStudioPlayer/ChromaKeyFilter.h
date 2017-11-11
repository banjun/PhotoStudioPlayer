@import CoreImage;
NS_ASSUME_NONNULL_BEGIN

@interface ChromaKeyFilter : NSObject

+ (CIFilter *)filter:(float)red green:(float)green blue:(float)blue threshold:(float)threshold;

@end

NS_ASSUME_NONNULL_END
