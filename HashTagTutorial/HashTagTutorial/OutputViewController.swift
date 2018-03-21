//
//  OutputViewController.swift
//  HashTagExample
//
//  Created by JerryWang on 2018/3/20.
//  Copyright © 2018年 Jerrywang. All rights reserved.
//

import UIKit

class OutputViewController: UIViewController {

    @IBOutlet weak var outputHashTagView: HashTagView!
    var attrNSString : NSMutableAttributedString?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputHashTagView.outputDelegate = self
        outputHashTagView._attrNSString = attrNSString
    }
}

extension OutputViewController: OutputHashTagViewProtocol {
    func passSelectedtag(of string: String, type: TagType) {
        switch type {
        case .hashTag:
            print("show hashtag screen")
            navigationItem.title = string
        case .mention:
            print("show mention screen")
            navigationItem.title = string
        }
    }
}
