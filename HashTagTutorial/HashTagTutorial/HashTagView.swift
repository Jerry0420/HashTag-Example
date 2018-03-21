//
//  HashTagView.swift
//  HashTagExample
//
//  Created by JerryWang on 2018/3/20.
//  Copyright © 2018年 Jerrywang. All rights reserved.
//

import UIKit

///Two tag types, hashtag and mention friend
enum TagType: Character {
    case hashTag = "#"
    case mention = "@"
}

///For InputVC implementation
protocol InputHashTagViewProtocol: class {
    ///Send Out current word for inputVC trainsition to outputVC
    func setUpAttributeString(of string: NSMutableAttributedString)
    ///For dynamic search tag and show fetched data on the tableview
    func passLastWord(of string: String, type: TagType)
}

///For OutputVC implementation
protocol OutputHashTagViewProtocol: class {
    ///when user tap on the tag or the mention friend, trainsition to the tag's page or the mention friend's page.
    func passSelectedtag(of string: String, type: TagType)
}

//@IBDesignable
class HashTagView: UIView {
    ///True: for inputVC.
    ///False: for outputVC
    @IBInspectable var editable: Bool = true {
        didSet { hashTagTextView.isEditable = editable }
    }
    ///Set the portion between textview and tableview
    ///inputVC: 0 ~ 1, outputVC: 1
    @IBInspectable var portion: CGFloat = 0.4
    ///Set textview's textcolor.
    private var textcolor: UIColor = UIColor.black
    ///Set tag's color.
    private var tagcolor: UIColor = UIColor.cyan
    fileprivate var textViewFont: UIFont = UIFont(name: "Helvetica", size: 20)!
    ///Set textview's fontsize
    @IBInspectable var textfontsize: CGFloat = 20 {
        didSet {
            textViewFont = UIFont.systemFont(ofSize: textfontsize)
            hashTagTextView.font = textViewFont
        }
    }
    ///Pass in the attributeString to show on the outputVC
    var _attrNSString: NSMutableAttributedString? {
        didSet {
            guard let length = _attrNSString?.length else { return }
            //為了可在storyboard變更字體大小，故加入前2行
            let range = NSRange(location: 0, length: length)
            _attrNSString?.addAttribute(NSAttributedStringKey.font, value: textViewFont, range: range)
            //outputVC時，改變tag顏色
            hashTagTextView.attributedText = _attrNSString
        }
    }
    
    ///Current searched tags
    var tags = [String](){
        didSet{ DispatchQueue.main.async { self.tableView?.reloadData() } }
    }
    
    weak var inputDelegate: InputHashTagViewProtocol?
    weak var outputDelegate: OutputHashTagViewProtocol?
    
    fileprivate var hashTagTextView = UITextView(frame: CGRect.zero)
    fileprivate var tableView: UITableView?
    fileprivate var textNSString: NSString = ""
    fileprivate var attrNSString: NSMutableAttributedString = NSMutableAttributedString(string: "")
    fileprivate var lastHashTagRange = NSMakeRange(0, 0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpHashTagTextView()
        if editable{ setUpTableView() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpHashTagTextView()
        if editable{ setUpTableView() }
    }
    
    fileprivate func setUpHashTagTextView() {
        hashTagTextView.delegate = self
        hashTagTextView.textColor = textcolor
        hashTagTextView.keyboardType = .twitter
        hashTagTextView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: tagcolor]
        addSubview(hashTagTextView)
    }
    
    fileprivate func setUpTableView() {
        tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
        guard let tableView = tableView else { fatalError("tableView initialize fail") }
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isUserInteractionEnabled = true
        addSubview(tableView)
    }
    
    override func layoutSubviews() {
        let vieSize = bounds.size
        hashTagTextView.frame = CGRect(x: 0, y: 0, width: vieSize.width, height: vieSize.height * portion)
        tableView?.frame = CGRect(x: 0, y: vieSize.height * portion, width: vieSize.width, height: vieSize.height * (1 - portion))
    }
    
