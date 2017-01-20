//
//  LayerStackUIView.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 04/07/16.
//  Copyright © 2016 Simen E. Sørensen. All rights reserved.
//

import UIKit

class LayerStackUIView: UIView {
    
    var layers: LinkedList<Layer> = LinkedList<Layer>()
    var currentSelection = -1
    var backgroundSize: CGSize = CGSize.zero
    var backgroundTotalScaleX: CGFloat = 1
    var backgroundTotalScaleY: CGFloat = 1
    var backgroundTotalRotation: CGFloat = 0
    var backgroundTransform: CGAffineTransform = CGAffineTransform()
    var backgroundOrigin: CGPoint = CGPoint.zero

    
    func newBackgroundLayer(_ layer: Layer){
        backgroundSize = (layer.image?.size)!
        currentSelection = 0
        newLayer(layer)
        //TODO: flytt layer til index 0 i stacken hvis det allerede eksisterer layers. Trenger en metode for flytting av layers uansett
        
    }
    
    func newLayer(_ layer: Layer){
        layers.append(layer)
        
        /*
        if let imv = layer.item as? UIImageViewLayer{
            //do stuff with imageview
        }else if let txv = layer.item as? UITextViewLayer {
            //do stuff with textview
        }
        */
        
        layer.scaleCenterAndSetParent(to: self)
        
        deselector(currentSelection)
        currentSelection = layers.count - 1
        selector(currentSelection)
    }
    
    public var count: Int{
        return layers.count
    }
    
    func getLayer(_ index: Int) ->Layer{
        deselector(currentSelection)
        selector(index)
        currentSelection = index
        return layers[index]
    }
    
    func getSelectedLayer() -> Layer{
        return layers[currentSelection]
    }
    
    func removeLayer(_ index: Int){
        if layers.count > 0{
            let layer = getLayer(index).content
            for subview in self.subviews{
                if subview == layer{
                    subview.removeFromSuperview()
                }
            }
            _ = layers.remove(atIndex: index)
            currentSelection = index-1
            selector(currentSelection)
            print("layer removed")
        }
    }
    
    func clearScreen(){
        for _ in(0..<layers.count){
            removeLayer(0)
        }
        
        for subview in self.subviews{
            if subview is LayerItem{
                subview.removeFromSuperview()
            }
        }
    }
    
    func prepareForMerge(){
        deselector(currentSelection)
    }
    
    func mergeCompleted(){
        selector(currentSelection)
    }
    
    fileprivate func deselector(_ index: Int){
        if layers.count > 0 && index >= 0 && index < layers.count{
            let view = layers[index].item 
            view.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 000).cgColor
            view.layer.borderWidth = 0.0
        }
    }
    fileprivate func selector(_ index: Int){
        if layers.count > 0 && index >= 0 && index < layers.count{
            let view = layers[index].item 
            view.layer.borderColor = UIColor(red: 255, green: 0, blue: 0, alpha: 100).cgColor
            view.layer.borderWidth = 1.0/layers[index].totalScaleX
        }
    }
    
    //required init?(coder aDecoder: NSCoder) {
    //    fatalError("init(coder:) has not been implemented")
    //}

}
