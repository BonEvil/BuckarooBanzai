//
//  BuckarooBanzai.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

open class BuckarooBanzai: NSObject {
        
    fileprivate static var instance: BuckarooBanzai?
    
    public static var errorDomain = "BuckarooBanzaiError"
    public static let BBHTTPResponseErrorKey = "_bbHttpResponseErrorKey"
    public static let BBHTTPStatusCodeErrorKey = "_bbHttpStatusCodeErrorKey"
    
    lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Buckaroo_Queue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    fileprivate var session: Foundation.URLSession!
    
    private override init() {
        super.init()
        createSession()
    }
    
    // MARK: SHARED INSTANCE
    
    public class func sharedInstance() -> BuckarooBanzai {
        guard let instance = BuckarooBanzai.instance else {
            BuckarooBanzai.instance = BuckarooBanzai()
            return BuckarooBanzai.instance!
        }
        
        return instance
    }
    
    // MARK: SETUP METHODS
    
    fileprivate func createSession() {
        session = URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
    }
    
    // MARK: - PUBLIC METHODS
    
    public func resetSession() {
        session = nil
        createSession()
    }
    
    public func start(service: Service) async throws -> HTTPResponse {
        let request = try createRequest(service)
        let response = try await sendRequest(request, forService: service)
        return response
    }
    
    // MARK: - PRIVATE METHODS
    
    fileprivate func createRequest(_ service: Service) throws -> URLRequest {
        let request = NSMutableURLRequest()
        request.url = URL(string: service.requestURL)
        request.httpMethod = service.requestType.string()
        request.timeoutInterval = service.timeout
        
        if let additionalHeaders = service.additionalHeaders {
            for (key,value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let contentType = service.contentType {
            request.setValue(contentType.string(), forHTTPHeaderField: "Content-Type")
        }
        request.setValue(service.acceptType.string(), forHTTPHeaderField: "Accept")
        
        guard let requestParams = service.requestParams, requestParams.count > 0 else {
            return request as URLRequest
        }
        
        if let body = service.requestBodyOverride {
            request.httpBody = body
            return request as URLRequest
        }
        
        do {
            let data = try serializeRequest(forService: service)
            request.httpBody = data
            return request as URLRequest
        } catch let error {
            throw error
        }
    }
    
    fileprivate func sendRequest(_ request: URLRequest, forService service: Service) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request, delegate: service.sessionDelegate)
        
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            throw NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : "Bad response."])
        }
        
        let allHeaderFields = httpUrlResponse.allHeaderFields
        let statusCode = httpUrlResponse.statusCode
        var httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data, parsedObject: nil)
        
        do {
            try checkStatusCode(statusCode)
        } catch let error as NSError {
            var userInfo = error.userInfo
            userInfo[BuckarooBanzai.BBHTTPResponseErrorKey] = httpResponse
            let modError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            throw modError
        }
        
        let receivedContentType = self.contentType(fromHeaders: allHeaderFields)
        let acceptType = service.acceptType.string()
        
        do {
            try checkContentType(receivedContentType, forAcceptType: acceptType)
        } catch let error as NSError {
            var userInfo = error.userInfo
            userInfo[BuckarooBanzai.BBHTTPResponseErrorKey] = httpResponse
            let modError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            throw modError
        }
        
        if let parser = service.responseParser {
            let parsedObject = try parseWithCustomParser(parser, usingData: data)
            httpResponse.parsedObject = parsedObject
        }
        
        return httpResponse
    }
    
    fileprivate func checkStatusCode(_ statusCode: Int) throws {
        if statusCode < 200 || statusCode >= 300 {
            throw NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Status code not OK: \(statusCode)", BuckarooBanzai.BBHTTPStatusCodeErrorKey: statusCode])
        }
    }
    
    fileprivate func checkContentType(_ receivedContentType: String, forAcceptType acceptType: String) throws {
        if receivedContentType != acceptType {
            throw NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Expecting Content-Type [\(acceptType)] but got [\(receivedContentType)]"])
        }
    }
    
    fileprivate func contentType(fromHeaders headers: [AnyHashable: Any]) -> String {
        
        guard let contentTypeHeader = headers["Content-Type"] as? String else {
            return ""
        }
        
        let contentTypeArray = contentTypeHeader.components(separatedBy: ";")
        if contentTypeArray.count > 0 {
            return contentTypeArray[0]
        }
        
        return ""
    }
    
    fileprivate func parseWithCustomParser(_ parser: ResponseParser, usingData data: Data) throws -> Any {
        do {
            let object: Any = try parser.parse(data)
            return object
        } catch let error {
            throw error
        }
    }
    
    // MARK: - Serialize request body
    
    fileprivate func serializeRequest(forService service: Service) throws -> Data? {
        
        guard let requestParams = service.requestParams, requestParams.count > 0 else {
            return nil
        }
        
        if let serializer = service.requestSerializer  {
            return try serializeRequestParams(requestParams, withCustomSerializer: serializer)
        } else {
            return try serializeRequestParams(requestParams, forContentType: service.contentType)
        }
    }
    
    // MARK: - Custom request serializer
    
    fileprivate func serializeRequestParams(_ requestParams: [String: Any], withCustomSerializer serializer: RequestSerializer) throws -> Data {
        do {
            let data = try serializer.serialize(requestParams as Any)
            return data
        } catch let error {
            throw error
        }
    }
    
    // MARK: - Standard request body serializers
    
    fileprivate func serializeRequestParams(_ requestParams: [String: Any], forContentType contentType: HTTPContentType?) throws -> Data? {
        guard let contentType = contentType else {
            return nil
        }

        switch contentType {
        case .JSON:
            return try serializeJsonFromRequestParams(requestParams)
        case .FORM:
            return try serializeFormFromRequestParams(requestParams)
        default:
            return nil
        }
    }
    
    fileprivate func serializeJsonFromRequestParams(_ requestParams: [String: Any]) throws -> Data {
        do {
            let data = try JSONRequestSerializer().serialize(requestParams as Any)
            return data
        } catch let error {
            throw error
        }
    }
    
    fileprivate func serializeFormFromRequestParams(_ requestParams: [String: Any]) throws -> Data {
        do {
            let data = try FormRequestSerializer().serialize(requestParams as Any)
            return data
        } catch let error {
            throw error
        }
    }
}

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
