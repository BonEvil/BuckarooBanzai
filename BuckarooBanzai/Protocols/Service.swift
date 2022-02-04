//
//  Service.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public protocol Service {

    var requestType: HTTPRequestType { get }
    var acceptType: HTTPAcceptType { get }
    var timeout: TimeInterval { get }
    var requestURL: String { get }
    
    var contentType: HTTPContentType? { get }
    var requestBody: Any? { get }
    var requestBodyOverride: Data? { get }
    var additionalHeaders: [String: String]? { get }
    
    var requestSerializer: RequestSerializer? { get }
    var sessionDelegate: URLSessionTaskDelegate? { get }
    
    var testResponse: HTTPResponse? { get }
}
