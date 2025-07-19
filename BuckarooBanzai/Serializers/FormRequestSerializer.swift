//
//  FormRequestSerializer.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/29/20.
//

import Foundation

struct FormRequestSerializer: RequestSerializer {
    
    private static let customCharacterSet: CharacterSet = {
        var charSet = NSCharacterSet.urlQueryAllowed
        let remove = "+&"
        for char in remove.unicodeScalars {
            charSet.remove(char)
        }
        
        return charSet
    }()
    
    func serialize(_ object: Any) throws -> Data {
        
        guard let params = object as? [String: Any] else {
            throw BBError.serializer([NSLocalizedDescriptionKey: "Params should be in a one-level Dictionary<String,Any>"])
        }

        var components = URLComponents()
        components.queryItems = params.map { key, value in
            URLQueryItem(name: key, value: String(describing: value))
        }
        
        guard let query = components.query else {
            throw BBError.serializer([NSLocalizedDescriptionKey: "Could not create URL query from parameters."])
        }
        
        guard let formData = query.data(using: .utf8) else {
            throw BBError.serializer([NSLocalizedDescriptionKey: "Could not convert query string to Data."])
        }
        
        return formData
    }
    
    private func urlEncode(_ string: String) -> String {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: Self.customCharacterSet) else {
            return string
        }
        
        return encoded
    }
}
