//
//  RenderViewController.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 08/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class RenderViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var canvasUIView: UIView!
    
    //MARK: Properties
    var img: UIImage = UIImage()
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
        
        let imv = UIImageViewLayer(image: img)
        imv.scaleCenterAndSetParent(to: canvasUIView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        returnToEditor()
    }

    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        if let png = UIImagePNGRepresentation(img){
            let activity = UIActivityViewController(activityItems: [png], applicationActivities: nil)
            activity.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
                if completed == true{
                    if activityType == UIActivityType.saveToCameraRoll{
                        print("Image Saved")
                    }
                }else{
                    print("ERROR! Image not saved")
                }
                self.returnToEditor()
            }

            present(activity, animated: true, completion: nil)
        }
    }
    
    
    
    func returnToEditor(){
        guard (navigationController?.popViewController(animated:true)) != nil
            else {
                print("No Navigation Controller")
                dismiss(animated: true, completion: nil)
                return
        }
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let editorScene = segue.destination as! EditorViewController
        editorScene.layerStack.mergeCompleted()
        
    }
    

}
