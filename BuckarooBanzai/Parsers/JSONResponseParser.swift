//
//  JSONResponseParser.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/25/20.
//

import Foundation

public struct JSONResponseParser: ResponseParser {
    public func parse(_ data: Data) throws -> Any {
        do {
            let responseBody = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return responseBody
        } catch let error {
            throw error
        }
    }
}
