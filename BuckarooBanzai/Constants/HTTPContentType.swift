//
//  HTTPContentType.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public enum HTTPContentType {
    case XML
    case JSON
    case FORM
    case CUSTOM(String)
    
    public func string() -> String {
        switch self {
        case .XML: return "application/xml"
        case .JSON: return "application/json"
        case .FORM: return "application/x-www-form-urlencoded"
        case .CUSTOM(let customType): return customType
        }
    }
}
