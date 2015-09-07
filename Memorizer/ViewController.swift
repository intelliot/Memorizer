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
    
    enum ControllerState {
        case InitialTextEntry
        case InvisibleLetters
    }
    
    var state = ControllerState.InitialTextEntry
    
    let debugEnabled = true
    let shouldJumpToBlank = true
    
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

    @IBAction func doneTapped(sender: UIBarButtonItem) {
        state = .InvisibleLetters
        textView.autocorrectionType = UITextAutocorrectionType.No
        navigationItem.rightBarButtonItem = nil;
        //textView.resignFirstResponder()
        
        UIView.transitionWithView(textView, duration: 1, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            let visibleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(14)]
            let invisibleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(14),
                NSForegroundColorAttributeName: UIColor.whiteColor()]
            
            let attributedString = NSMutableAttributedString()
            
            var firstInvisibleLetterPosition = NSMakeRange(0, 0)
            var isFirstLetter = true
            for letter in self.textView.text.characters {
                if (letter == " " || letter == "\n") {
                    isFirstLetter = true
                    attributedString.appendAttributedString(NSAttributedString(string: "\(letter)", attributes: visibleAttributes))
                    continue
                }
                if (isFirstLetter || letter == "'" || letter == ",") {
                    attributedString.appendAttributedString(NSAttributedString(string: "\(letter)", attributes: visibleAttributes))
                    isFirstLetter = false
                } else {
                    if (NSEqualRanges(firstInvisibleLetterPosition, NSMakeRange(0, 0))) {
                        firstInvisibleLetterPosition = NSMakeRange(attributedString.length, 0)
                    }
                    attributedString.appendAttributedString(NSAttributedString(string: "\(letter)", attributes:invisibleAttributes))
                }
            }
            
            self.textView.attributedText = attributedString
            
            self.textView.becomeFirstResponder()
            
            self.textView.selectedRange = firstInvisibleLetterPosition
            
            }, completion: nil)
    }
    
    func isInvisible(textView: UITextView, range: Range<String.Index>) -> Bool {
        let attributes = textView.attributedText.attributesAtIndex(textView.text.nsRangeFromRange(range).location, effectiveRange: nil)
        if attributes[NSForegroundColorAttributeName] as? UIColor == UIColor.whiteColor() {
            return true
        }
        return false
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if state == .InitialTextEntry {
            return true
        }
        
        if text == "" {
            debug("Backspace detected and ignored")
            return false
        }
        
        // Simulate `insert` behavior by creating a range with `length` equal to `text` length
        var rangeToOverwrite = NSMakeRange(range.location, text.characters.count)
        
        if var swiftRange = textView.text.rangeFromNSRange(rangeToOverwrite) {
            repeat {
                if text == textView.text.substringWithRange(swiftRange) {
                    var requestedRange = textView.text.nsRangeFromRange(swiftRange) // Base requestedRange on the current swiftRange
                    requestedRange.length = range.length // ... But set its length to the one this function was originally called with
                    
                    // Remove invisible letter
                    let mutableAttributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
                    mutableAttributedString.mutableString.replaceCharactersInRange(rangeToOverwrite, withString: "") // Delete this area of the String
                    
                    // Typically, add this text (requestedRange.length == 0)
                    mutableAttributedString.mutableString.replaceCharactersInRange(requestedRange, withString: text)
                    
                    textView.attributedText = mutableAttributedString
                    
                    var cursorLocation: UITextPosition?
                    
                    if shouldJumpToBlank {
                        // Find next visible letter
                        
                        repeat {
                            // Advance swiftRange by a letter
                            swiftRange = textView.text.rangeOfComposedCharacterSequenceAtIndex(swiftRange.startIndex.advancedBy(1))
                            
                            // If we're at a space or *visible* letter, keep advancing
                        } while " " == textView.text.substringWithRange(swiftRange) || isInvisible(textView, range: swiftRange) == false
                        
                        cursorLocation = textView.positionFromPosition(textView.beginningOfDocument, offset: textView.text.nsRangeFromRange(swiftRange).location)
                        
                    } else {
                        // Don't jump to blank
                        cursorLocation = textView.positionFromPosition(textView.beginningOfDocument, offset: (requestedRange.location + text.characters.count))
                    }
                    
                    if let cursorLocation = cursorLocation {
                        textView.selectedTextRange = textView.textRangeFromPosition(cursorLocation, toPosition: cursorLocation)
                    }
                    return false
                }
                
                // Allow for matching the next non-space invisible letter
                if " " == textView.text.substringWithRange(swiftRange) || isInvisible(textView, range: swiftRange) == false {
                    
                    // Advance swiftRange by a letter
                    swiftRange = textView.text.rangeOfComposedCharacterSequenceAtIndex(swiftRange.startIndex.advancedBy(1))
                    
                    // Update rangeToOverwrite for subsequent loop
                    rangeToOverwrite = textView.text.nsRangeFromRange(swiftRange)
                    
                } else {
                    // No match. We could notify the user here
                    return false
                }
            } while true
        }
        
        // Should never reach this point
        return false
    }
    
    func debug(string: String) {
        if (debugEnabled) {
            print(string)
        }
    }
}

extension String {
    func rangeFromNSRange(nsRange: NSRange) -> Range<String.Index>? {
        let startUtf16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let endUtf16 = startUtf16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let startIndex = String.Index(startUtf16, within: self),
            let endIndex = String.Index(endUtf16, within: self) {
                return startIndex ..< endIndex
        }
        return nil
    }
    
    func nsRangeFromRange(range: Range<String.Index>) -> NSRange {
        let prefix = substringToIndex(range.startIndex)
        let substring = substringWithRange(range)
        return NSRange(location: prefix.utf16.count, length: substring.utf16.count)
    }
}
