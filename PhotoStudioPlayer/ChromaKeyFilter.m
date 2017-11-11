#import "ChromaKeyFilter.h"
NS_ASSUME_NONNULL_BEGIN

@implementation ChromaKeyFilter

// see: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html

+ (nonnull CIFilter *)filter:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue threshold:(CGFloat)threshold {
    // Allocate memory
    const unsigned int size = 64;
    float *cubeData = (float *)malloc (size * size * size * sizeof (float) * 4);
    float rgb[3], hsv[3], *c = cubeData;
    float target[] = { red, green, blue };

    // Populate cube with a simple gradient going from 0 to 1
    for (int z = 0; z < size; z++){
        rgb[2] = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            rgb[1] = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                rgb[0] = ((double)x)/(size-1); // Red value
                // Convert RGB to HSV
                // You can find publicly available rgbToHSV functions on the Internet
                //                rgbToHSV(rgb, hsv);
                // Use the hue value to determine which to make transparent
                // The minimum and maximum hue angle depends on
                // the color you want to remove
                //                float alpha = (hsv[0] > minHueAngle && hsv[0] < maxHueAngle) ? 0.0f: 1.0f;
                float distance = sqrt(pow(rgb[0] - target[0], 2)
                                      + pow(rgb[1] - target[1], 2)
                                      + pow(rgb[2] - target[2], 2));
                float alpha = distance < threshold ? 0 : 1;
                // Calculate premultiplied alpha values for the cube
                c[0] = rgb[0] * alpha;
                c[1] = rgb[1] * alpha;
                c[2] = rgb[2] * alpha;
                c[3] = alpha;
                c += 4; // advance our pointer into memory for the next color value
            }
        }
    }
    // Create memory with the cube data
    NSData *data = [NSData dataWithBytesNoCopy:cubeData
                                        length:size * size * size * sizeof (float) * 4
                                  freeWhenDone:NO];
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    // Set data for cube
    [colorCube setValue:data forKey:@"inputCubeData"];
    return colorCube;
}

@end
NS_ASSUME_NONNULL_END
