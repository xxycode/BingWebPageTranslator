//
//  BingTranslator.swift
//  BingWebPageTranslator
//
//  Created by Xueyuan Xiao on 2022/10/9.
//

import Foundation

private struct BingTranslatorConstants {

    static let Endpoint = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0"

    // FIXME: - Fill your subscription key in azure
    static let SubscriptionKey = "<Fill your subscription key in azure>"

    // FIXME: - Fill your subscription region in azure
    static let SubscriptionRegion = "<Fill your subscription region in azure>"

}

class BingTranslator {

    static let xClientID = UUID().uuidString

    static func translate(_ text: [String], from: String, to: String, isHTML: Bool = false) async throws -> [String] {
        var urlString = "\(BingTranslatorConstants.Endpoint)&from=\(from)&to=\(to)"
        if isHTML {
            urlString += "&textType=html"
        }
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "com.bing.translate", code: -1)
        }

        var request = URLRequest(url: url)
        request.addValue(BingTranslatorConstants.SubscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.addValue(BingTranslatorConstants.SubscriptionRegion, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        request.addValue("application/json", forHTTPHeaderField: "Content-type")
        request.addValue(xClientID, forHTTPHeaderField: "X-ClientTraceId")
        request.httpMethod = "POST"

        let bodyArray = text.map {
            ["text": $0]
        }
        let bodyData = try JSONSerialization.data(withJSONObject: bodyArray, options: [])
        
        request.httpBody = bodyData
        let translateResult = try await URLSession.shared.data(for: request)
        let translateData = translateResult.0
        guard let translateJSON = try JSONSerialization.jsonObject(with: translateData) as? [[String: Any]] else {
            throw NSError(domain: "com.bing.translate", code: -2)
        }

        let result = translateJSON.reduce([String]()) {
            if let translations = $1["translations"] as? [[String: String]],
               let translation = translations.first,
               let text = translation["text"] {
                return $0 + [text]
            }
            return $0
        }
        return result
    }

}
