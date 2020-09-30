//
//  JsONRequestSerializer.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public struct JSONRequestSerializer: RequestSerializer {

    public func serialize(_ object: Any) throws -> Data {
        
        if !JSONSerialization.isValidJSONObject(object) {
            throw NSError(domain: "JsONSerialization", code: -1, userInfo: [NSLocalizedDescriptionKey: "Will not produce a valid JsON object | \(object)."])
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
            return jsonData
        } catch let error {
            throw error
        }
    }
}
