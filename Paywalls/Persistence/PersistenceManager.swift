import Foundation
import SQLite3

protocol PersistenceModel: Codable {
    static var entityName: String { get }
}

struct PersistenceResult<T: PersistenceModel> {
    let id: Int
    let data: T
    let syncedAt: Date?
    let createdAt: Date

    func prefilledUpdateRequest() -> PersistenceUpdateRequest<T> {
        .init(id: id, syncedAt: syncedAt)
    }

    func prefilledDeleteRequest() -> PersistenceDeleteRequest<T> {
        .init(id: id)
    }
}

struct PersistenceUpdateRequest<T: PersistenceModel> {
    let id: Int
    var syncedAt: Date?
}

struct PersistenceDeleteRequest<T: PersistenceModel> {
    let id: Int
}

protocol PersistenceManagerProtocol {
    func insert<T: PersistenceModel>(_ type: T.Type, _ entry: T)
    func getAll<T: PersistenceModel>(_ type: T.Type, limit: Int, offset: Int) -> [PersistenceResult<T>]
    func find<T: PersistenceModel>(_ type: T.Type, id: Int) -> PersistenceResult<T>?
    func update<T: PersistenceModel>(_ type: T.Type, request: PersistenceUpdateRequest<T>)
    func delete<T: PersistenceModel>(_ type: T.Type, requests: [PersistenceDeleteRequest<T>])
    func deleteAll(_ type: PersistenceModel.Type)
}

enum SqlitePersistenceManagerError: Error {
    case databaseNotOpened
    case couldNotPrepareStatement
}

final class SqlitePersistenceManager: PersistenceManagerProtocol {
    private var database: Database?
    private let logger: LoggerProtocol
    private let databaseName: String
    private let persistableModels: [PersistenceModel.Type]

    init(
        databaseFileName: String,
        persistableModels: [PersistenceModel.Type],
        logger: LoggerProtocol
    ) {
        self.databaseName = "\(databaseFileName).sqlite"
        self.persistableModels = persistableModels
        self.logger = logger

        do {
            database = try Database(name: databaseName)
            guard let database else {
                throw SqlitePersistenceManagerError.databaseNotOpened
            }
            database.applyWriteAheadLog()

            for model in persistableModels {
                setupTable(for: model)
            }

            logger.debug("Database opened at \(database.file)")
        } catch {
            logger.error("Couldn't open database with name \(databaseName)")
        }
    }

    deinit {
        database?.close()
    }

    private func setupTable(for entityType: PersistenceModel.Type) {
        let tableName = tableName(for: entityType)
        let sql = """
CREATE TABLE IF NOT EXISTS \(tableName) (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data BLOB NOT NULL,
    syncedAt DATETIME DEFAULT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_synced_at ON \(tableName) (syncedAt);
"""
        do {
            try database?.execute(sql)
            logger.debug("\(tableName) created with index")
        } catch {
            logger.error("Error setting up table \(tableName)")
        }
    }

    public func insert<T: PersistenceModel>(_ type: T.Type, _ entry: T) {
        let tableName = tableName(for: type)
        let sql = "insert into \(tableName) (data) VALUES (:data)"
        do {
            let data = try encodeToData(entry)
            _ = try database?.execute(sql, .init("data", data))
            logger.debug("Insert row in \(tableName)")
        } catch {
            logger.error("Error inserting data into \(tableName): \(error.localizedDescription)")
        }
    }

    func update<T: PersistenceModel>(_ type: T.Type, request: PersistenceUpdateRequest<T>) {
        let tableName = tableName(for: type)
        do {
            let values = ContentValues()
            values.add([
                .init("syncedAt", request.syncedAt)
            ])
            _ = try database?.update(into: tableName, values: values, where: "id = :id", with: .init("id", request.id))
            logger.debug("Updated row in \(tableName) with id \(request.id)")
        } catch {
            logger.error("Error inserting data into \(tableName): \(error.localizedDescription)")
        }
    }

    public func getAll<T: PersistenceModel>(_ type: T.Type, limit: Int, offset: Int) -> [PersistenceResult<T>] {
        let tableName = tableName(for: type)
        do {
            guard let stmt = try database?.prepare("SELECT * FROM \(tableName) LIMIT :limit OFFSET :offset") else {
                throw SqlitePersistenceManagerError.couldNotPrepareStatement
            }
            stmt.bind([
                .init("limit", limit),
                .init("offset", offset),
            ])

            let rows = stmt.query()
            var entries: [PersistenceResult<T>] = []
            while try rows.next() {
                if let row = persistanceResult(type, from: rows) {
                    entries.append(row)
                }
            }
            return entries
        } catch {
            logger.error("Error get on \(tableName): \(error.localizedDescription)")
            return []
        }
    }

    public func find<T: PersistenceModel>(_ type: T.Type, id: Int) -> PersistenceResult<T>? {
        let tableName = tableName(for: type)
        do {
            let sql = "SELECT * FROM \(tableName) WHERE id = :id"
            guard let query = try database?.query(sql, .init(":id", id)) else {
                logger.error("Could not query \(tableName). Database not opened")
                return nil
            }

            guard let row = persistanceResult(T.self, from: query) else {
                return nil
            }

            return row
        } catch {
            logger.error("Error get on \(tableName): \(error.localizedDescription)")
        }

        return nil
    }

    public func delete<T: PersistenceModel>(_ type: T.Type, requests: [PersistenceDeleteRequest<T>]) {
        let tableName = tableName(for: type)
        do {
            let ids = requests.map { String($0.id) }.joined(separator: ",")
            try database?.execute("DELETE FROM \(tableName) WHERE id IN (\(ids))")
            logger.debug("Deleted rows in \(tableName) with ids \(ids)")
        } catch {
            logger.error("Error delete on \(tableName): \(error.localizedDescription)")
        }
    }

    public func deleteAll(_ type: PersistenceModel.Type) {
        let tableName = tableName(for: type)
        do {
            try database?.execute("DELETE FROM \(tableName)")
            logger.debug("Deleted all rows in \(tableName)")
        } catch {
            logger.error("Error deleteAll on \(tableName): \(error.localizedDescription)")
        }
    }

    private func persistanceResult<T: PersistenceModel>(
        _ type: T.Type,
        from query: DatabaseRows
    ) -> PersistenceResult<T>? {
        guard let id = query.int("id"),
              let data = query.data("data"),
              let createdAt = query.date("createdAt") else {
            return nil
        }

        do {
            return .init(
                id: id,
                data: try decodeFromData(T.self, data),
                syncedAt: query.date("syncedAt"),
                createdAt: createdAt
            )
        } catch {
            let message: String
            if let dataString = String(data: data, encoding: .utf8) {
                message = "Unable to decode persistent result \(type): \(error.localizedDescription): \(dataString)"
            } else {
                message = "Unable to decode persistent result \(type): \(error.localizedDescription). Unknown data string."
            }
            logger.error(message)

            delete(type, requests: [.init(id: id)])
        }
        return nil
    }

    private func tableName(for entry: PersistenceModel.Type) -> String {
        entry.entityName
    }

    private func encodeToData(_ entry: PersistenceModel) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(entry)
    }

    private func decodeFromData<T: PersistenceModel>(_ type: T.Type, _ data: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}
