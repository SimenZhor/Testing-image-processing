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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
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
        guard (navigationController?.popViewController(animated:true)) != nil
            else {
                print("No Navigation Controller")
                dismiss(animated: true, completion: nil)
                return
        }
    }

    @IBAction func saveAction(_ sender: UIBarButtonItem) {
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let editorScene = segue.destination as! EditorViewController
        //endre variabler i editorScene hvis nødvendig
        
    }
    

}
