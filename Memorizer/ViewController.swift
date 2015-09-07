//
//  ViewController.swift
//  Memorizer
//
//  Created by E on 9/6/15.
//  Copyright © 2015 Tiny Terabyte. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardRectValue = notification.userInfo![UIKeyboardFrameEndUserInfoKey]!
        
        var keyboardRect = CGRectZero
        keyboardRectValue.getValue(&keyboardRect)
        
        textView.contentInset = UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0)
        textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        textView.contentInset = UIEdgeInsetsZero
        textView.scrollIndicatorInsets = UIEdgeInsetsZero
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

