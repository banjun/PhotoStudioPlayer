// NOTE:
// this file is not a part of app.
// in debug build, we can hot reload replacing implementations with this file content.
// steps
// 1. Build & Run
// 2. Edit and save this file while the app is running
// 3. In case for errors, check console log and start over from step 1.
// see also AppDelegate.reloader and SwiftHotReload package.

import Foundation
import AppKit
import PhotoStudioPlayer
import CoreImage
import CoreImage.CIFilterBuiltins

extension ViewController {
    @_dynamicReplacement(for: reload)
    func reload2() {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(0.20, green: 0.45, blue: 0.96, threshold: 0.2))
    }
}
extension ChromaKeyFilter {
    @_dynamicReplacement(for: filter)
    static func filter2(_ targetRed: Float, green targetGreen: Float, blue targetBlue: Float, threshold: Float) -> CIFilter {
        let size = 64
        var data = Data(count: size * size * size * MemoryLayout<Float>.size * 4)
        data.withUnsafeMutableBytes { (cubeData: UnsafeMutableRawBufferPointer) -> Void in
            var c = cubeData.bindMemory(to: Float.self).baseAddress!
            // Populate cube with a simple gradient going from 0 to 1
            for z in 0...size-1 {
                let blue = Float(z) / Float(size-1) // Blue value
                for y in 0...size-1 {
                    let green = Float(y) / Float(size-1) // Green value
                    for x in 0...size-1 {
                        let red = Float(x) / Float(size-1) // Red value
                        // Convert RGB to HSV
                        // You can find publicly available rgbToHSV functions on the Internet
                        //                rgbToHSV(rgb, hsv);
                        // Use the hue value to determine which to make transparent
                        // The minimum and maximum hue angle depends on
                        // the color you want to remove
                        //                float alpha = (hsv[0] > minHueAngle && hsv[0] < maxHueAngle) ? 0.0f: 1.0f;
                        let distance = sqrt(
                            pow(red - targetRed, 2)
                            + pow(green - targetGreen, 2)
                            + pow(blue - targetBlue, 2))

                        // Calculate premultiplied alpha values for the cube
                        if distance < threshold {
                            c[0] = red
                            c[1] = green
                            c[2] = blue
                            c[3] = 0
                        } else {
                            c[0] = red // targetRed * 1
                            c[1] = green // targetGreen * 1
                            c[2] = blue // targetBlue * 1
                            c[3] = 1
                        }
                        c = c.advanced(by: 4)
                    }
                }
            }
        }

        let colorCube = CIFilter.colorCubeWithColorSpace()
        colorCube.cubeDimension = Float(size)
        colorCube.cubeData = data
        colorCube.colorSpace = CGColorSpace(name: CGColorSpace.displayP3)
        return colorCube
    }
}
