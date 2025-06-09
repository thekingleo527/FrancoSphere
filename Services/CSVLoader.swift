
//  CSVLoader.swift
//  FrancoSphere
//
//  Created by Nova on 2025-05-22.
//

import Foundation

/// Ultra-light CSV reader (no third-party dependency).
/// - Returns an array where element 0 is the header row.
struct CSVLoader {

    static func rows(from url: URL) throws -> [[String]] {
        let raw = try String(contentsOf: url)
        return raw
            .split(whereSeparator: \.isNewline)
            .map { $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
    }

    /// Builds a `["header-name": index]` map for quick look-ups.
    static func headerMap(_ header: [String]) -> [String:Int] {
        Dictionary(uniqueKeysWithValues:
            header.enumerated().map { ($1.lowercased(), $0) })
    }
}
