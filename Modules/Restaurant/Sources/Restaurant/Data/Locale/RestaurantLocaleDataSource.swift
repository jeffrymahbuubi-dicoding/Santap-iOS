import Combine
import CoreData
import Foundation
import SantapCore

public final class RestaurantLocaleDataSource: LocaleDataSource {
  private enum Key {
    static let entity = "RestaurantEntity"
    static let id = "id"
    static let name = "name"
    static let city = "city"
    static let summary = "summary"
    static let rating = "rating"
    static let pictureId = "pictureId"
    static let sortIndex = "sortIndex"
    static let isFavorite = "isFavorite"
    static let favoritedAt = "favoritedAt"
  }

  private static let notListed = -1

  private static let model: NSManagedObjectModel? = {
    Bundle.module
      .url(forResource: "Santap", withExtension: "momd")
      .flatMap { NSManagedObjectModel(contentsOf: $0) }
  }()

  private let context: NSManagedObjectContext?

  public init(location: StoreLocation = .standard) {
    guard let model = Self.model else {
      context = nil
      return
    }
    let container = NSPersistentContainer(name: "Santap", managedObjectModel: model)
    let description = NSPersistentStoreDescription(url: Self.storeURL(for: location))
    description.type = NSSQLiteStoreType
    container.persistentStoreDescriptions = [description]
    var loaded = false
    container.loadPersistentStores { _, error in
      loaded = error == nil
    }
    context = loaded ? container.newBackgroundContext() : nil
    context?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  public func list(request: RestaurantListRequest) -> AnyPublisher<[RestaurantEntity], Error> {
    switch request {
    case .all:
      return perform { context in
        try Self.fetch(in: context, predicate: NSPredicate(format: "%K >= 0", Key.sortIndex))
          .map(Self.entity(from:))
          .sorted { $0.sortIndex < $1.sortIndex }
      }
    case .favorites:
      return perform { context in
        try Self.fetch(in: context, predicate: NSPredicate(format: "%K == YES", Key.isFavorite))
          .map(Self.entity(from:))
          .sorted { ($0.favoritedAt ?? .distantPast) > ($1.favoritedAt ?? .distantPast) }
      }
    }
  }

  public func add(entities: [RestaurantEntity]) -> AnyPublisher<Bool, Error> {
    perform { context in
      var rows = Dictionary(
        try Self.fetch(in: context).compactMap { row in
          (row.value(forKey: Key.id) as? String).map { ($0, row) }
        },
        uniquingKeysWith: { first, _ in first }
      )
      let incoming = Set(entities.map(\.id))
      for entity in entities {
        let row = rows[entity.id] ?? Self.insertRow(id: entity.id, in: context)
        rows[entity.id] = row
        Self.writeListFields(of: entity, to: row)
      }
      for (id, row) in rows where !incoming.contains(id) {
        if row.value(forKey: Key.isFavorite) as? Bool == true {
          row.setValue(Self.notListed, forKey: Key.sortIndex)
        } else {
          context.delete(row)
        }
      }
      try Self.save(context)
      return true
    }
  }

  public func get(id: String) -> AnyPublisher<RestaurantEntity?, Error> {
    perform { context in
      try Self.fetch(in: context, id: id).first.map(Self.entity(from:))
    }
  }

  public func update(id: String, entity: RestaurantEntity) -> AnyPublisher<Bool, Error> {
    perform { context in
      let existing = try Self.fetch(in: context, id: id).first
      if entity.isFavorite {
        let row = existing ?? Self.insertRow(id: id, in: context)
        if existing == nil {
          Self.writeListFields(of: entity, to: row)
        }
        if row.value(forKey: Key.isFavorite) as? Bool != true {
          row.setValue(true, forKey: Key.isFavorite)
          row.setValue(Date(), forKey: Key.favoritedAt)
        }
      } else if let row = existing {
        let sortIndex = row.value(forKey: Key.sortIndex) as? Int ?? Self.notListed
        if sortIndex < 0 {
          context.delete(row)
        } else {
          row.setValue(false, forKey: Key.isFavorite)
          row.setValue(nil, forKey: Key.favoritedAt)
        }
      }
      try Self.save(context)
      return entity.isFavorite
    }
  }

  private static func storeURL(for location: StoreLocation) -> URL {
    switch location {
    case .standard:
      return NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Santap.sqlite")
    case .inMemory:
      return URL(fileURLWithPath: "/dev/null")
    case .file(let url):
      return url
    }
  }

  private func perform<Value>(
    _ work: @escaping (NSManagedObjectContext) throws -> Value
  ) -> AnyPublisher<Value, Error> {
    Deferred {
      Future<Value, Error> { promise in
        guard let context = self.context else {
          promise(.failure(DatabaseError.unavailable))
          return
        }
        context.perform {
          do {
            promise(.success(try work(context)))
          } catch {
            context.rollback()
            promise(.failure(DatabaseError.operationFailed))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }

  private static func fetch(
    in context: NSManagedObjectContext,
    predicate: NSPredicate? = nil
  ) throws -> [NSManagedObject] {
    let request = NSFetchRequest<NSManagedObject>(entityName: Key.entity)
    request.predicate = predicate
    return try context.fetch(request)
  }

  private static func fetch(in context: NSManagedObjectContext, id: String) throws -> [NSManagedObject] {
    let request = NSFetchRequest<NSManagedObject>(entityName: Key.entity)
    request.predicate = NSPredicate(format: "%K == %@", Key.id, id)
    request.fetchLimit = 1
    return try context.fetch(request)
  }

  private static func insertRow(id: String, in context: NSManagedObjectContext) -> NSManagedObject {
    let row = NSEntityDescription.insertNewObject(forEntityName: Key.entity, into: context)
    row.setValue(id, forKey: Key.id)
    return row
  }

  private static func writeListFields(of entity: RestaurantEntity, to row: NSManagedObject) {
    row.setValue(entity.name, forKey: Key.name)
    row.setValue(entity.city, forKey: Key.city)
    row.setValue(entity.summary, forKey: Key.summary)
    row.setValue(entity.rating, forKey: Key.rating)
    row.setValue(entity.pictureId, forKey: Key.pictureId)
    row.setValue(entity.sortIndex, forKey: Key.sortIndex)
  }

  private static func entity(from row: NSManagedObject) -> RestaurantEntity {
    RestaurantEntity(
      id: row.value(forKey: Key.id) as? String ?? "",
      name: row.value(forKey: Key.name) as? String ?? "",
      city: row.value(forKey: Key.city) as? String ?? "",
      summary: row.value(forKey: Key.summary) as? String ?? "",
      rating: row.value(forKey: Key.rating) as? Double ?? 0,
      pictureId: row.value(forKey: Key.pictureId) as? String,
      sortIndex: row.value(forKey: Key.sortIndex) as? Int ?? 0,
      isFavorite: row.value(forKey: Key.isFavorite) as? Bool ?? false,
      favoritedAt: row.value(forKey: Key.favoritedAt) as? Date
    )
  }

  private static func save(_ context: NSManagedObjectContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }
}
