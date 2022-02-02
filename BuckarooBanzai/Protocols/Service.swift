//
//  Service.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public protocol Service {

    var requestType: HTTPRequestType { get }
    var contentType: HTTPContentType? { get }
    var acceptType: HTTPAcceptType { get }
    var timeout: TimeInterval { get }
    var requestURL: String { get }
    
    var requestParams: [String: Any]? { get }
    var additionalHeaders: [String: String]? { get }
    
    var requestSerializer: RequestSerializer? { get }
    var responseParser: ResponseParser? { get }
    var sessionDelegate: URLSessionTaskDelegate? { get }
    
    var testResponse: HTTPResponse? { get }
}
