import Foundation
import CryptoKit

extension String {
    /// SHA256 hash of the string for cache keys
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Double {
    /// Format chapter number nicely (1.0 -> "1", 1.5 -> "1.5")
    var chapterString: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

extension Int64 {
    /// Format bytes to human readable string
    var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
