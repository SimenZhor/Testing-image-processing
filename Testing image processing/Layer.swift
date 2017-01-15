//
//  Layer.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 10/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

protocol LayerItem{
    func content() -> Self
    func scaleAndCenterInParent() -> Void
    func scale(xScale: CGFloat, yScale: CGFloat, totScale: CGFloat, border: Bool) -> Void
    func rotate(angle: CGFloat) -> Void
    func scaleCenterAndSetParent(to: UIView) -> Void
    var totalRotation:CGFloat {get set}
    var totalScaleX:CGFloat {get set}
    var totalScaleY:CGFloat {get set}
}



extension UIImageViewLayer: LayerItem {
    func content() -> Self {
        return self
    }
}

extension UITextViewLayer: LayerItem {
    func content() -> Self {
        return self
    }
}

class Layer{

    var item: UIView

    
    public var image: UIImage?{
        if let imv = item as? UIImageViewLayer{
            if imv.image != nil{
                return imv.image
            }else{
                print("layer does not contain any picures yet")
            }
        }else{
            print("This is a text layer")
        }
        return nil
    }
    
    public var text: String?{
        if let txv = item as? UITextViewLayer{
            return txv.text
        }else{
            print("This is an image layer")
        }
        return nil
    }
    public var textView: UITextViewLayer?{
        if let txv = item as? UITextViewLayer{
            return txv
        }else{
            print("This is an image layer")
        }
        return nil
    }
    
    public var content: UIView{
        return item
    }

    public var totalRotation: CGFloat{
        if let imv = item as? UIImageViewLayer{
            return imv.totalRotation
        }else if let txv = item as? UITextViewLayer{
            return txv.totalRotation
        }
        return CGFloat()
        
    }
    
    public var totalScaleX: CGFloat{
        if let imv = item as? UIImageViewLayer{
            return imv.totalScaleX
        }else if let txv = item as? UITextViewLayer{
            return txv.totalScaleX
        }
        return CGFloat()
    }
    
    public var totalScaleY: CGFloat{
        if let imv = item as? UIImageViewLayer{
            return imv.totalScaleY
        }else if let txv = item as? UITextViewLayer{
            return txv.totalScaleY
        }
        return CGFloat()
    }
    
    //MARK: Initializers
    init(_ item: UIView) {
        if let imv = item as? UIImageViewLayer{
            imv.contentMode = .scaleAspectFit
            self.item = imv
        }else{
            self.item = item
        }
    }
    
    
    convenience init(image: UIImage?) {
        self.init(UIImageViewLayer(image: image))
    }
    
    convenience init(text: String){
        let txv = UITextViewLayer(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width-100, height: 100))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attrs = [NSFontAttributeName: UIFont(name: "Impact", size: 50)!, NSParagraphStyleAttributeName: paragraphStyle, NSBackgroundColorAttributeName: UIColor.clear, NSForegroundColorAttributeName: UIColor.white, NSStrokeColorAttributeName: UIColor.black, NSStrokeWidthAttributeName: -2] as [String : Any]
        
        txv.autocapitalizationType = .allCharacters
        txv.backgroundColor = UIColor.clear
        //txv.tintColor = UIColor.white
        txv.textColor = UIColor.white
        txv.isScrollEnabled = false
        txv.clearsContextBeforeDrawing = false
        txv.contentMode = .scaleToFill
        let attrText = NSMutableAttributedString(string: text, attributes: attrs)
        txv.attributedText = attrText
        //txv.frame.size.height = txv.contentSize.height
        txv.keyboardDismissMode = .interactive
        txv.translatesAutoresizingMaskIntoConstraints = true
        txv.resizeToText()
        self.init(txv)
    }
    convenience init(text: String, frame: CGRect){
        let txv = UITextViewLayer(frame: frame)
        txv.text = text
        self.init(txv)
    }
    
    //MARK: Functions
    
    func scaleCenterAndSetParent(to: UIView){
        
        if let imv = item as? UIImageViewLayer{
            imv.scaleCenterAndSetParent(to: to)
        }else if let txv = item as? UITextViewLayer{
            txv.scaleCenterAndSetParent(to: to)
        }
    }

    func scale(xScale: CGFloat, yScale: CGFloat, totScale: CGFloat, border: Bool){
        
        if let imv = item as? UIImageViewLayer{
            imv.scale(xScale: xScale, yScale: yScale, totScale: totScale, border: border)
        }else if let txv = item as? UITextViewLayer{
            txv.scale(xScale: xScale, yScale: yScale, totScale: totScale, border: border)
        }
    }
    func rotate(angle: CGFloat){
        
        if let imv = item as? UIImageViewLayer{
            imv.rotate(angle: angle)
        }else if let txv = item as? UITextViewLayer{
            txv.rotate(angle: angle)
        }
    }
    
}
