import Foundation
import CoreData

@objc(QuoteEntity)
public class QuoteEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var author: String?
    @NSManaged public var dateAdded: Date?
}

extension QuoteEntity: Identifiable {

    static func create(in context: NSManagedObjectContext, text: String, author: String) -> QuoteEntity {
        let entity = QuoteEntity(context: context)
        entity.id = UUID()
        entity.text = text
        entity.author = author
        entity.dateAdded = Date()
        return entity
    }

    // Lekka konwersja do struct Quote - używana tylko przez widget
    func toQuote() -> Quote {
        Quote(
            id: id ?? UUID(),
            text: text ?? "",
            author: author ?? "",
            dateAdded: dateAdded ?? Date()
        )
    }

    // Bezpieczny dostęp do id - eliminuje ?? UUID() wszędzie w UI
    var safeID: UUID { id ?? UUID() }
}
