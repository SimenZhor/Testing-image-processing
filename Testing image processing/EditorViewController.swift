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

class EditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, RenderDelegate {
    
    @IBOutlet var pan: UIPanGestureRecognizer!
    @IBOutlet var zoom: UIPinchGestureRecognizer!
    @IBOutlet var rotate: UIRotationGestureRecognizer!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    @IBOutlet weak var newLayerButton: UIBarButtonItem!
    @IBOutlet weak var nextLayerButton: UIBarButtonItem!
    @IBOutlet weak var prevLayerButton: UIBarButtonItem!
    @IBOutlet weak var layerStack: LayerStackUIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var deleteButton: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var remadeToolbar: CustomToolbar!
    
    let imagePicker = UIImagePickerController()
    var bg: UIImage!
    var overlay: UIImage!
    var merge: UIImage!
    var tempoverlay: UIImage!
    var currentLayer = 0
    
    var ppos: CGPoint?
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        self.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        let itemsize = CGSize(width: 52, height: 52)
        let rect = CGRect(origin: remadeToolbar.frame.origin, size: itemsize)
        let toolsmenu = ExpandingMenuButton(frame: rect, centerImage: #imageLiteral(resourceName: "Settings"), centerHighlightedImage: #imageLiteral(resourceName: "Settings"))
        self.layerStack.addSubview(toolsmenu)
        toolsmenu.expandingDirection = .top
        toolsmenu.menuTitleDirection = .right
        
        let linkLayers = ExpandingMenuItem(size: itemsize, title: "Link Layers", titleColor: UIColor.white, image: #imageLiteral(resourceName: "Link"), highlightedImage: #imageLiteral(resourceName: "Link"), backgroundImage: nil, backgroundHighlightedImage: nil, itemTapped: {() -> Void in
            self.linkLayers(indexlist: [0,1])
        })
        let unlinkAll = ExpandingMenuItem(size: itemsize, title: "Unlink All", titleColor: UIColor.white, image: #imageLiteral(resourceName: "Unlink"), highlightedImage: #imageLiteral(resourceName: "Unlink"), backgroundImage: nil, backgroundHighlightedImage: nil, itemTapped: {() -> Void in
            self.linkLayers(indexlist: [0,1])
        })
        let eraseBG = ExpandingMenuItem(size: itemsize, title: "Eraser", titleColor: UIColor.white, image: #imageLiteral(resourceName: "Erase"), highlightedImage: #imageLiteral(resourceName: "Erase"), backgroundImage: nil, backgroundHighlightedImage: nil, itemTapped: {() -> Void in
            self.linkLayers(indexlist: [0,1])
        })
        let rearrangeLayers = ExpandingMenuItem(size: itemsize, title: "Rearrange Layers", titleColor: UIColor.white, image: #imageLiteral(resourceName: "Rearrange"), highlightedImage: #imageLiteral(resourceName: "Rearrange"), backgroundImage: nil, backgroundHighlightedImage: nil, itemTapped: {() -> Void in
            self.linkLayers(indexlist: [0,1])
        })
        toolsmenu.addMenuItems([eraseBG, unlinkAll, linkLayers,rearrangeLayers])
                
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zoom.isEnabled = true
        imagePicker.delegate = self
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    
    @IBAction func resizeAction(_ sender: UIPinchGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        if let (x,y) = sender.scale(view: self.view){
            layerStack.layers[currentLayer].scale(xScale: x, yScale: y, totScale: sender.scale, border: true)
        }else{
            layerStack.layers[currentLayer].scale(xScale: sender.scale, yScale: sender.scale, totScale: sender.scale, border: true)
        }
        
        //print("resized to a scale of: ",sender.scale)
        sender.scale = 1
    }
    
    
    @IBAction func rotate(_ sender: UIRotationGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        let layer = layerStack.layers[currentLayer]
        layer.rotate(angle: sender.rotation)
        //sender.velocity kan brukes til å avbryte rotasjonen hvis bevegelsen går fra sakte til fort.
        //print("rotated ", sender.rotation," degrees")
        sender.rotation = 0
    }
    
    @IBAction func moveAround(_ sender: UIPanGestureRecognizer) {
        currentLayer = layerStack.currentSelection
        if currentLayer >= 0{
            let layer = layerStack.layers[currentLayer].item
            
            if pan.state == .began{
                let scaleAnimation = remadeToolbar.createSpringScaleAnimation()
                remadeToolbar.createBlurLayer(below: deleteButton)
                deleteButton.layer.add(scaleAnimation, forKey: "transform.scale")
            }else if pan.state == .changed{
                
                
                let translation = sender.translation(in: self.view)
                layer.center = CGPoint(x:layer.center.x + translation.x,
                                       y:layer.center.y + translation.y)
                if ppos != nil{
                    
                    if deleteButton.frame.contains(pan.location(in: remadeToolbar)) && !deleteButton.frame.contains(ppos!){
                        //tap gesture is now within deletebutton radius, previous touch was not
                        let masklayer = CAShapeLayer()
                        masklayer.frame = layer.frame
                        masklayer.bounds = layer.frame
                        layer.layer.mask = masklayer
                        masklayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: layer.bounds.width, height: layer.bounds.height)).cgPath
                        
                        
                        let animation = layerStack.layers[currentLayer].createReduceToCircleAnimation(fromValue: masklayer.path!, center: pan.location(in: layer))
                        
                        masklayer.add(animation, forKey: "path")
                        /*
                        let opacity = CABasicAnimation(keyPath: "opacity")
                        opacity.fromValue = 1
                        opacity.toValue = 0.75
                        opacity.duration = 0.5
                        layer.layer.add(opacity, forKey: "opacity")
                        layer.layer.opacity = 0.75
                        */
                        
                    }else if !deleteButton.frame.contains(pan.location(in: remadeToolbar)) && deleteButton.frame.contains(ppos!){
                        //tap gesture has been moved away from deletebutton
                        layer.layer.mask = nil
                        /*
                        layer.layer.opacity = 1
                        layer.layer.removeAllAnimations()
                        */
                    }
                }
                ppos = pan.location(in: remadeToolbar)
                sender.setTranslation(CGPoint.zero, in: self.view)
            }else if pan.state == .ended{
                
                for sub in layerStack.subviews{
                    
                    if sub.tag == 3{
                        sub.removeFromSuperview()
                    }
                }
                
                if deleteButton.frame.contains(pan.location(in: remadeToolbar)){
                    layerStack.removeLayer(layerStack.currentSelection)
                }
            }
        }
    }
    
    @IBAction func longPressActivateDelete(_ sender: UILongPressGestureRecognizer) {
        
    }
    

    
    @IBAction func nextLayer(_ sender: UIBarButtonItem) {
        currentLayer = layerStack.currentSelection
        if (currentLayer+1) < layerStack.count{
            _ = layerStack.getLayer(layerStack.currentSelection+1)
            //print("fra: ",currentLayer," til: ",(currentLayer+1))
        }else if layerStack.count == 0{
            //print("No layers")
        }
        else{
            //print("går til første")
            _ = layerStack.getLayer(0)
        }
    }
    
    @IBAction func prevLayer(_ sender: UIBarButtonItem) {
        currentLayer = layerStack.currentSelection
        if (currentLayer-1) >= 0{
            _ = layerStack.getLayer(layerStack.currentSelection-1)
            //print("fra: ",currentLayer," til: ",(currentLayer-1))
        }else if layerStack.count == 0{
            //print("No layers")
        }else{
            //print("går til siste")
            _ = layerStack.getLayer(layerStack.count-1)
        }
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
               
        /*
         if layerStack.layers.count > 0{
            let img = merge(layerStack)
            layerStack.clearScreen()
            let imv = UIImageViewLayer(image: img)
            imv.contentMode = .scaleAspectFit
            layerStack.newLayer(imv)
            layerStack.layers[0]?.transform = layerStack.backgroundTransform //overføring til den nye viewen
            layerStack.layers[0]?.totalScaleX = layerStack.backgroundTotalScaleX //(unødvendig uten transformen som også gjøres
            layerStack.layers[0]?.totalScaleY = layerStack.backgroundTotalScaleY //(unødvendig uten transformen som også gjøres
            layerStack.layers[0]?.totalRotation = layerStack.backgroundTotalRotation //(unødvendig uten transformen som også gjøres
        }
        */
    }
    
    @IBAction func newLayer(_ sender: UIBarButtonItem) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
        layerStack.bringSubview(toFront: remadeToolbar)
    }
    
    @IBAction func newTextLayer(_ sender: UIButton) {
        let layer = Layer(text: "NEW TEXT LAYER")
        layer.textView?.delegate = self
        setDoneOnKeyboard(layer.textView!)
        if(layerStack.count > 0){
            layerStack.newLayer(layer)
        }else{
            layerStack.newBackgroundLayer(layer)
        }
        layer.textView!.becomeFirstResponder()
        layerStack.bringSubview(toFront: remadeToolbar)
    }
    
    
    
    func linkLayers(indexlist: [Int]){
    
    }

    func unusedDeleteLayer(index: Int){
        
    }
    
    
    //MARK: Image Processing
    
    func merge(_ layerStack: LayerStackUIView) -> UIImage{
        //prepare each layer:
        var merge: UIImage!
        layerStack.prepareForMerge()
        
        //klargjør konteksten:
        let contextElm = layerStack.layers[0].item as! LayerItem
        var contextSize = CGSize()
        var contextOrigin = CGPoint()
        var backgroundImage = UIImage()
        
        if let imv = contextElm as? UIImageViewLayer{
            contextSize = imv.image!.size
            contextOrigin = layerStack.convert(imv.bounds.origin, from: imv)
            backgroundImage = imv.image!
        }else if let txv = contextElm as? UITextViewLayer{
            //Kan ikke ha tekst som bakgrunn (foreløpig)
        }
        
        
        //Behandler background layer
        //layerStack.backgroundOrigin = contextOrigin //skal brukes på UIImageView når metoden er ferdig
        //layerStack.backgroundTransform = contextElm.transform //skal brukes på UIImageView når metoden er ferdig
        layerStack.backgroundTotalScaleX = contextElm.totalScaleX //skal brukes på resterende layers
        layerStack.backgroundTotalScaleY = contextElm.totalScaleY //skal brukes på resterende layers
        layerStack.backgroundTotalRotation = contextElm.totalRotation //skal brukes på resterende layers
        
        
        if layerStack.layers.count == 1 {
            return layerStack.layers[0].image!
        }
        
        
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = .high
        
        
        let backgroundRect = CGRect(origin: CGPoint.zero, size: contextSize)
        backgroundImage.draw(in: backgroundRect)
        
        
        //klargjør matriser og skaleringer
        let xScale = layerStack.backgroundTotalScaleX
        let yScale = layerStack.backgroundTotalScaleY
        var matrix = CGAffineTransform()
        let backgroundRotationMatrix = CGAffineTransform.init(rotationAngle: -layerStack.backgroundTotalRotation)
        let backgroundRescaleMatrix = CGAffineTransform.init(scaleX: 1/xScale, y: 1/yScale) //NOTAT: skaleringen her skal være lik skaleringen som blir gjort på bakgrunnen når denne tegnes i konteksten og ikke blir tilført affine-avbildningen
        var ownScaleMatrix = CGAffineTransform()
        var ownRotationMatrix = CGAffineTransform()
        
        
        //behandler resterende layers:
        for i in 1...(layerStack.count-1){ //imageView: Layer! in layerStack.layers{
            context.saveGState()
            let layer = (layerStack.layers[i] as  Layer!)!
            
            //Variables needed from specific layertypes
            var image: UIImage?
            var textView: UITextViewLayer?
            var relativeCenterX = CGFloat()
            var relativeCenterY = CGFloat()
            var layerBounds = CGSize()
            
            if let imv = layer.item as? UIImageViewLayer{
                image = imv.image!
                relativeCenterX = (imv.center.x - contextOrigin.x)/xScale
                relativeCenterY = (imv.center.y - contextOrigin.y)/yScale
                layerBounds = imv.bounds.size
                
                //Klargjøring av matriser
                ownScaleMatrix = CGAffineTransform.init(scaleX: layer.totalScaleX, y: layer.totalScaleY)
                ownRotationMatrix = CGAffineTransform.init(rotationAngle: layer.totalRotation)
                
                matrix = backgroundRescaleMatrix.concatenating(ownScaleMatrix)
                matrix = matrix.concatenating(ownRotationMatrix)
                matrix = matrix.concatenating(backgroundRotationMatrix)
                
                /*if (layer.totalScaleY/yScale) > 1 || (layer.totalScaleX/xScale > 1){
                    //WARNING about to loose quality
                    let alert = UIAlertController(title: "Warning: Quality loss", message: "You are about to scale the image in layer \(i+1) to a size larger than it's original dimentions (\(layer.image!.size.width)x\(layer.image!.size.height). This will result in a quality loss.)", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    let scaleBG = UIAlertAction(title: "Scale background down instead", style: .cancel, handler: {
                        action in
                        //endre på layer[0] totalscale verdiene og start metoden på nytt
                    })
                    alert.addAction(ok)
                    alert.addAction(scaleBG)
                    
                    present(alert, animated: true, completion: nil)
                }*/
                
            }else if let txv = layerStack.layers[i].item as? UITextViewLayer{
                textView = txv
                relativeCenterX = (txv.center.x - contextOrigin.x)/xScale
                relativeCenterY = (txv.center.y - contextOrigin.y)/yScale
                layerBounds = txv.attributedText.size()
                
                //Textview er allerede skalert, trenger ikke ownScaleMatrix
                ownRotationMatrix = CGAffineTransform.init(rotationAngle: layer.totalRotation)
                
                
                matrix = backgroundRescaleMatrix
                matrix = matrix.concatenating(ownRotationMatrix)
                matrix = matrix.concatenating(backgroundRotationMatrix)
            }
            
            //Finner center-plasseringen til det manipulerte bildet i forhold til context
            
            
            var relCenter = CGPoint(x: relativeCenterX, y: relativeCenterY)
            relCenter = relCenter.applying(backgroundRotationMatrix)
            
           
            
            
            
            
            
            
            
            
            context.translateBy(x: relCenter.x, y: relCenter.y)
            context.concatenate(matrix)
            context.translateBy(x: -relCenter.x, y: -relCenter.y)
            
            
            //Prepare for draw to context:
            let drawOrigin = CGPoint(x: (relCenter.x - layerBounds.width*0.5), y: (relCenter.y - layerBounds.height*0.5))
            let drawingRect : CGRect = CGRect(origin: drawOrigin, size: layerBounds)
            
            //Draw to context:
            if image != nil{
                image!.draw(in: drawingRect)
            }else if textView != nil{
                let text = textView?.attributedText

                text?.draw(in: drawingRect)
                //draw(with: drawingRect, options: .truncatesLastVisibleLine, attributes: attrs, context: context)
            }
            context.restoreGState()
        }
        merge = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //UIImagePNGRepresentation(merge).writeto
        return merge
    }

    
    
    //MARK: Imagepicker methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]){
        if var pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            pickedImage = pickedImage.fixOrientation()
            
            let layer = Layer(image: pickedImage)
            if(layerStack.count > 0){
                layerStack.newLayer(layer)
            }else{
                layerStack.newBackgroundLayer(layer)
            }
        }
        layerStack.bringSubview(toFront: remadeToolbar)
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
    
    //MARK: TextViewDelegates
    
    func textViewDidChange(_ textView: UITextView) {
        if let txv = textView as? UITextViewLayer{
            txv.resizeToText()
        }
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let layer = layerStack.getSelectedLayer().content as? UITextViewLayer
        if let txv = textView as? UITextViewLayer{
            if layer == txv{
                return true
            }
        }
        return false
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        
    }
    func setDoneOnKeyboard(_ textView: UITextViewLayer) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EditorViewController.dismissKeyboard))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        textView.inputAccessoryView = keyboardToolbar
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    
    //MARK:Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SaveImage"{
            if layerStack.layers.count > 0{
                if let destination = segue.destination as? RenderViewController{
                    //Gammel "Clear screen" code ligger i "done"-actionen
                    destination.delegate = self
                    destination.img = merge(layerStack)
                }
            }
        }
    }
    
    func mergeCompleted() {
        layerStack.mergeCompleted()
    }
 
    
}

