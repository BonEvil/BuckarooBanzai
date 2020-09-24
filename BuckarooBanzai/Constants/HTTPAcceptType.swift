//
//  HTTPAcceptType.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public enum HTTPAcceptType {
    case XML(_: String = "application/xml")
    case JSON(_: String = "application/json")
    case HTML(_: String = "text/html")
    case TEXT(_: String = "text/plain")
    case JAVASCRIPT(_: String = "text/javascript")
    case CUSTOM(String)
}
