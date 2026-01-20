import UIKit

/// Manages haptic feedback throughout the app
@Observable
final class HapticManager {
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    @ObservationIgnored
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }
    
    init() {
        // Set default value
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hapticsEnabled")
        }
        
        // Prepare generators
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }
    
    /// Light impact - for subtle interactions
    func lightImpact() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }
    
    /// Medium impact - for page turns, etc.
    func mediumImpact() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }
    
    /// Heavy impact - for chapter end
    func heavyImpact() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
    }
    
    /// Notify chapter end with success feedback
    func chapterEnd() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Notify error
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Selection changed feedback
    func selectionChanged() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Double tap save feedback
    func doubleTapSave() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 1.0)
    }
    
    /// Refresh feedback
    func refresh() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: 0.7)
    }
}
