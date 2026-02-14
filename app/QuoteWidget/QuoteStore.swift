import Foundation
import CoreData
import WidgetKit

// MARK: - Quote (lekki struct dla widgetu - bez Core Data)
struct Quote: Identifiable, Codable {
    let id: UUID
    var text: String
    var author: String
    var dateAdded: Date

    init(id: UUID = UUID(), text: String, author: String, dateAdded: Date = Date()) {
        self.id = id
        self.text = text
        self.author = author
        self.dateAdded = dateAdded
    }
}

// MARK: - Core Data Stack (singleton)
final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: AppConfig.CoreData.modelName)

        // Store w App Group - dostępny zarówno dla aplikacji jak i widgetu
        if let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup)?
            .appendingPathComponent(AppConfig.CoreData.storeFile) {

            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data błąd: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Core Data zapis błąd: \(error)")
        }
    }
}

// MARK: - QuoteStore
final class QuoteStore: ObservableObject {
    @Published var quotes: [QuoteEntity] = []
    @Published var searchText: String = "" {
        didSet {
            fetchQuotes()
            
            NotificationCenter.default.post(name: .quotesSearchChanged, object: nil)
        }
    }

    private let stack = CoreDataStack.shared

    init() {
        fetchQuotes()
        if quotes.isEmpty { insertSampleData() }
    }

    // MARK: - Fetch
    func fetchQuotes() {
        let request = NSFetchRequest<QuoteEntity>(entityName: AppConfig.CoreData.entityName)

        if !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "text CONTAINS[cd] %@ OR author CONTAINS[cd] %@",
                searchText, searchText
            )
        }

        // Domyślnie: najnowsze pierwsze
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        request.fetchBatchSize = 20

        do {
            quotes = try stack.context.fetch(request)
        } catch {
            print("Fetch błąd: \(error)")
        }
    }

    // MARK: - CRUD
    func addQuote(text: String, author: String) {
        _ = QuoteEntity.create(in: stack.context, text: text, author: author)
        stack.save()
        fetchQuotes()
    }

    func deleteQuote(_ entity: QuoteEntity) {
        stack.context.delete(entity)
        stack.save()
        fetchQuotes()
    }

    func updateQuote(_ entity: QuoteEntity, text: String, author: String) {
        entity.text = text
        entity.author = author
        stack.save()
        fetchQuotes()
    }

    // MARK: - Losowy cytat (dla widgetu)
    // fetchLimit: 1 po COUNT(*) - nie ładuje wszystkich do pamięci
    func getRandomQuote() -> Quote? {
        let countRequest = NSFetchRequest<NSNumber>(entityName: AppConfig.CoreData.entityName)
        countRequest.resultType = .countResultType

        guard let count = try? stack.context.fetch(countRequest).first?.intValue,
              count > 0 else { return nil }

        let request = NSFetchRequest<QuoteEntity>(entityName: AppConfig.CoreData.entityName)
        request.fetchOffset = Int.random(in: 0..<count)
        request.fetchLimit = 1

        return (try? stack.context.fetch(request).first)?.toQuote()
    }

    // MARK: - Sample data
    private func insertSampleData() {
        let samples: [(String, String)] = [
            ("Jedynym sposobem na dobrą robotę jest kochać to, co się robi.", "Steve Jobs"),
            ("Życie jest tym, co dzieje się, gdy jesteś zajęty robieniem innych planów.", "John Lennon"),
            ("Sukces to nie klucz do szczęścia. Szczęście jest kluczem do sukcesu.", "Albert Schweitzer"),
            ("Nie liczy się to, ile masz lat, ale jak je przeżyłeś.", "Abraham Lincoln"),
            ("Bądź zmianą, którą chcesz widzieć w świecie.", "Mahatma Gandhi")
        ]
        samples.forEach { _ = QuoteEntity.create(in: stack.context, text: $0.0, author: $0.1) }
        stack.save()
        fetchQuotes()
    }
}


// MARK: - Notification names
extension Notification.Name {
    static let quotesSearchChanged = Notification.Name("quotesSearchChanged")
}
