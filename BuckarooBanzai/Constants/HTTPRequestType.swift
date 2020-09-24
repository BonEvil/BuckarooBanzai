//
//  HTTPRequestType.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public enum HTTPRequestType
{
    case GET(_: String = "GET")
    case POST(_: String = "POST")
    case PUT(_: String = "PUT")
    case DELETE(_: String = "DELETE")
    case HEAD(_: String = "HEAD")
    case CUSTOM(String)
}
