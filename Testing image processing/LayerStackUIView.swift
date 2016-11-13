//
//  LayerStackUIView.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 04/07/16.
//  Copyright © 2016 Simen E. Sørensen. All rights reserved.
//

import UIKit

class LayerStackUIView: UIView {
    
    var layers: [UIImageView?] = []
    var currentSelection = 0
    
    func newLayer(_ layer: UIImageView){
        
      
        
    }
    
    func count() -> Int{
        return layers.count
    }
    
    func getLayer(_ index: Int) ->UIImageView{
        deselector(currentSelection)
        selector(index)
        currentSelection = index
        return layers[index]!
    }
    
    func removeLayer(_ index: Int){
        layers.remove(at: index)
        if layers.count>1{
            selector(index)
        }
    }
    
    func clearScreen(){
        for _ in(0..<layers.count){
            removeLayer(0)
        }
        let subViews = self.subviews
        for subview in subViews{
            if subview is UIImageView{
                subview.removeFromSuperview()
            }
        }
    }
    
    func prepareForMerge(){
        deselector(currentSelection)
    }
    
    fileprivate func deselector(_ index: Int){
        if layers.count > 0 && index > 0 && index < layers.count{
            layers[index]?.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 000).cgColor
            layers[index]?.layer.borderWidth = 0.0
        }
    }
    fileprivate func selector(_ index: Int){
        if layers.count > 0 && index > 0 && index < layers.count{
            layers[index]?.layer.borderColor = UIColor(red: 255, green: 0, blue: 0, alpha: 100).cgColor
            layers[index]?.layer.borderWidth = 2.0
        }
    }
    
    fileprivate func aspectResize(_ image: UIImage, size: CGRect) -> CGRect{
        let aspect: CGFloat = image.size.width / image.size.height
        if (size.width / aspect) <= size.height{
            return CGRect(x:size.origin.x, y:size.origin.y, width: size.width, height: size.width/aspect)
        }else{
            //Denne scaler kanskje opp? return size istede?
            return CGRect(x:size.origin.x, y:size.origin.y, width: size.height * aspect, height: size.height)
        }
    }
    
    //required init?(coder aDecoder: NSCoder) {
    //    fatalError("init(coder:) has not been implemented")
    //}

}
