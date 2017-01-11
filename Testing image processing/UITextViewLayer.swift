//
//  UITextViewLayer.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 10/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class UITextViewLayer: UITextView {

    //Bonus Properties:
    var totalRotation:CGFloat = 0
    var totalScaleX:CGFloat = 1
    var totalScaleY:CGFloat = 1
    
    func scaleAndCenterInParent(){
        //Scales and centers to superview, to set superview use function: "scaleCenterAndSetParent(to: UIView)"
        if let screenSize = superview?.frame.size{
            
            let frameSize = self.frame.size
                
                
            if frameSize.width > screenSize.width || frameSize.height > screenSize.height{
                //Image exceeds screen in at least one direction
                var scale: CGFloat = 1
                let frameRatio = (frameSize.width)/(frameSize.height)
                    
                if frameRatio >= 1{
                    //landscape frame
                    scale = screenSize.width/frameSize.width
                }else{
                    //portrait frame
                    scale = screenSize.height/frameSize.height
                }
                
                //apply transform to self (imageview)
                self.scale(xScale: scale, yScale: scale, totScale: scale, border: false)
                
            
                
                //center
                self.frame.origin.x = (superview!.bounds.midX - (frameSize.width*0.5))
                self.frame.origin.y = (superview!.bounds.midY - (frameSize.height*0.5))
            }
        }
    }
    
    func scaleCenterAndSetParent(to: UIView){
        to.addSubview(self)
        self.scaleAndCenterInParent()
    }
    
    func scale(xScale: CGFloat, yScale: CGFloat, totScale: CGFloat, border: Bool){
        
        //self.bounds.applying(CGAffineTransform(scaleX: xScale, y: yScale))
        self.transform = self.transform.scaledBy(x: xScale, y: yScale)
        self.totalScaleX *= xScale
        self.totalScaleY *= yScale
        if border{
            self.layer.borderWidth = 1.0/self.totalScaleX
        }
        
    }
    
    func rotate(angle: CGFloat){
        self.transform = self.transform.rotated(by: angle)
        self.totalRotation += angle
    }
    

    
}
