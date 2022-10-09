//
//  ViewController.swift
//  BingWebPageTranslator
//
//  Created by Xueyuan Xiao on 2022/10/9.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let path = Bundle.main.path(forResource: "mozilla_translate", ofType: "js"),
           let str = try? String(contentsOfFile: path, encoding: .utf8) {
            webView.configuration.userContentController.addUserScript(WKUserScript(source: str, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .defaultClient))
        }
        webView.configuration.userContentController.add(self, contentWorld: .defaultClient, name: "translationHandler")
        webView.load(URLRequest(url: URL(string: "https://www.qq.com")!))
    }

    @IBAction func trAct(_ sender: Any) {
        let script = """
        window.translator.addElement(document.body);
        window.translator.start('en');
        """
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "translationHandler" {
            if let translationPayload = message.body as? [String: Any],
               let attrid = translationPayload["attrId"] as? [Int],
               let text = translationPayload["text"] as? String {
                print(translationPayload)
                Task {
                    do {
                        let res = try await BingTranslator.translate([text], from: "zh-Hans", to: "en", isHTML: true)
                        if let resText = res.first {
                            let script = """
                            window.translator.mediatorNotification({
                                'attrId': [\(attrid.first!)],
                                'translatedParagraph': '\(escapeJSONString(resText))'
                            });
                            """
                            webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
                                switch result {
                                    case .success(_):
                                        print("evaluateJavaScript success")
                                    case .failure(let error):
                                        print("evaluateJavaScript error: \(error)")
                                }
                            }
                        }
                    } catch {
                        print("error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

}

extension ViewController {
    private func escapeJSONString(_ str: String) -> String {
        var chars = ""
        for c in str {
            switch c {
                case "\n":
                    chars.append("\\n")
                case "\r":
                    chars.append("\\r")
                case "\t":
                    chars.append("\\t")
                case "\\":
                    chars.append("\\\\")
                case "/" :
                    chars.append("\\/")
                case "\"":
                    chars.append("\\\"")
                case "<":
                    chars.append("\\u003C")
                case "'":
                    chars.append("&#x27;")
                default:
                    chars.append(c)
            }
        }
        return String(chars)
    }
}

