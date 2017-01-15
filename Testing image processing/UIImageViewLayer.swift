//
//  UIImageViewLayer.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 05/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class UIImageViewLayer: UIImageView{

    //Bonus Properties:
    var totalRotation:CGFloat = 0
    var totalScaleX:CGFloat = 1
    var totalScaleY:CGFloat = 1
    
    func scaleAndCenterInParent(){
        //Scales and centers to superview, to set superview use function: "scaleCenterAndSetParent(to: UIView)"
        if let screenSize = superview?.frame.size{
            if let imageSize = self.image?.size{
                self.contentMode = .scaleAspectFit
                
                if imageSize.width > screenSize.width || imageSize.height > screenSize.height{
                    //Image exceeds screen in at least one direction
                    var scale: CGFloat = 1
                    let imageRatio = (imageSize.width)/(imageSize.height)
                    
                    if imageRatio >= 1{
                        //landscape picture
                        scale = screenSize.width/imageSize.width
                    }else{
                        //portrait picture
                        scale = screenSize.height/imageSize.height
                    }
                    
                    //apply transform to self (imageview)
                    self.scale(xScale: scale, yScale: scale, totScale: scale, border: false)
                    
                }
                
                //center
                let size = self.frame.size
                self.frame.origin.x = (superview!.bounds.midX - (size.width*0.5))
                self.frame.origin.y = (superview!.bounds.midY - (size.height*0.5))
            }
        }
    }
    
    func scaleCenterAndSetParent(to: UIView){
        to.addSubview(self)
        self.scaleAndCenterInParent()
    }
    
    func scale(xScale: CGFloat, yScale: CGFloat, totScale: CGFloat, border: Bool){
        
        self.transform = self.transform.scaledBy(x: totScale, y: totScale)
        self.totalScaleX *= totScale//xScale
        self.totalScaleY *= totScale//yScale
        if border{
            self.layer.borderWidth = 1.0/self.totalScaleX
        }
        
    }
    
    func rotate(angle: CGFloat){
        self.transform = self.transform.rotated(by: angle)
        self.totalRotation += angle
    }
}
