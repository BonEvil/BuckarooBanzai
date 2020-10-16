//
//  HTTPResponse.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/25/20.
//

import Foundation

public struct HTTPResponse {
    
    public var statusCode: Int
    public var headers: [AnyHashable: Any]
    public var body: Data?
    public var parsedObject: Any?
}
