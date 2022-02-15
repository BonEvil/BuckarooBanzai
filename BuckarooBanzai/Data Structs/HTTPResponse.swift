//
//  HTTPResponse.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/25/20.
//

import Foundation
import UIKit

public struct HTTPResponse {
    
    /// Default initializer for the repsonse object
    /// - Parameters:
    ///   - statusCode: Will hold the HTTP status code returned from the service call.
    ///   - headers: Will hold any key/value pairs returned in the header from the service call.
    ///   - body: Will hold the data returned in the body from the service call.
    public init(statusCode: Int, headers: [AnyHashable: Any], body: Data? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
    
    /// The HTTP status code returned from the service call.
    public var statusCode: Int
    
    /// Any key/value pairs returned in the header from the service call.
    public var headers: [AnyHashable: Any]
    
    /// The data returned in the body from the service call.
    public var body: Data?
    
    /// A convenience method to do simple decoding of JSON-structured data returned from the service.
    ///
    /// This method takes a Decodable Generic and tries to parse it into the object provided.
    ///
    /// ```swift
    ///let myObject: MyObject = try response.decodeBodyData()
    /// ```
    /// - Returns: The Decodable object specified or throws an error if there was no data returned or if the data could not be parsed to the specified object.
    public func decodeBodyData<T: Decodable>() throws -> T {
        guard let data = body else {
            throw BBError.decoder([NSLocalizedDescriptionKey: "No body data found."])
        }
        let decoder = JSONDecoder()
        let object = try decoder.decode(T.self, from: data)
        return object
    }
    
    /// A convenience method to do simple decoding of image data returned from the service.
    ///
    /// This method is convenient when downloading image assets.
    ///
    /// ```swift
    ///let myNetworkImage = try response.decodeBodyDataAsImage()
    /// ```
    /// - Returns: The network image asset as a ``UIImage`` or throws an error if there was no data returned or if the data could not be parsed to an image.
    public func decodeBodyDataAsImage() throws -> UIImage {
        guard let data = body else {
            throw BBError.decoder([NSLocalizedDescriptionKey: "No body data found."])
        }
        guard let image = UIImage(data: data) else {
            throw BBError.decoder([NSLocalizedDescriptionKey: "Could not create image from data."])
        }
        
        return image
    }
}