extension UIImage {
    
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if ( self.imageOrientation == UIImageOrientation.up ) {
            return self;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        if ( self.imageOrientation == UIImageOrientation.down || self.imageOrientation == UIImageOrientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
        }
        
        if ( self.imageOrientation == UIImageOrientation.left || self.imageOrientation == UIImageOrientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
        }
        
        if ( self.imageOrientation == UIImageOrientation.right || self.imageOrientation == UIImageOrientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-M_PI_2));
        }
        
        if ( self.imageOrientation == UIImageOrientation.upMirrored || self.imageOrientation == UIImageOrientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( self.imageOrientation == UIImageOrientation.leftMirrored || self.imageOrientation == UIImageOrientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( self.imageOrientation == UIImageOrientation.left ||
            self.imageOrientation == UIImageOrientation.leftMirrored ||
            self.imageOrientation == UIImageOrientation.right ||
            self.imageOrientation == UIImageOrientation.rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
}
extension UIPinchGestureRecognizer {
    func scale(view: UIView) -> (x: CGFloat, y: CGFloat)? {
        if numberOfTouches > 1 {
            let touch1 = self.location(ofTouch: 0, in: view)
            let touch2 = self.location(ofTouch: 1, in: view)
            let deltaX = abs(touch1.x - touch2.x)
            let deltaY = abs(touch1.y - touch2.y)
            let sum = deltaX + deltaY
            if sum > 0 {
                let scale = self.scale
                return (1.0 + (scale - 1.0) * (deltaX / sum), 1.0 + (scale - 1.0) * (deltaY / sum))
            }
        }
        return nil
    }
}

extension UIBarButtonItem{
    func highlight(){
        let matrix = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: .curveEaseIn, animations: { () -> Void in
            //self.customView!.transform = matrix
        }, completion: { (finished: Bool) -> Void in
            
            print("Highlighted")
            
        })
        
    }
}
