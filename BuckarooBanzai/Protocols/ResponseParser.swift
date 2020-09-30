//
//  ResponseParser.swift
//  BuckarooBanzai
//
//  Created by Daniel Person on 9/24/20.
//

import Foundation

public protocol ResponseParser {
    
    func parse(_ data: Data) throws -> Any
}
