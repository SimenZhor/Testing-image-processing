//
//  UIImage+Resize.swift
//  Port of UIImage+Resize.m
//  from http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/
//

import Foundation
import UIKit

extension UIImage {
    //
    // UIImage+Alpha
    // http://vocaro.com/trevor/blog/wp-content/uploads/2009/10/UIImage+Alpha.m
    //
    
    // Returns true if the image has an alpha layer
    func hasAlpha() -> Bool {
        let alpha = self.cgImage?.alphaInfo
        return alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast
    }
    
    // Returns a copy of the given image, adding an alpha channel if it doesn't already have one
    func imageWithAlpha() -> UIImage? {
        if hasAlpha() {
            return self
        }
        
        let imageRef = self.cgImage
        let width = imageRef?.width
        let height = imageRef?.height
        
        // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
        let offscreenContext = CGContext(data: nil, width: width!, height: height!, bitsPerComponent: 8, bytesPerRow: 0, space: (imageRef?.colorSpace!)!, bitmapInfo: CGBitmapInfo().rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        offscreenContext?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: CGFloat(width!), height: CGFloat(height!)))
        if let imageRefWithAlpha = offscreenContext?.makeImage() {
            return UIImage(cgImage: imageRefWithAlpha)
        } else {
            return nil
        }
    }
    
    // Creates a mask that makes the outer edges transparent and everything else opaque
    // The size must include the entire mask (opaque part + transparent border)
    // The caller is responsible for releasing the returned reference by calling CGImageRelease
    fileprivate func newBorderMask(_ borderSize: UInt, size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        // Build a context that's the same dimensions as the new size
        let maskContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                                bitsPerComponent: 8, // 8-bit grayscale
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo().rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue);
        
        // Start with a mask that's entirely transparent
        maskContext?.setFillColor(UIColor.black.cgColor)
        maskContext?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // Make the inner part (within the border) opaque
        maskContext?.setFillColor(UIColor.white.cgColor);
        maskContext?.fill(CGRect(x: CGFloat(borderSize), y: CGFloat(borderSize), width: size.width - CGFloat(borderSize) * 2.0, height: size.height - CGFloat(borderSize) * 2.0))
        
        // Get an image of the context
        return maskContext?.makeImage()
    }
    
    // Returns a copy of the image with a transparent border of the given size added around its edges.
    // If the image has no alpha layer, one will be added to it.
    func transparentBorderImage(_ borderSize: UInt) -> UIImage? {
        // If the image does not have an alpha layer, add one
        if let image = imageWithAlpha() {
            let newRect = CGRect(x: 0, y: 0, width: image.size.width + CGFloat(borderSize) * 2.0, height: image.size.height + CGFloat(borderSize) * 2.0)
            
            // Build a context that's the same dimensions as the new size
            let bitmap = CGContext(data: nil, width: Int(newRect.size.width), height: Int(newRect.size.height), bitsPerComponent: (self.cgImage?.bitsPerComponent)!, bytesPerRow: 0,
                                               space: (self.cgImage?.colorSpace!)!, bitmapInfo: (self.cgImage?.bitmapInfo.rawValue)!)
            
            // Draw the image in the center of the context, leaving a gap around the edges
            let imageLocation = CGRect(x: CGFloat(borderSize), y: CGFloat(borderSize), width: image.size.width, height: image.size.height)
            bitmap?.draw(self.cgImage!, in: imageLocation)
            let borderImageRef = bitmap?.makeImage()
            
            // Create a mask to make the border transparent, and combine it with the image
            let maskImageRef = newBorderMask(borderSize, size: newRect.size)
            if let transparentBorderImageRef = borderImageRef?.masking(maskImageRef!) {
                return UIImage(cgImage: transparentBorderImageRef)
            } else {
                return nil
            }
        }
        return nil
    }
    
    // Returns a copy of the image with a colored border of the given size added around its edges.
    // If the image has no alpha layer, one will be added to it.
    func coloredBorderImage(_ borderSize: UInt) -> UIImage? {
        // If the image does not have an alpha layer, add one
        if let image = imageWithAlpha() {
            let newRect = CGRect(x: 0, y: 0, width: image.size.width + CGFloat(borderSize) * 2.0, height: image.size.height + CGFloat(borderSize) * 2.0)
            
            // Build a context that's the same dimensions as the new size
            let bitmap = CGContext(data: nil, width: Int(newRect.size.width), height: Int(newRect.size.height), bitsPerComponent: (self.cgImage?.bitsPerComponent)!, bytesPerRow: 0,
                                               space: (self.cgImage?.colorSpace!)!, bitmapInfo: (self.cgImage?.bitmapInfo.rawValue)!)
            
            // Draw the image in the center of the context, leaving a gap around the edges
            let imageLocation = CGRect(x: CGFloat(borderSize), y: CGFloat(borderSize), width: image.size.width, height: image.size.height)
            bitmap?.draw(self.cgImage!, in: imageLocation)
            //let borderImageRef = CGBitmapContextCreateImage(bitmap)
            
            // fill bitmap with color (border), and combine it with the image
            bitmap?.setFillColor(red: CGFloat(255), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(100))
            let coloredBorderImageRef = bitmap?.makeImage()
            return UIImage(cgImage: coloredBorderImageRef!)
        }
        return nil
    }

    
    // Adds a rectangular path to the given context and rounds its corners by the given extents
    // Original author: BjÃ¶rn SÃ¥llarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    fileprivate func addRoundedRectToPath(_ rect: CGRect, context: CGContext, ovalWidth: CGFloat, ovalHeight: CGFloat) {
        if (ovalWidth == 0 || ovalHeight == 0) {
            context.addRect(rect)
            return
        }
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: ovalWidth, y: ovalHeight)
        let fw = rect.width / ovalWidth
        let fh = rect.height / ovalHeight
        context.move(to: CGPoint(x: fw, y: fh/2))
        //DE FIRE NESTE LINJENE FUNGERER IKKE I SWIFT 3
        //CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1)
        //CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1)
        //CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1)
        //CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1)
        context.closePath()
        context.restoreGState()
    }
    
    //
    // UIImage+RoundedCorner
    // http://vocaro.com/trevor/blog/wp-content/uploads/2009/10/UIImage+RoundedCorner.m
    //
    
    // Creates a copy of this image with rounded corners
    // If borderSize is non-zero, a transparent border of the given size will also be added
    // Original author: BjÃ¶rn SÃ¥llarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    func roundedCornerImage(_ cornerSize:Int, borderSize: Int) -> UIImage? {
        // If the image does not have an alpha layer, add one
        if let image = imageWithAlpha() {
            // Build a context that's the same dimensions as the new size
            if let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height),
                                                   bitsPerComponent: (image.cgImage?.bitsPerComponent)!, bytesPerRow: 0, space: (image.cgImage?.colorSpace!)!, bitmapInfo: (image.cgImage?.bitmapInfo.rawValue)!) {
                
                // Create a clipping path with rounded corners
                context.beginPath()
                addRoundedRectToPath(CGRect(x: CGFloat(borderSize), y: CGFloat(borderSize), width: image.size.width - CGFloat(borderSize) * 2.0,
                    height: image.size.height - CGFloat(borderSize) * 2.0), context:context, ovalWidth:CGFloat(cornerSize), ovalHeight:CGFloat(cornerSize))
                context.closePath()
                context.clip()
                
                // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
                context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                
                // Create a CGImage from the context
                if let clippedImage = context.makeImage() {
                    return UIImage(cgImage:clippedImage)
                }
            }
        }
        return nil
    }
    
    //
    // UIImage+Resize
    // http://vocaro.com/trevor/blog/wp-content/uploads/2009/10/UIImage+Resize.m
    //
    
    // Returns a rescaled copy of the image, taking into account its orientation
    // The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
    func resizedImage(_ newSize: CGSize, quality: CGInterpolationQuality) -> UIImage? {
        var drawTransposed: Bool
        
        switch (imageOrientation) {
        case .left: fallthrough
        case .leftMirrored: fallthrough
        case .right: fallthrough
        case .rightMirrored:
            drawTransposed = true
        default:
            drawTransposed = false
        }
        
        return resizedImage(newSize, transform: transformForOrientation(newSize), transpose: drawTransposed, quality: quality)
    }
    
    
    // Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
    // The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
    // If the new size is not integral, it will be rounded up
    fileprivate func resizedImage(_ newSize: CGSize, transform: CGAffineTransform, transpose: Bool, quality: CGInterpolationQuality) -> UIImage? {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        let transposedRect = CGRect(x: 0, y: 0, width: newRect.size.height, height: newRect.size.width)
        let imageRef = self.cgImage;
        
        // Build a context that's the same dimensions as the new size
        let bitmap = CGContext(data: nil, width: Int(newRect.size.width), height: Int(newRect.size.height), bitsPerComponent: (imageRef?.bitsPerComponent)!,
                                           bytesPerRow: 0, space: (imageRef?.colorSpace!)!, bitmapInfo: (imageRef?.bitmapInfo.rawValue)!)
        
        // Rotate and/or flip the image if required by its orientation
        bitmap?.concatenate(transform)
        
        // Set the quality level to use when rescaling
        bitmap!.interpolationQuality = quality
        
        // Draw into the context; this scales the image
        bitmap?.draw(imageRef!, in: transpose ? transposedRect : newRect);
        
        // Get the resized image from the context and a UIImage
        if let newImageRef = bitmap?.makeImage() {
            return UIImage(cgImage: newImageRef)
        }
        return nil
    }
    
    // Returns a copy of this image that is cropped to the given bounds.
    // The bounds will be adjusted using CGRectIntegral.
    // This method ignores the image's imageOrientation setting.
    func croppedImage(_ bounds: CGRect) -> UIImage? {
        if let imageRef = self.cgImage?.cropping(to: bounds) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
    
    // Returns a copy of this image that is squared to the thumbnail size.
    // If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.)
    func thumbnailImage(_ thumbnailSize: Int, borderSize: Int, cornerRadius: Int, quality: CGInterpolationQuality) -> UIImage? {
        if let resizedImage = resizedImageWithContentMode(.scaleAspectFill, bounds: CGSize(width: CGFloat(thumbnailSize), height: CGFloat(thumbnailSize)), quality: quality) {
            
            // Crop out any part of the image that's larger than the thumbnail size
            // The cropped rect must be centered on the resized image
            // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
            let cropRect = CGRect(x: round((resizedImage.size.width - CGFloat(thumbnailSize)) / 2),
                                      y: round((resizedImage.size.height - CGFloat(thumbnailSize)) / 2),
                                      width: CGFloat(thumbnailSize),  height: CGFloat(thumbnailSize))
            if let croppedImage = resizedImage.croppedImage(cropRect) {
                if let transparentBorderImage = borderSize > 0 ? croppedImage.transparentBorderImage(UInt(borderSize)) : croppedImage {
                    return transparentBorderImage.roundedCornerImage(cornerRadius, borderSize: borderSize)
                }
            }
        }
        
        return nil
    }
    
    // Resizes the image according to the given content mode, taking into account the image's orientation
    func resizedImageWithContentMode(_ contentMode: UIViewContentMode, bounds: CGSize, quality: CGInterpolationQuality) -> UIImage? {
        let horizontalRatio = bounds.width / self.size.width
        let verticalRatio = bounds.height / self.size.height
        var ratio: CGFloat!
        
        switch (contentMode) {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        default:
            NSException.raise(NSExceptionName.invalidArgumentException, format: "Unsupported content mode: %d", arguments:getVaList([contentMode.rawValue]))
        }
        
        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        return resizedImage(newSize, quality: quality)
    }
    
    // Returns an affine transform that takes into account the image orientation when drawing a scaled image
    func transformForOrientation(_ newSize: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        switch (self.imageOrientation) {
        case .down: fallthrough  // EXIF = 3
        case .downMirrored:   // EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: newSize.height)
            transform = transform.rotated(by: CGFloat(M_PI))
        case .left: fallthrough  // EXIF = 6
        case .leftMirrored:   // EXIF = 5
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
        case .right: fallthrough  // EXIF = 8
        case .rightMirrored: // EXIF = 7
            transform = transform.translatedBy(x: 0, y: newSize.height)
            transform = transform.rotated(by: -CGFloat(M_PI_2))
        default: break
        }
        
        switch (self.imageOrientation) {
        case .upMirrored: fallthrough // EXIF = 2
        case .downMirrored: // EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored: fallthrough  // EXIF = 5
        case .rightMirrored:  // EXIF = 7
            transform = transform.translatedBy(x: newSize.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default: break
        }
        
        return transform
    }
}
