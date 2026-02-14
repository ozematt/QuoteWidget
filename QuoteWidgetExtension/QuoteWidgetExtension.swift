import WidgetKit
import SwiftUI
import CoreData

// MARK: - Timeline Provider
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: Quote(text: "Ładowanie...", author: ""))
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: Date(), quote: resolveQuote()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let entry = QuoteEntry(date: Date(), quote: resolveQuote())
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func resolveQuote() -> Quote {
        let defaults = AppConfig.defaults

        if let pinnedID = defaults?.string(forKey: AppConfig.Keys.pinnedQuoteID),
           let uuid = UUID(uuidString: pinnedID),
           let quote = fetchQuote(by: uuid) {
            return quote
        }

        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults?.object(forKey: AppConfig.Keys.lastQuoteDate) as? Date,
           Calendar.current.startOfDay(for: lastDate) == today,
           let dailyID = defaults?.string(forKey: AppConfig.Keys.dailyQuoteID),
           let uuid = UUID(uuidString: dailyID),
           let quote = fetchQuote(by: uuid) {
            return quote
        }

        let quote = QuoteStore().getRandomQuote() ?? Quote(text: "Dodaj swój pierwszy cytat!", author: "")
        defaults?.set(Date(), forKey: AppConfig.Keys.lastQuoteDate)
        defaults?.set(quote.id.uuidString, forKey: AppConfig.Keys.dailyQuoteID)
        return quote
    }

    private func fetchQuote(by uuid: UUID) -> Quote? {
        let request = NSFetchRequest<QuoteEntity>(entityName: AppConfig.CoreData.entityName)
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        return (try? CoreDataStack.shared.context.fetch(request).first)?.toQuote()
    }
}

// MARK: - Entry
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

// MARK: - Widget View
struct WidgetView: View {
    let quote: Quote
    @Environment(\.widgetFamily) var family

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: return 13
        default:           return 16
        }
    }

    private var headerSize: CGFloat {
        switch family {
        case .systemSmall: return 12
        default:           return 14
        }
    }

    private var authorSize: CGFloat {
        switch family {
        case .systemSmall: return 9
        default:           return 11
        }
    }

    private var padding: CGFloat {
        switch family {
        case .systemSmall:  return 16
        case .systemMedium: return 20
        default:            return 24
        }
    }

    private var lineLimit: Int {
        switch family {
        case .systemSmall:  return 7
        case .systemMedium: return 5
        default:            return 10
        }
    }

    private var background: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.05, blue: 0.05),
                Color(red: 0.0, green: 0.0, blue: 0.0)
            ]),
            center: .center,
            startRadius: 20,
            endRadius: 500
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: headerSize, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text("CYTAT DNIA")
                    .font(.system(size: headerSize - 2, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer().frame(height: padding * 0.7)

            Text(quote.text)
                .font(.system(size: fontSize, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .lineLimit(lineLimit)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: padding * 0.7)

            Text(quote.author.uppercased())
                .font(.system(size: authorSize, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(padding)
        .modifier(WidgetBackgroundModifier(background: background))
    }
}

// MARK: - Background Modifier (iOS 16 + iOS 17 kompatybilny)
struct WidgetBackgroundModifier<Background: View>: ViewModifier {
    let background: Background

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) { background }
        } else {
            content
        }
    }
}

// MARK: - Widget Entry View
struct QuoteWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        WidgetView(quote: entry.quote)
    }
}

// MARK: - Widget Configuration
@main
struct QuoteWidget: Widget {
    let kind = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cytat Dnia")
        .description("Wyświetla losowy cytat z Twojej kolekcji.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
