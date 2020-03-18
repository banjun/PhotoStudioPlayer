//
//  ChromaKeyFilter.swift
//  PhotoStudioPlayer
//
//  Created by mzp on 2017/12/19.
//  Copyright © 2017 banjun. All rights reserved.
//

import CoreImage

 // see: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html
class ChromaKeyFilter {
    static func filter(_ targetRed: Float, green targetGreen: Float, blue targetBlue: Float, threshold: Float) -> CIFilter {
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
                        let alpha: Float = distance < threshold ? 0.0 : 1.0;
                        // Calculate premultiplied alpha values for the cube
                        c.pointee = red * alpha
                        c = c.advanced(by: 1)
                        c.pointee = green * alpha
                        c = c.advanced(by: 1)
                        c.pointee = blue * alpha
                        c = c.advanced(by: 1)
                        c.pointee = alpha
                        c = c.advanced(by: 1)
                    }
                }
            }
        }

        let colorCube = CIFilter(name: "CIColorCube")
        colorCube?.setValue(size, forKey: "inputCubeDimension")
        // Set data for cube
        colorCube?.setValue(data, forKey:"inputCubeData")
        return colorCube!
    }
}
