
import SwiftUI

extension Font {
    
    // MARK: - App Typography
    
    static var titleLarge: Font {
        return Font.largeTitle.weight(.bold)
    }
    
    static var bodyBold: Font {
        return Font.body.weight(.bold)
    }
    
    static var captionText: Font {
        return Font.caption
    }
    
    static var headlineText: Font {
        return Font.headline
    }
    
    static var subheadlineText: Font {
        return Font.subheadline
    }
}
