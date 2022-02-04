//
//  Error+Extension.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 2/4/22.
//

import Foundation

extension Error {
    public func httpResponse() -> HTTPResponse? {
        if let response = (self as NSError).userInfo[BuckarooBanzai.BBHTTPResponseErrorKey] as? HTTPResponse {
            return response
        }
        
        return nil
    }
    
    public func httpStatusCode() -> Int? {
        if let statusCode = (self as NSError).userInfo[BuckarooBanzai.BBHTTPStatusCodeErrorKey] as? Int {
            return statusCode
        }
        
        return nil
    }
}
