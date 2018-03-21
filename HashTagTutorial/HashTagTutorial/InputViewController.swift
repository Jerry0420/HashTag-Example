//
//  InputViewController.swift
//  HashTagExample
//
//  Created by JerryWang on 2018/3/20.
//  Copyright © 2018年 Jerrywang. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {

    @IBOutlet weak var inputHashTagView: HashTagView!
    var attrNSString : NSMutableAttributedString?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputHashTagView.inputDelegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHashTag"{
            if let outputVC = segue.destination as? OutputViewController{
                outputVC.attrNSString = attrNSString
            }
        }
    }
}

extension InputViewController: InputHashTagViewProtocol {
    func setUpAttributeString(of string: NSMutableAttributedString) {
        attrNSString = string
    }
    
    func passLastWord(of string: String, type: TagType) {
        //用string做網路請求，接著更新tableview
        //依據不同的tagtype發不同的請求 ex請求hashtag or 請求friends
        switch type {
        case .hashTag:
            inputHashTagView.tags = ["#hello","#你好🏠","#hello👋","#嗨嗨","#hello","#你好🏠","#hello👋","#嗨嗨"]
            inputHashTagView.tags.insert(string, at: 0)
        case .mention:
            inputHashTagView.tags = ["@hello","@你好🏠","@hello👋","@嗨嗨","@hello","@你好🏠","@hello👋","@嗨嗨"]
            inputHashTagView.tags.insert(string, at: 0)
        }
    }
}
