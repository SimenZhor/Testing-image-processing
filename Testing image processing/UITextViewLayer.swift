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
        if let screenSize = superview?.bounds.size{
            
            var boundSize = self.bounds.size
            
                
            if boundSize.width > screenSize.width || boundSize.height > screenSize.height{
                //Image exceeds screen in at least one direction
                var scale: CGFloat = 1
                let boundRatio = (boundSize.width)/(boundSize.height)
                    
                if boundRatio >= 1{
                    //landscape bound
                    scale = screenSize.width/boundSize.width
                }else{
                    //portrait bound
                    scale = screenSize.height/boundSize.height
                }
                
                //apply transform to self (imageview)
                self.scale(xScale: scale, yScale: scale, totScale: scale, border: false)
            }
            //center
            boundSize = self.bounds.size
            let originx = (superview!.bounds.midX - (boundSize.width*0.5))
            let originy = (superview!.bounds.midY - (boundSize.height*0.5))
            let origin = CGPoint.init(x: originx, y: originy)
            print(origin)
            self.frame.origin = origin
        }
    }
    
    func scaleCenterAndSetParent(to: UIView){
        to.addSubview(self)
        self.scaleAndCenterInParent()
    }
    
    func scale(xScale: CGFloat, yScale: CGFloat, totScale: CGFloat, border: Bool){
        self.font = UIFont(name: self.font!.fontName, size: self.font!.pointSize*totScale)
        self.resizeToText()
        self.totalScaleX *= totScale
        self.totalScaleY *= totScale
        print("\n(\(totalScaleX),\(totalScaleY))")
        if border{
            self.layer.borderWidth = 1.0/self.totalScaleX
        }
        
    }
    
    func resizeToText(){
        let height = self.attributedText.size().height
        let width = self.attributedText.size().width
        let rect = CGRect.init(x: self.bounds.origin.x, y: self.bounds.origin.y, width: width+50, height: height+20)
        
        self.bounds = rect
        /*let textArray = String(describing: self.attributedText.string).components(separatedBy: "\n")
        
        let linecount = textArray.count
        if linecount > 1{
            print("\(linecount) lines")
            var longestLine = String()
            for line in textArray{
                if line.characters.count > longestLine.characters.count{
                    longestLine = line
                }
            }
            let rect = CGRect.init(x: self.bounds.origin.x, y: self.bounds.origin.y, width: width+50, height: height+20)
            
            self.bounds = rect
        }else{
            print("one line")
            let rect = CGRect.init(x: self.bounds.origin.x, y: self.bounds.origin.y, width: width+50, height: height+20)
            
            self.bounds = rect
        }*/
        
    }
    
    func rotate(angle: CGFloat){
        self.transform = self.transform.rotated(by: angle)
        self.totalRotation += angle
    }
    

    
}
