//
//  NoticeTableViewController.swift
//  ITSC
//
//  Created by nju on 2021/11/13.
//

import UIKit
import Foundation

class NoticeTableViewController: UITableViewController {

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    } ()
    
    private var receivedData: Data = Data()
    private var titles: [String] = []
    private var times: [String] = []
    private var links: [String] = []

    private func fetchData() {
        let url = URL(string: "https://itsc.nju.edu.cn/tzgg/list.htm")!
        let task = self.session.dataTask(with: url)
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.fetchData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 30
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell", for: indexPath) as! TableViewCell

        // Configure the cell...
        if self.titles.count == 14 && self.times.count == 14 {
            cell.title.text = self.titles[indexPath.row % 14]
            cell.time.text = self.times[indexPath.row % 14]
        } else {
            cell.title.text = "loading..."
            cell.time.text = ""
        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "noticeContent" {
            let contentViewController = segue.destination as! ContentViewController
            let cell = sender as! TableViewCell
            let row: Int = self.tableView.indexPath(for: cell)!.row
            contentViewController.link = self.links[row % 14]
        }
    }
    

}

extension NoticeTableViewController: URLSessionDataDelegate {
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
                let pattern: String = "href=.+\\s+target=.+\\s+title=.+\\s+<span class=\"news_meta\">.+<\\/span>"
                do {
                    let regex: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                    let matches: [NSTextCheckingResult] = regex.matches(in: string, options: .init(rawValue: 0), range: NSMakeRange(0, string.count))
                    let nsString: NSString = string as NSString
                    for match in matches {
                        let matchRange: NSRange = match.range
                        let regResString: NSString = nsString.substring(with: matchRange) as NSString
                        let linkBegin: Int = regResString.range(of: "href=").upperBound + 1
                        let linkEnd: Int = regResString.range(of: ".htm").upperBound - 1
                        let link: String = "https://itsc.nju.edu.cn" + regResString.substring(with: NSMakeRange(linkBegin, linkEnd - linkBegin + 1))
                        self.links.append(link)
                        let titleBegin: Int = regResString.range(of: "title=").upperBound + 1
                        let titleEnd: Int = regResString.range(of: "'>").lowerBound - 1
                        let title: String = regResString.substring(with: NSMakeRange(titleBegin, titleEnd - titleBegin + 1))
                        self.titles.append(title)
                        let timePos: Int = regResString.range(of: "-").lowerBound - 4
                        let time: String = regResString.substring(with: NSMakeRange(timePos, 10))
                        self.times.append(time)
                    }
                    self.tableView.reloadData()
                }
                catch {
                    print("RegexExpression Error")
                    return
                }
                
            }
        }
    }
    
}
