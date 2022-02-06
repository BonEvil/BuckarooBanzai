//
//  BuckarooBanzai.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

open class BuckarooBanzai: NSObject {
        
    fileprivate static var instance: BuckarooBanzai?
    
    static let errorDomain = "BuckarooBanzaiErrorDomain"
    static let BBHTTPResponseErrorKey = "_bbHttpResponseErrorKey"
    static let BBHTTPStatusCodeErrorKey = "_bbHttpStatusCodeErrorKey"
    
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
        session.invalidateAndCancel()
        session = nil
        createSession()
    }
    
    public func start(service: Service) async throws -> HTTPResponse {
        if let testResponse = service.testResponse {
            let response = try doTestResponse(testResponse, withAcceptType: service.acceptType)
            return response
        }
        
        let request = try createRequest(service)
        let response = try await sendRequest(request, forService: service)
        return response
    }
    
    // MARK: - PRIVATE METHODS
    
    fileprivate func doTestResponse(_ httpResponse: HTTPResponse, withAcceptType acceptType: HTTPAcceptType) throws -> HTTPResponse {
        do {
            try checkStatusCode(httpResponse.statusCode)
            try checkContentType(contentType(fromHeaders: httpResponse.headers), forAcceptType: acceptType.string())
            return httpResponse
        } catch let error as NSError {
            var userInfo = error.userInfo
            userInfo[BuckarooBanzai.BBHTTPResponseErrorKey] = httpResponse
            let modError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            throw modError
        }
    }
    
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
            throw BuckarooBanzai.createErrorWithUserInfo([NSLocalizedDescriptionKey : "Invalid response."])
        }
        
        let allHeaderFields = httpUrlResponse.allHeaderFields
        let statusCode = httpUrlResponse.statusCode
        let httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data)
        let receivedContentType = self.contentType(fromHeaders: allHeaderFields)
        let acceptType = service.acceptType.string()
        
        do {
            try checkStatusCode(statusCode)
            try checkContentType(receivedContentType, forAcceptType: acceptType)
            return httpResponse
        } catch let error as NSError {
            var userInfo = error.userInfo
            userInfo[BuckarooBanzai.BBHTTPResponseErrorKey] = httpResponse
            throw BuckarooBanzai.createErrorWithUserInfo(userInfo)
        }
    }
    
    fileprivate func checkStatusCode(_ statusCode: Int) throws {
        if statusCode < 200 || statusCode >= 300 {
            throw BuckarooBanzai.createErrorWithUserInfo([NSLocalizedDescriptionKey: "Status code not OK: \(statusCode)", BuckarooBanzai.BBHTTPStatusCodeErrorKey: statusCode])
        }
    }
    
    fileprivate func checkContentType(_ receivedContentType: String, forAcceptType acceptType: String) throws {
        if acceptType != HTTPAcceptType.ANY.string() && receivedContentType != acceptType {
            throw BuckarooBanzai.createErrorWithUserInfo([NSLocalizedDescriptionKey: "Expecting Content-Type [\(acceptType)] but got [\(receivedContentType)]"])
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
    
    // MARK: - Serialize request body
    
    fileprivate func serializeRequest(forService service: Service) throws -> Data? {
        
        guard let requestBody = service.requestBody as? [String: Any], requestBody.count > 0 else {
            return nil
        }
        
        if let serializer = service.requestSerializer  {
            return try serializeRequestParams(requestBody, withCustomSerializer: serializer)
        } else {
            return try serializeRequestParams(requestBody, forContentType: service.contentType)
        }
    }
    
    // MARK: - Custom request serializer
    
    fileprivate func serializeRequestParams(_ requestParams: Any, withCustomSerializer serializer: RequestSerializer) throws -> Data? {
        do {
            let data = try serializer.serialize(requestParams as Any)
            return data
        } catch let error {
            throw error
        }
    }
    
    // MARK: - Standard request body serializers
    
    fileprivate func serializeRequestParams(_ requestParams: Any, forContentType contentType: HTTPContentType?) throws -> Data? {
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
    
    fileprivate func serializeJsonFromRequestParams(_ requestParams: Any) throws -> Data? {
        do {
            let data = try JSONRequestSerializer().serialize(requestParams)
            return data
        } catch let error {
            throw error
        }
    }
    
    fileprivate func serializeFormFromRequestParams(_ requestParams: Any) throws -> Data? {
        do {
            let data = try FormRequestSerializer().serialize(requestParams)
            return data
        } catch let error {
            throw error
        }
    }
}

extension BuckarooBanzai {
    static func createErrorWithUserInfo(_ userInfo: [String: Any]) -> NSError {
        return NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: userInfo)
    }
}