    fileprivate func setText(of text: String) {
        
        attrNSString = NSMutableAttributedString(string: text)
        textNSString = NSString(string: text)
        
        let range = NSRange(location: 0, length: textNSString.length)
        
        attrNSString.addAttribute(NSAttributedStringKey.font, value: textViewFont, range: range)
        attrNSString.addAttribute(NSAttributedStringKey.foregroundColor, value: textcolor, range: range)
        splitText(of: textNSString)
    }
    
    private func splitText(of text: NSString) {
        //從空白和換行，把目前textview的字切成一個string array，分別判斷
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        guard let lastWord = words.last else { return }
        
        //判斷最後一個詞的第一個字是否為# or @，若為tag，則發請求更新tableview
        switch Array(lastWord).first {
        case nil:
            tableView?.isHidden = true
        case (TagType.mention.rawValue)?, (TagType.hashTag.rawValue)?:
            tableView?.isHidden = false
            inputDelegate?.passLastWord(of: lastWord, type: TagType(rawValue: Array(lastWord).first!)!)
        default:
            break
        }
        
        words.forEach {
            if $0.hasPrefix("\(TagType.hashTag.rawValue)") || $0.hasPrefix("\(TagType.mention.rawValue)") { setAttribute(of: $0) }
        }
    }
    
    
    private func setAttribute(of word: String){
        //要取字串長度，使用NSString的length，不要使用String的count(因為在emoji時會有差別，長度不同)
        //將search range依照found range從全部慢慢限縮
        //found range 找出目前的word所在的位置
        //未直接將word設定AttributedString的原因為，若同樣的tag輸入超過1次，除了第1個tag之外，其餘的會無法偵測到。
        //previousCharacterRange判斷found range的前一個字為何，避免#hihi#hihi or #hi@wang... 等#@混用的情況，第157行 range到的word為於單詞中間，造成attribute加錯位置。
        let fullStringLength = textNSString.length
        var searchRange = NSMakeRange(0, fullStringLength)
        while searchRange.location < fullStringLength {
            searchRange.length = fullStringLength - searchRange.location
            let foundRange = textNSString.range(of: word, options: .caseInsensitive, range: searchRange)
            guard foundRange.location != NSNotFound else { break }
            searchRange.location = foundRange.location + (word as NSString).length + 1
            let previousCharacterRange = NSMakeRange(foundRange.location - 1, 1)
            let previousCharacter = (previousCharacterRange.location >= 0) ? (textNSString.substring(with: previousCharacterRange)) : ("")
            
            if  previousCharacter == "" || previousCharacter == "\0" || previousCharacter == " " || previousCharacter == "\n" {

                let result = textNSString.substring(with: foundRange)
                //result.remove(at: result.startIndex)
                lastHashTagRange = foundRange
                guard let encodedInputString = result.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
                
                attrNSString.addAttribute(NSAttributedStringKey.link, value: "\(encodedInputString)", range: foundRange)
                //在inputVC時就改變tag顏色
//                hashTagTextView.attributedText = attrNSString
            }
        }
    }
}

extension HashTagView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        //清空目前所有字的時候，變更lastHashTagRange
        if textView.text == "" { lastHashTagRange = NSMakeRange(0, 0) }
        setText(of: textView.text) //在打字的時候，生出正確的atrrString
        inputDelegate?.setUpAttributeString(of: attrNSString)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        //點下即可秀出相對應的頁面
        guard let encodedInputString = URL.absoluteString.removingPercentEncoding else { return false }
        switch Array(encodedInputString)[0] {
        case (TagType.mention.rawValue), (TagType.hashTag.rawValue):
            outputDelegate?.passSelectedtag(of: encodedInputString, type: TagType(rawValue: Array(encodedInputString)[0])!)
        default:
            break
        }
        
        return false
    }
}

extension HashTagView: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = tags[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Helvetica", size: 20)
        
        return cell
    }
}

extension HashTagView : UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //自動加一個空格，方便tag斷句
        //true部分，處理當textview一開始就輸入tag時
        let textString = (lastHashTagRange == NSMakeRange(0, 0)) ? (tags[indexPath.row] + " ") : (textNSString.replacingCharacters(in: lastHashTagRange, with: (tags[indexPath.row] + " ")))
        hashTagTextView.text = textString
        setText(of: textString)
        inputDelegate?.setUpAttributeString(of: attrNSString)
    }
}

