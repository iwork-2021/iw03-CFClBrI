//
//  ViewController.swift
//  ITSC
//
//  Created by Chun on 2021/10/19.
//

import UIKit
import WebKit
import SwiftSoup

class AboutViewController: UIViewController {

    @IBOutlet weak var contentWebView: WKWebView!
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    } ()
    
    private var receivedData: Data = Data()
    
    private func fetchData() {
        let url = URL(string: "https://itsc.nju.edu.cn/main.htm")!
        let task = self.session.dataTask(with: url)
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.fetchData()
    }


}

extension AboutViewController: URLSessionDataDelegate {
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
                    let footer: Element = try doc.select("[id=footer]").first()!
                    self.contentWebView.loadHTMLString(try footer.html(), baseURL: nil)
                }
                catch {
                    print("Html Parse Error")
                }
                
            }
        }
    }
}
