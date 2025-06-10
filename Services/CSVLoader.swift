import Foundation

enum CSVLoader {
    
    /// Parse CSV file into array of rows (each row is array of strings)
    static func rows(from url: URL) throws -> [[String]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        return lines.map { line in
            parseCSVLine(line)
        }
    }
    
    /// Create header map (column name -> index) from first row
    static func headerMap(_ headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            // Convert to lowercase and trim whitespace
            let key = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            map[key] = index
        }
        return map
    }
    
    /// Parse a single CSV line handling quoted values
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Don't forget the last field
        result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return result
    }
}
