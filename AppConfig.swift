import SwiftUI

// MARK: - Jeden punkt prawdy dla całej aplikacji
// ZMIEŃ appGroup na swój identyfikator!

enum AppConfig {

    // App Group
    static let appGroup = "group.com.loranstudio.quotewidget"

    // Klucze UserDefaults
    enum Keys {
        static let pinnedQuoteID = "pinnedQuoteID"
        static let dailyQuoteID  = "dailyQuoteID"
        static let lastQuoteDate = "lastQuoteDate"
    }

    // Core Data
    enum CoreData {
        static let modelName  = "QuoteModel"
        static let entityName = "QuoteEntity"
        static let storeFile  = "QuoteModel.sqlite"
    }

    // 5+6. Wszystkie kolory w jednym miejscu
    enum Colors {
        // Tło aplikacji
        static let navyCenter  = Color(red: 0.08, green: 0.10, blue: 0.15)
        static let navyEdge    = Color(red: 0.02, green: 0.03, blue: 0.08)

        // Delete button - burgundowy stonowany (opacity obniżone dla spójności z aplikacją)
        static let deleteBurgundyLight = Color(red: 0.60, green: 0.10, blue: 0.15).opacity(0.75)
        static let deleteBurgundyDark  = Color(red: 0.35, green: 0.05, blue: 0.10).opacity(0.75)

        // Tekst - named opacity levels
        static let textPrimary   = Color.white.opacity(0.95)  // cytat
        static let textSecondary = Color.white.opacity(0.50)  // autor
        static let textTertiary  = Color.white.opacity(0.40)  // ikony toolbar
        static let textMuted     = Color.white.opacity(0.30)  // placeholder
        static let textFaint     = Color.white.opacity(0.25)  // label "DODANO"

        // UI elementy
        static let divider       = Color.white.opacity(0.15)
        static let cardOverlay   = Color.white.opacity(0.02)
        static let fieldFill     = Color.white.opacity(0.03)
        static let fieldBorder   = Color.white.opacity(0.08)
        static let fieldFocused  = Color.white.opacity(0.15)
        static let searchFill    = Color.white.opacity(0.05)
        static let searchBorder  = Color.white.opacity(0.10)
    }

    // Layout
    enum Layout {
        static let cardHeight: CGFloat      = 200
        static let cardSpacing: CGFloat     = 30
        static let deleteWidth: CGFloat     = 100
        static let swipeThreshold: CGFloat  = 50
        static let cardPaddingV: CGFloat    = 48
        static let cardPaddingH: CGFloat    = 32
    }

    // 8. Animacja jako stała
    static let springAnimation = Animation.spring(response: 0.3)

    // Shared UserDefaults
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
}
