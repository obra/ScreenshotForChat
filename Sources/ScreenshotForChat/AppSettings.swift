// ABOUTME: Observable settings class managing app preferences with UserDefaults persistence
// ABOUTME: Handles HiDPI scaling and other user preferences

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("disableHiDPI") var disableHiDPI: Bool = false
    
    private init() {
        print("📝 Settings initialized - HiDPI disabled: \(disableHiDPI)")
    }
}