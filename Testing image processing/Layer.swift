//
//  Layer.swift
//  Testing image processing
//
//  Created by Simen E. Sørensen on 10/01/17.
//  Copyright © 2017 Simen E. Sørensen. All rights reserved.
//

import UIKit

class Layer{
    
    private var textfield: UITextView? = UITextView()
    private var imageview: UIImageViewLayer? = UIImageViewLayer()
    private var firstAccess = true
    
    
    public var image: UIImage?{
        if firstAccess{
            imageview?.isHidden = false
            textfield?.isHidden = true
        }
        if textfield?.isHidden{
            return imageview?.image
        }
    }
    
    public var text: String?{
        if firstAccess{
            imageview?.isHidden = true
            textfield?.isHidden = false
        }
        if imageview.isHidden{
            return textfield?.text
        }
    }
    
    
}
