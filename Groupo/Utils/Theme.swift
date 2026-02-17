import SwiftUI

// MARK: - Color Theme
extension Color {
    static let brandTeal = Color("AccentColor")
    
    // MARK: - Custom Theme Colors
    
    static let appPrimaryBackground = Color("PrimaryBackground")
    static let appSecondaryBackground = Color("SecondaryBackground")
    static let appTextSecondary = Color("TextSecondary")
    static let appDangerRed = Color("DangerRed")
    
    // MARK: - Semantic Colors
    
    static var successGreen: Color {
        Color(UIColor.systemGreen)
    }
    
    static var warningOrange: Color {
        Color(UIColor.systemOrange)
    }
}
