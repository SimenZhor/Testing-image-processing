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

class EditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, RenderDelegate {
    
    @IBOutlet var pan: UIPanGestureRecognizer!
    @IBOutlet var zoom: UIPinchGestureRecognizer!
    @IBOutlet var rotate: UIRotationGestureRecognizer!
    @IBOutlet weak var newLayerButton: UIBarButtonItem!
    @IBOutlet weak var nextLayerButton: UIBarButtonItem!
    @IBOutlet weak var prevLayerButton: UIBarButtonItem!
    @IBOutlet weak var layerStack: LayerStackUIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    
    let imagePicker = UIImagePickerController()
    var bg: UIImage!
    var overlay: UIImage!
    var merge: UIImage!
    var tempoverlay: UIImage!
    var currentLayer = 0
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        self.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zoom.isEnabled = true
        imagePicker.delegate = self
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
        layerStack.layers[currentLayer].scale(xScale: sender.scale, yScale: sender.scale, border: true)
        
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
        let layer = layerStack.layers[currentLayer]
        let translation = sender.translation(in: self.view)
        layer.center = CGPoint(x:layer.center.x + translation.x,
                                y:layer.center.y + translation.y)
        //layer?.absOrigin.x += translation.x
        //layer?.absOrigin.y += translation.y
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @IBAction func newLayer(_ sender: UIBarButtonItem) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
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
    
    @IBAction func newTextLayer(_ sender: UIButton) {
    
    }
    
    func linkLayers(indexlist: [Int]){
    
    }

    func deleteLayer(index: Int){
        
    }
    
    
    //MARK: Image Processing
    
    func merge(_ layerStack: LayerStackUIView) -> UIImage{
        //prepare each layer:
        var merge: UIImage!
        layerStack.prepareForMerge()
        
        //klargjør konteksten:
        let contextElm = layerStack.layers[0]
        let contextSize = contextElm.image!.size
        let contextOrigin = layerStack.convert(contextElm.bounds.origin, from: contextElm)
        
        //Behandler background layer
        layerStack.backgroundOrigin = contextOrigin //skal brukes på UIImageView når metoden er ferdig
        layerStack.backgroundTransform = contextElm.transform //skal brukes på UIImageView når metoden er ferdig
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
        let backgroundImage = contextElm.image!
        backgroundImage.draw(in: backgroundRect)
        
        
        //klargjør matriser og skaleringer
        var matrix = CGAffineTransform()
        var backgroundRotationMatrix = CGAffineTransform()
        var backgroundRescaleMatrix = CGAffineTransform()
        var ownScaleMatrix = CGAffineTransform()
        var ownRotationMatrix = CGAffineTransform()
        let xScale = layerStack.backgroundTotalScaleX
        let yScale = layerStack.backgroundTotalScaleY
        
        //behandler resterende layers:
        for i in 1...(layerStack.count-1){ //imageView: UIImageViewLayer! in layerStack.layers{
            context.saveGState()
            
            let layer = (layerStack.layers[i] as  UIImageViewLayer!)!
            let image = layer.image!
            
            //Finner center-plasseringen til det manipulerte bildet i forhold til context
            backgroundRotationMatrix = CGAffineTransform.init(rotationAngle: -layerStack.backgroundTotalRotation)
            let relativeCenterX = (layer.center.x - contextOrigin.x)/xScale
            let relativeCenterY = (layer.center.y - contextOrigin.y)/yScale
            var relCenter = CGPoint(x: relativeCenterX, y: relativeCenterY)
            relCenter = relCenter.applying(backgroundRotationMatrix)
            
            if (layer.totalScaleY/yScale) > 1 || (layer.totalScaleX/xScale > 1){
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
            }
            
            ownScaleMatrix = CGAffineTransform.init(scaleX: layer.totalScaleX, y: layer.totalScaleY)
            ownRotationMatrix = CGAffineTransform.init(rotationAngle: layer.totalRotation)
            backgroundRotationMatrix = CGAffineTransform.init(rotationAngle: -layerStack.backgroundTotalRotation)
            backgroundRescaleMatrix = CGAffineTransform.init(scaleX: 1/xScale, y: 1/yScale) //NOTAT: skaleringen her skal være lik skaleringen som blir gjort på bakgrunnen når denne tegnes i konteksten og ikke blir tilført affine-avbildningen
            
            matrix = backgroundRescaleMatrix.concatenating(ownScaleMatrix)
            print("\n\nSkaleringsmatrise layer\(i):\n\(matrix)\n\n")
            matrix = matrix.concatenating(ownRotationMatrix)
            matrix = matrix.concatenating(backgroundRotationMatrix)
            
            context.translateBy(x: relCenter.x, y: relCenter.y)
            context.concatenate(matrix)
            context.translateBy(x: -relCenter.x, y: -relCenter.y)
            let filterResult = layer.bounds
            //Prepare for draw to context:
            let drawOrigin = CGPoint(x: (relCenter.x - filterResult.size.width*0.5), y: (relCenter.y - filterResult.size.height*0.5))
            let drawingRect : CGRect = CGRect(origin: drawOrigin, size: filterResult.size)
            
            //Draw to context:
            image.draw(in: drawingRect)
            
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
            let imv = UIImageViewLayer(image: pickedImage)
            imv.contentMode = .scaleAspectFit
            if(layerStack.count > 0){
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
