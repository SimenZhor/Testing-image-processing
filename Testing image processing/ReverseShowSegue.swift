//
//  ReverseShowSegue.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 08/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class Shaking: CALayer {
    
    var animationGroup = CAAnimationGroup()
    
    var maxOffset: CGFloat = 5 //points the layer can move while shaking
    var animationDuration:TimeInterval = 0.5
    var radius:CGFloat = 100
    
    
    override init(layer: Any){
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    init(maxOffset:Float = 5, radius: CGFloat = 100, position: CGPoint){
        super.init()
        
        self.contentsScale = UIScreen.main.scale
        self.opacity = 0
        self.radius = radius
        self.maxOffset = CGFloat(maxOffset)
        self.position = position
        
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = UIScreen.main.bounds
        
        let sublayer = blurView.layer
        sublayer.bounds = CGRect(x: self.position.x - radius, y: self.position.y - radius, width: radius*2, height: radius*2)
        sublayer.backgroundColor = UIColor.clear.cgColor
        sublayer.cornerRadius = radius
        self.addSublayer(sublayer)
        

        
    }
    
    func createOpacityAnimation() -> CABasicAnimation{
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        
        
        opacityAnimation.duration = 0.2
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        
        
        return opacityAnimation
    }
    
    
    
}
