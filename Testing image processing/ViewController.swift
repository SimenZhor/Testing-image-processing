//
//  ViewController.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 03/07/16.
//  Copyright © 2016 Simen E. Sørensen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

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
        layer?.totalRotation -= sender.rotation
        //sender.velocity kan brukes til å avbryte rotasjonen hvis bevegelsen går fra sakte til fort.
        //print("rotated ", sender.rotation," degrees")
        sender.rotation = 0
    }
    
    @IBAction func moveAround(_ sender: UIPanGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        let layer = layerStack.layers[currentLayer]
        let translation = sender.translation(in: self.view)
        layer?.center = CGPoint(x:(layer?.center.x)! + translation.x,
                                  y:(layer?.center.y)! + translation.y)
        layer?.absOrigin.x += translation.x
        layer?.absOrigin.y += translation.y
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
        let imv = UIImageViewLayer(image: img)
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
    
    
    func merge2(_ layerStack: LayerStackUIView) -> UIImage{
        //prepare each layer:
        var merge: UIImage!
        layerStack.prepareForMerge()
        
        //let backgroundImageSize = layerStack.backgroundSize
        let contextElm = layerStack
        let contextSize = contextElm.frame.size
        let contextOrigin = CGPoint.zero // midlertidig (0,0) fordi layerstack også er superview til layers, så de er relative til hverandre allerede. skal egentlig være: contextElm.frame.origin
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 1);
        let context = UIGraphicsGetCurrentContext()!

        for i in 0...(layerStack.count()-1){ //imageView: UIImageViewLayer! in layerStack.layers{
            
            //Save graphics state
            context.saveGState()
            
            let imageView = (layerStack.layers[i] as  UIImageViewLayer!)!
            let image = CIImage(image: imageView.image!)!
            
            //Finner center-plasseringen til det manipulerte bildet i forhold til context
            //print ("context origin: \(contextOrigin)")
            //print ("frame origin: \(imageView.frame.origin)")
            //print ("frame center: \(imageView.center)")
            //print ("relative center: (\(imageView.center.x - contextOrigin.x),\(imageView.center.y - contextOrigin.y))\n")
            let relativeCenterX = imageView.center.x - contextOrigin.x
            let relativeCenterY = imageView.center.y - contextOrigin.y
            
            let rotationFlipBackMatrix = CGAffineTransform.init(rotationAngle: imageView.totalRotation*2) //transformen i imageview har motsatt koordinatsystem på rotasjonen, så den gjøres feil vei. Retter det opp med denne.
            let matrix = imageView.transform.concatenating(rotationFlipBackMatrix)

            
            //let cicontext = CIContext()
            let tempFilter = CIFilter(name: "CIAffineTransform",
                                      withInputParameters: [kCIInputImageKey: image, kCIInputTransformKey: matrix])
            let filterResult = UIImage(ciImage: ((tempFilter?.outputImage)! as CIImage))
            
            //jobber oss til hjørnet av det transformerte bildet ut ifra det center-punktet vi fant i forhold til context
            let drawOrigin = CGPoint(x: (relativeCenterX - filterResult.size.width*0.5), y: (relativeCenterY - filterResult.size.height*0.5))
            
            print("\n\n Layer index: \(i) \n\n")
            print("UIimage size: \(imageView.image!.size)")
            print("CIimage extent: \(image.extent)")
            print("imageview frame size: \(imageView.frame.size)")
            print("Filter result size: \(filterResult.size)")
            print("draw origin: \(drawOrigin)\n")
            
            let drawingRect : CGRect = CGRect(origin: drawOrigin, size: filterResult.size)
            
            filterResult.draw(in: drawingRect)
            
            //Restore graphics state
            context.restoreGState()
        }
        merge = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //UIImagePNGRepresentation(merge).writeto
        return merge
    }
    
    //MARK: Image Scaling
    
    func scaleToSize(_ image: UIImage, size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
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
            
            let imv = UIImageViewLayer(image: pickedImage)
            imv.contentMode = .scaleAspectFit
            if(layerStack.count() > 0){
                layerStack.newLayer(imv)
            }else{
                layerStack.newBackgroundLayer(imv)
            }
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

