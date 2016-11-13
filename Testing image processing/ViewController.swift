//
//  ViewController.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 03/07/16.
//  Copyright © 2016 Simen E. Sørensen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var pan: UIPanGestureRecognizer!
    @IBOutlet var zoom: UIPinchGestureRecognizer!
    @IBOutlet var rotate: UIRotationGestureRecognizer!
    @IBOutlet weak var newLayerButton: NSLayoutConstraint!
    @IBOutlet weak var nextLayerButton: UIButton!
    @IBOutlet weak var prevLayerButton: UIButton!
    @IBOutlet weak var layerStack: LayerStackUIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    var bg: UIImage!
    var overlay: UIImage!
    var merge: UIImage!
    var tempoverlay: UIImage!
    var currentLayer = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zoom.isEnabled = true
        
        imagePicker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Actions


    @IBAction func resizeAction(_ sender: UIPinchGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        let layer = layerStack.layers[currentLayer]
        layer?.transform = (layer?.transform.scaledBy(x: sender.scale, y: sender.scale))!
        //print("resized to a scale of: ",sender.scale)
        sender.scale = 1
    }
 
    
    @IBAction func rotate(_ sender: UIRotationGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        let layer = layerStack.layers[currentLayer]
        layer?.transform = (layer?.transform.rotated(by: sender.rotation))!
        //print("rotated ", sender.rotation," degrees")
        sender.rotation = 0
    }
    
    @IBAction func moveAround(_ sender: UIPanGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        let layer = layerStack.layers[currentLayer]
        let translation = sender.translation(in: self.view)
        layer?.center = CGPoint(x:(layer?.center.x)! + translation.x,
                                  y:(layer?.center.y)! + translation.y)
        
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @IBAction func newLayer(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary

        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func nextLayer(_ sender: UIButton) {
        currentLayer = layerStack.currentSelection
        if (currentLayer+1) < layerStack.count(){
            layerStack.getLayer(layerStack.currentSelection+1)
            //print("fra: ",currentLayer," til: ",(currentLayer+1))
        }else if layerStack.count() == 0{
            //print("No layers")
        }
        else{
            //print("går til første")
            layerStack.getLayer(0)
        }
    }
    
    @IBAction func prevLayer(_ sender: UIButton) {
        currentLayer = layerStack.currentSelection
        if (currentLayer-1) >= 0{
            layerStack.getLayer(layerStack.currentSelection-1)
            //print("fra: ",currentLayer," til: ",(currentLayer-1))
        }else if layerStack.count() == 0{
            //print("No layers")
        }else{
            //print("går til siste")
            layerStack.getLayer(layerStack.count()-1)
        }
    }
    
    @IBAction func done(_ sender: UIButton) {
        let img = merge2(layerStack)
        layerStack.clearScreen()
        let imv = UIImageView(image: img)
        imv.contentMode = .scaleAspectFit
        
        layerStack.newLayer(imv)
    }
    
    @IBAction func newTextLayer(_ sender: UIButton) {
    }
    
    
    //MARK: Image Processing

    func merge(_ bg: UIImage, overlay: UIImage){
        let size = bg.size
        UIGraphicsBeginImageContext(size)
        
        let bgSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let areaSize = CGRect(x: 0, y: 0, width: overlay.size.width, height: overlay.size.height)
        bg.draw(in: bgSize)
        
        overlay.draw(in: areaSize, blendMode: .normal, alpha: 1)
        
        merge = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func merge2(_ layers: LayerStackUIView) -> UIImage{
        //prepare each layer:
        var merge: UIImage!
        layerStack.prepareForMerge()
        for imageView: UIImageView! in layerStack.layers{
            let image = imageView.image
            let boundsScale = layerStack.bounds.size.width / layerStack.bounds.size.height
            let imageScale = image!.size.width / image!.size.height
            
            let size = (image?.size)!
            
            var canvasSize = size
            
            if boundsScale > imageScale {
                canvasSize.width =  canvasSize.height * boundsScale
            }else{
                canvasSize.height =  canvasSize.width / boundsScale
            }
            
            let xScale = canvasSize.width / imageView.bounds.size.width
            let yScale = canvasSize.height / imageView.bounds.size.height
            
            let center = imageView.center.applying(CGAffineTransform.identity.scaledBy(x: xScale, y: yScale))
            
            let xCenter = center.x
            let yCenter = center.y
            
            UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0);
            let context = UIGraphicsGetCurrentContext()!
            
            //Apply transformation
            context.translateBy(x: xCenter, y: yCenter)
            
            context.concatenate(imageView.transform)
            
            context.translateBy(x: -xCenter, y: -yCenter)
            
            
            var drawingRect : CGRect = CGRect.zero
            drawingRect.size = canvasSize
            
            //Translation
            drawingRect.origin.x = (xCenter - size.width*0.5)
            drawingRect.origin.y = (yCenter - size.height*0.5)
            
            //Aspectfit calculation
            
            if boundsScale > imageScale {
                drawingRect.size.width =  drawingRect.size.height * imageScale
            }else{
                drawingRect.size.height = drawingRect.size.width / imageScale
            }
            
            //if  (layerStack.bounds.width / imageScale) <= layerStack.bounds.size.height {
            //    drawingRect.size.width = layerStack.bounds.width
            //    drawingRect.size.height = layerStack.bounds.width / imageScale
            //}else{
            //    drawingRect.size.width = layerStack.bounds.height * imageScale
            //   drawingRect.size.height = layerStack.bounds.height
            //}
            
            image!.draw(in: drawingRect)
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
            //UIImagePNGRepresentation(newImage)?.writeToFile("/Users/admin/Desktop/xyy.png", atomically: true)
            
            //let sb = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            //let vc = sb.instantiateViewControllerWithIdentifier("DetailViewController") as? ViewController
            
            let imv = UIImageView(image: newImage)
            imv.contentMode = .scaleAspectFit
            layerStack.layers[0]!.image = newImage
            //self.navigationController?.pushViewController(vc!, animated: true)

            
            if (merge == nil){
                merge = newImage
            }else{
                //let mergeScale = merge.size.width / merge.size.height
                //let newImageScale = newImage.size.width / newImage.size.height
                //var size2 = newImage.size
                //if (mergeScale) > (newImageScale){
                //    size2.width = size2.height * newImageScale
                //}else{
                //    size2.height = size2.width / newImageScale
                //}
                UIGraphicsBeginImageContext(merge.size)
            
                let bgSize = CGRect(x: 0, y: 0, width: merge.size.width, height: merge.size.height)
                //let areaSize = CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height)
                merge.draw(in: bgSize)
                
                newImage?.draw(in: bgSize, blendMode: .normal, alpha: 1)
            
                merge = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
        
            }
        }
        //UIImagePNGRepresentation(merge).writeto
        return merge
    }
    
    //MARK: Image Scaling
    
    func scaleToSize(_ image: UIImage, size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let ret = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return ret!
    }
    
    func aspectFit(_ image: UIImage, size: CGSize) -> UIImage{
        let aspect: CGFloat = size.width / size.height
        if (size.width / aspect) <= size.height{
            return scaleToSize(image, size: CGSize(width: size.width, height: size.width/aspect))
        }else{
            return scaleToSize(image, size: CGSize(width: size.height * aspect, height: size.height))
        }
    }
    
    func aspectResize(_ image: UIImage, size: CGSize) -> CGSize{
        let aspect: CGFloat = size.width / size.height
        if (size.width / aspect) <= size.height{
            return CGSize(width: size.width, height: size.width/aspect)
        }else{
            return CGSize(width: size.height * aspect, height: size.height)
        }
    }
    
    
    //MARK: Imagepicker methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]){
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            //imageView.contentMode = .ScaleAspectFit
            
            let imv = UIImageView(image: pickedImage)
            imv.contentMode = .scaleAspectFit
            
            layerStack.newLayer(imv)
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Gesture delegates
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
}

