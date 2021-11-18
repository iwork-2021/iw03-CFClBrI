//
//  ContentViewController.swift
//  ITSC
//
//  Created by nju on 2021/11/12.
//

import UIKit
import Foundation
import SwiftSoup

class ContentViewController: UIViewController {
    
    @IBOutlet weak var contentTitle: UILabel!
    @IBOutlet weak var contentImage: UIImageView!
    @IBOutlet weak var contentTextFirst: UITextView!
    @IBOutlet weak var contentTextSecond: UITextView!
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    } ()
    
    var link: String = ""
    private var receivedData: Data = Data()
    
    private func fetchData() {
        let task = self.session.dataTask(with: URL(string: self.link)!)
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.fetchData()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ContentViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              let mimeType = response.mimeType,
              mimeType == "text/html" else {
                  completionHandler(URLSession.ResponseDisposition.cancel)
                  return
              }
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                let string: String = String(data: self.receivedData, encoding: String.Encoding.utf8)!
                do {
                    let doc: Document = try SwiftSoup.parse(string)
                    //set title
                    let titleText: Element = try doc.select("[class=arti_title]").first()!
                    self.contentTitle.text = try titleText.text()
                    //set main text
                    let mainTexts: Element = try doc.select("[class=wp_articlecontent]").first()!
                    let mainTextArray: [Element] = mainTexts.children().array()
                    var resTexts: [String] = []
                    for mainText: Element in mainTextArray {
                        let t = try mainText.text()
                        if t != "" {
                            resTexts.append(t)
                        }
                    }
                    self.contentTextFirst.text = resTexts[0]
                    if resTexts.count > 1 {
                        self.contentTextSecond.text = resTexts[1]
                    }
                    else {
                        self.contentTextSecond.text = ""
                    }
                    //set picture
                    let pictures: Elements = try doc.select("img[src]")
                    let pictureLinks: [String] = try pictures.array().map {
                        try $0.attr("src").description
                    }
                    for pictureLink: String in pictureLinks {
                        if (pictureLink.range(of: "article/images") != nil) {
                            let data: Data = try Data(contentsOf: URL(string: "https://itsc.nju.edu.cn" + pictureLink)!)
                            self.contentImage.image = UIImage(data: data)
                            break
                        }
                    }
                    
                }
                catch {
                    print("Html Parse Error")
                }
                
            }
        }
    }
}
