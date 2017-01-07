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
        layer?.totalScaleX *= sender.scale
        layer?.totalScaleY *= sender.scale
        
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
        //layer?.absOrigin.x += translation.x
        //layer?.absOrigin.y += translation.y
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
        layerStack.layers[0]?.transform = layerStack.backgroundTransform //overføring til den nye viewen
        layerStack.layers[0]?.totalScaleX = layerStack.backgroundTotalScaleX //(unødvendig uten transformen som også gjøres
        layerStack.layers[0]?.totalScaleY = layerStack.backgroundTotalScaleY //(unødvendig uten transformen som også gjøres
        layerStack.layers[0]?.totalRotation = layerStack.backgroundTotalRotation //(unødvendig uten transformen som også gjøres
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
        if layerStack.layers.count == 0{
            return merge
        }else if layerStack.layers.count == 1 {
            return layerStack.layers[0]!.image!
        }
        
        //klargjør konteksten:
        let contextElm = layerStack.layers[0]!
        let contextSize = contextElm.image!.size
        let contextOrigin = layerStack.convert(contextElm.bounds.origin, from: contextElm)  //CGPoint.zero // midlertidig (0,0) fordi layerstack også er superview til layers, så de er relative til hverandre allerede. skal egentlig være: contextElm.frame.origin
        //let contextScaleReference = contextElm.frame.size
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 1);
        let context = UIGraphicsGetCurrentContext()!
        
        //Behandler background layer
        layerStack.backgroundOrigin = contextOrigin //skal brukes på UIImageView når metoden er ferdig
        layerStack.backgroundTransform = contextElm.transform //skal brukes på UIImageView når metoden er ferdig
        layerStack.backgroundTotalScaleX = contextElm.totalScaleX //skal brukes på resterende layers
        layerStack.backgroundTotalScaleY = contextElm.totalScaleY //skal brukes på resterende layers
        layerStack.backgroundTotalRotation = contextElm.totalRotation //skal brukes på resterende layers
        
        print("\n backgroundTotalScaleX: \(layerStack.backgroundTotalScaleX)")
        print("backgroundTotalScaleY: \(layerStack.backgroundTotalScaleY)\n")
        
        let backgroundRect = CGRect(origin: CGPoint.zero, size: contextSize)
        let backgroundImage = contextElm.image!
        backgroundImage.draw(in: backgroundRect)
        
        //klargjør matriser og skaleringer
        var matrix = CGAffineTransform()
        var backgroundRescaleMatrix = CGAffineTransform()
        var rotationFlipBackMatrix = CGAffineTransform()
        let xScale = layerStack.backgroundTotalScaleX //contextSize.width/contextScaleReference.width
        let yScale = layerStack.backgroundTotalScaleY //contextSize.height/contextScaleReference.height
        
        //behandler resterende layers:
        for i in 1...(layerStack.count()-1){ //imageView: UIImageViewLayer! in layerStack.layers{
            
            let imageView = (layerStack.layers[i] as  UIImageViewLayer!)!
            let image = CIImage(image: imageView.image!)!
            
            //Finner center-plasseringen til det manipulerte bildet i forhold til context
            let backgroundRotationMatrix = CGAffineTransform.init(rotationAngle: layerStack.backgroundTotalRotation)
            let relativeCenterX = (imageView.center.x - contextOrigin.x)/xScale
            let relativeCenterY = (imageView.center.y - contextOrigin.y)/yScale
            var relCenter = CGPoint(x: relativeCenterX, y: relativeCenterY)
            relCenter = relCenter.applying(backgroundRotationMatrix)
            
            
            rotationFlipBackMatrix = CGAffineTransform.init(rotationAngle: imageView.totalRotation*2 - layerStack.backgroundTotalRotation) //NOTAT: transformen i imageview har motsatt koordinatsystem på rotasjonen, så den gjøres feil vei. Retter det opp med denne. Legger også til bakgrunnens rotasjon for å motvirke eventuelle rotasjoner gjort på den.
            backgroundRescaleMatrix = CGAffineTransform.init(scaleX: 1/xScale, y: 1/yScale) //NOTAT: skaleringen her skal være lik skaleringen som blir gjort på bakgrunnen når denne tegnes i konteksten og ikke blir tilført affine-avbildningen
            
                
            matrix = imageView.transform.concatenating(backgroundRescaleMatrix)
            matrix = matrix.concatenating(rotationFlipBackMatrix)

            let tempFilter = CIFilter(name: "CIAffineTransform",
                                          withInputParameters: [kCIInputImageKey: image, kCIInputTransformKey: matrix])
            let filterResult = UIImage(ciImage: ((tempFilter?.outputImage)! as CIImage))
            
            //Prepare for draw to context:
            let drawOrigin = CGPoint(x: (relCenter.x - filterResult.size.width*0.5), y: (relCenter.y - filterResult.size.height*0.5))
            let drawingRect : CGRect = CGRect(origin: drawOrigin, size: filterResult.size)
            
            //Draw to context:
            filterResult.draw(in: drawingRect)

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
        if var pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            pickedImage = pickedImage.fixOrientation()
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
