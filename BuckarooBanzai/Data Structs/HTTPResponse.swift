//
//  HTTPResponse.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/25/20.
//

import Foundation
import UIKit

public struct HTTPResponse {
    
    public init(statusCode: Int, headers: [AnyHashable: Any], body: Data? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
    
    public var statusCode: Int
    public var headers: [AnyHashable: Any]
    public var body: Data?

    public func decodeBodyData<T: Decodable>() throws -> T {
        guard let data = body else {
            throw NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "No body data found."])
        }
        let decoder = JSONDecoder()
        let object = try decoder.decode(T.self, from: data)
        return object
    }
    
    public func decodeBodyDataAsImage() throws -> UIImage {
        guard let data = body else {
            throw BuckarooBanzai.createErrorWithUserInfo([NSLocalizedDescriptionKey: "No body data found."])
        }
        guard let image = UIImage(data: data) else {
            throw BuckarooBanzai.createErrorWithUserInfo([NSLocalizedDescriptionKey: "Could not create image from data."])
        }
        
        return image
    }
}
