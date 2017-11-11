@import CoreImage;
NS_ASSUME_NONNULL_BEGIN

@interface ChromaKeyFilter : NSObject

+ (CIFilter *)filter:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue threshold:(CGFloat)threshold;

@end

NS_ASSUME_NONNULL_END
