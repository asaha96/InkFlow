import SwiftUI
import UIKit

/// Manages async image loading with in-memory and disk caching
@Observable
final class ImageLoader {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ManhwaReaderImages", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    /// Load image from URL with caching
    func loadImage(from urlString: String, referer: String? = nil) async -> UIImage? {
        let cacheKey = urlString as NSString
        
        // Check memory cache
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }
        
        // Check disk cache
        let diskCacheURL = cacheDirectory.appendingPathComponent(urlString.sha256Hash)
        if let data = try? Data(contentsOf: diskCacheURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: cacheKey)
            return image
        }
        
        // Check if already loading
        if let existingTask = loadingTasks[urlString] {
            return await existingTask.value
        }
        
        // Start new load task
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }
            
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            if let referer = referer ?? URL(string: urlString)?.host.map({ "https://\($0)/" }) {
                request.setValue(referer, forHTTPHeaderField: "Referer")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else {
                    return nil
                }
                
                // Cache to memory
                self.memoryCache.setObject(image, forKey: cacheKey)
                
                // Cache to disk
                try? data.write(to: diskCacheURL)
                
                return image
            } catch {
                return nil
            }
        }
        
        loadingTasks[urlString] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: urlString)
        
        return result
    }
    
    /// Prefetch images for upcoming pages
    func prefetch(urls: [String], referer: String? = nil) {
        for url in urls {
            Task {
                _ = await loadImage(from: url, referer: referer)
            }
        }
    }
    
    /// Clear all caches
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Get cache size in bytes
    var cacheSize: Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}
