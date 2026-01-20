import Foundation

enum Constants {
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardSpacing: CGFloat = 12
        static let gridColumns = 3
        static let coverAspectRatio: CGFloat = 0.7
    }
    
    enum Colors {
        static let accentGradient = ["#8B5CF6", "#A855F7", "#D946EF"]
    }
    
    enum UserDefaults {
        static let ghostModeKey = "ghostModeEnabled"
        static let hapticsEnabledKey = "hapticsEnabled"
        static let webtoonModeKey = "webtoonModeEnabled"
    }
}
