//
//  Toolbar.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 04/07/16.
//  Copyright © 2016 Simen E. Sørensen. All rights reserved.
//

import UIKit

class CustomToolbar: UIView {

    var toolsButton = UIImageView()
    var deleteButton = UIImageView()
    
    
    override func awakeFromNib() {
        setup()
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        setup()
        
        
    }
    
    func setup(){
        print("subview.count: \(subviews.count)")
        for sub in subviews{
            
            if sub.tag == 0{
                toolsButton = sub as! UIImageView
                toolsButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CustomToolbar.expandToolsMenu(_:))))
            }else if sub.tag == 1{
                deleteButton = sub as! UIImageView
                let tap = UITapGestureRecognizer(target: self, action: #selector(CustomToolbar.deleteLayer(_:)))
                deleteButton.addGestureRecognizer(tap)
            }
        }
    }
    
    func expandToolsMenu(_ sender: UIGestureRecognizer){
        
    }
    
    
    func deleteLayer(_ sender: UIGestureRecognizer){
        print("tapped")
        let layerStack = superview as! LayerStackUIView
        layerStack.removeLayer(layerStack.currentSelection)
        
        /*let matrix = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: [.curveEaseIn,.autoreverse], animations: { () -> Void in
            self.deleteButton.transform = matrix
        }, completion: { (finished: Bool) -> Void in
            self.deleteButton.transform = CGAffineTransform.identity
        })*/
        
        
        
    }
    
    func createSpringScaleAnimation() -> CASpringAnimation{
        let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 0.5//scaleAnimation.settlingDuration
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = 1.5
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        scaleAnimation.autoreverses = true
        scaleAnimation.damping = 1.5
        scaleAnimation.initialVelocity = 5
        
        
        return scaleAnimation
    }
    func createOpacityAnimation() -> CABasicAnimation{
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        
        
        opacityAnimation.duration = 0.2
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        
        
        return opacityAnimation
    }
    func createBlurLayer(below: UIView){
        
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = below.bounds//UIScreen.main.bounds
        
        let sublayer = blurView.layer
        sublayer.backgroundColor = UIColor.clear.cgColor
        sublayer.cornerRadius = CGFloat(blurView.frame.width/2)
        sublayer.add(createOpacityAnimation(), forKey: "opacity")
        
        let maskPath = UIBezierPath(ovalIn: CGRect(x: blurView.center.x-26, y: blurView.center.y-26, width: 52, height: 52))
        let mask = CAShapeLayer()
        mask.path = maskPath.cgPath
        sublayer.mask = mask
        
        blurView.center = self.convert(deleteButton.center, to: superview!)
        
        superview?.addSubview(blurView)
        superview?.bringSubview(toFront: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
}
