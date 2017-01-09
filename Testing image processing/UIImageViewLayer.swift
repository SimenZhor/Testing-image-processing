//
//  UIImageViewLayer.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 05/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class UIImageViewLayer: UIImageView {

    //Bonus Properties:
    var totalRotation:CGFloat = 0
    var totalScaleX:CGFloat = 1
    var totalScaleY:CGFloat = 1
    //var absOrigin:CGPoint = CGPoint.zero
    
    func scaleToScreen(screenSize: CGSize){
        if let imageSize = self.image?.size{
            //let screenSize = self.superview!.frame.size //UIScreen.main.bounds.size
            
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
                self.transform = self.transform.scaledBy(x: scale, y: scale)
                totalScaleX *= scale
                totalScaleY *= scale
                
            }
        }
    }
}
