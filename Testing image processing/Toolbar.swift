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
                print("gestureRecognizer added to toolsbutton")
            }else if sub.tag == 1{
                deleteButton = sub as! UIImageView
                let tap = UITapGestureRecognizer(target: self, action: #selector(CustomToolbar.deleteLayer(_:)))
                deleteButton.addGestureRecognizer(tap)
                print("gestureRecognizer added to deletebutton")
            }
        }
    }
    
    func expandToolsMenu(_ sender: UITapGestureRecognizer){
        
    }
    
    
    func deleteLayer(_ sender: UITapGestureRecognizer){
        print("tapped")
        let layerStack = superview as! LayerStackUIView
        layerStack.removeLayer(layerStack.currentSelection)
        
        let matrix = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        
        /*let scaleAnimation = CABasicAnimation(keyPath: "scale")
        scaleAnimation.duration = 1
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = 1.5
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        */
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: [.curveEaseIn,.autoreverse], animations: { () -> Void in
            self.deleteButton.transform = matrix
        }, completion: { (finished: Bool) -> Void in
            self.deleteButton.transform = CGAffineTransform.identity
        })
        //deleteButton.layer.add(scaleAnimation, forKey: "scale")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
}
