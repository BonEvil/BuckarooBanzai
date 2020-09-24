//
//  HTTPRequestType.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public enum HTTPRequestType
{
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
    case CUSTOM(String)
}
