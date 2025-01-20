//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//
import Foundation

class TranslatorUtil {

    static let subscriptionKey = "9Djf2ajySE5eIydDZ2cbxJA3GXHo2pg7FgsJOVqGnazGGb4W3G5HJQQJ99ALACULyCpXJ3w3AAAbACOGPGX2"
    
    static func translate(inputText: String, fromLocale: String, toLocale: String) async -> String {
        
        do {
            
            
            let url = URL(string: "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&from=\(fromLocale)&to=\(toLocale)")

            //create a new urlRequest passing the url
            var request = URLRequest(url: url!)
            request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let inputJson = "[{\"Text\": \"\(inputText)\"}]"
            request.httpBody = inputJson.data(using: .utf8)
            
            //run the request and retrieve both the data and the response of the call
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let JSONObject = try? JSONSerialization.jsonObject(with: data)
            let level1 = JSONObject as? [[String: Any]]
            let level2 = level1?[0] as? [String: Any]
            let level3 = level2?["translations"] as? [Any]
            let level4 = level3?.first as? [String: Any]
            let outputText = level4?["text"] as? String
            

            return outputText ?? ""
            
        } catch {
            print(error)
            return error.localizedDescription
        }


    }
}
