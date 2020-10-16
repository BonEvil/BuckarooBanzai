//
//  BuckarooBanzai.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

open class BuckarooBanzai: NSObject {
    
    public typealias HTTPResponseCallback = (HTTPResponse, Error?) -> Void
    
    fileprivate static var instance: BuckarooBanzai?
    
    public static var errorDomain = "BuckarooBanzaiError"
    
    lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Buckaroo.Queue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    fileprivate var session: Foundation.URLSession!
    private var credential: URLCredential?
    
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
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
    }
    
    // MARK: PUBLIC METHODS
    
    public func resetSession() {
        
        session = nil
        credential = nil
        createSession()
    }
    
    public func start(service: Service, withResponseCallback responseCallback: @escaping HTTPResponseCallback) {
        
        if let testResponse = service.testResponse {
            responseCallback(testResponse, nil)
            return
        }
        
        do {
            let request = try createRequest(service)
            sendRequest(request, forService: service, withResponse: responseCallback)
        } catch let error {
            let httpResponse = HTTPResponse(statusCode: -1, headers: [String: Any](), body: nil, parsedObject: nil)
            responseCallback(httpResponse, error)
            return
        }
    }
    
    // MARK: HELPER METHODS
    
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
        
        request.setValue(service.contentType.string(), forHTTPHeaderField: "Content-Type")
        request.setValue(service.acceptType.string(), forHTTPHeaderField: "Accept")
        
        
        guard let requestParams = service.requestParams, requestParams.count > 0 else {
            return request as URLRequest
        }
        
        do {
            let data =  try serializeRequest(forService: service)
            request.httpBody = data
            return request as URLRequest
        } catch let error {
            throw error
        }
    }
    
    fileprivate func sendRequest(_ request: URLRequest, forService service: Service, withResponse responseCallback: @escaping HTTPResponseCallback) {
        
        let task = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                responseCallback(HTTPResponse(statusCode: -1, headers: [String: Any](), body: nil, parsedObject: nil), error)
                return
            }
            
            let statusCode = httpUrlResponse.statusCode
            let allHeaderFields = httpUrlResponse.allHeaderFields
                        
            var httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data, parsedObject: nil)
            
            if let error = error {
                responseCallback(httpResponse, error)
                return
            }
            
            if statusCode < 200 || statusCode >= 300 {
                let error = NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Status code not OK: \(statusCode)"])
                responseCallback(httpResponse, error)
                return
            }
            
            let receivedContentType = self.contentType(fromHeaders: allHeaderFields)
            let acceptType = service.acceptType.string()
            if receivedContentType != acceptType {
                let error = NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Expecting Content-Type [\(service.acceptType.string())] but got [\(receivedContentType)]"])
                responseCallback(httpResponse, error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Body data not valid"])
                responseCallback(httpResponse, error)
                return
            }
            
            httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data, parsedObject: stringFromData(data))
            
            if let responseParser = service.responseParser {
                do {
                    let object = try responseParser.parse(data)
                    httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data, parsedObject: object)
                    responseCallback(httpResponse, nil)
                } catch let error {
                    responseCallback(httpResponse, error)
                }
                
                return
            }
            
            do {
                let object = try self.parseResponse(forService: service, data: data)
                httpResponse = HTTPResponse(statusCode: statusCode, headers: allHeaderFields, body: data, parsedObject: object)
                responseCallback(httpResponse, nil)
            } catch let error {
                responseCallback(httpResponse, error)
            }
        })
        
        task.resume()
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
    
    fileprivate func stringFromData(_ data: Data) -> String {
        
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return ""
    }
    
    fileprivate func parseResponse(forService service: Service, data: Data) throws -> Any {
        
        if let parser = service.responseParser {
            do {
                let object = try parser.parse(data)
                return object
            } catch let error {
                throw error
            }
        } else {
            switch service.acceptType {
            case .JSON:
                do {
                    let object = try JSONResponseParser().parse(data)
                    return object
                } catch let error {
                    throw error
                }
            default:
                return data
            }
        }
    }
    
    fileprivate func serializeRequest(forService service: Service) throws -> Data {
        
        guard let requestParams = service.requestParams, requestParams.count > 0 else {
            throw NSError(domain: BuckarooBanzai.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "No request params provided"])
        }
        
        if let serializer = service.requestSerializer  {
            do {
                let data = try serializer.serialize(requestParams as Any)
                return data
            } catch let error {
                throw error
            }
        } else {
            switch service.contentType {
            case .JSON:
                do {
                    let data = try JSONRequestSerializer().serialize(requestParams as Any)
                    return data
                } catch let error {
                    throw error
                }
            default:
                do {
                    let data = try FormRequestSerializer().serialize(requestParams as Any)
                    return data
                } catch let error {
                    throw error
                }
            }
        }
    }
}

extension BuckarooBanzai: URLSessionDelegate {
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.previousFailureCount == 0 {
            let authMethod = challenge.protectionSpace.authenticationMethod
            print("authentication method: \(authMethod)")
            
            switch authMethod {
            case NSURLAuthenticationMethodClientCertificate:
                completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
            default:
                completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
            }
        } else {
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}
