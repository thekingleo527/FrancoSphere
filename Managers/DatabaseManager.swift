import SQLite
import Foundation

class DatabaseManager {
    
    static let shared = DatabaseManager()
    private var db: Connection?

    private let users = Table("users")
    
    // Expressions without the 'value:' label
    private let id = Expression<Int64>("id")
    private let name = Expression<String>("name")
    private let email = Expression<String>("email")
    private let password = Expression<String>("password")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/db.sqlite3")
            
            // Print the database path for debugging
            print("Database path: \(path)/db.sqlite3")

            try db?.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL,
                    password TEXT NOT NULL
                )
            """)

            // Add test users - wrap in do-catch to see if there are errors
            do {
                try addUser(name: "Test User", email: "test@franco.com", password: "password")
                try addUser(name: "Worker User", email: "worker@franco.com", password: "password")
                try addUser(name: "Client User", email: "client@franco.com", password: "password")
                try addUser(name: "Admin User", email: "admin@franco.com", password: "password")
                print("Test users added successfully")
            } catch {
                print("Error adding test users: \(error)")
            }

            printAllUsers()
        } catch {
            print("Error setting up database: \(error)")
        }
    }

    func addUser(name userName: String, email userEmail: String, password userPassword: String) throws {
        guard let db = db else { throw NSError(domain: "DBError", code: 1) }

        let query = users.filter(email == userEmail)
        if try db.pluck(query) == nil {
            try db.run(users.insert(
                name <- userName,
                email <- userEmail,
                password <- userPassword
            ))
            print("Added user: \(userName), \(userEmail)")
        } else {
            print("User already exists: \(userEmail)")
        }
    }

    func fetchUser(byEmail userEmail: String) throws -> (String, String, String)? {
        guard let db = db else { throw NSError(domain: "DBError", code: 1) }

        print("Searching for user with email: \(userEmail)")
        if let user = try db.pluck(users.filter(email == userEmail)) {
            let fetchedName: String = try user.get(name)
            let fetchedEmail: String = try user.get(email)
            let fetchedPassword: String = try user.get(password)
            print("Found user: \(fetchedName), \(fetchedEmail)")
            return (fetchedName, fetchedEmail, fetchedPassword)
        }
        print("User not found with email: \(userEmail)")
        return nil
    }

    func authenticateUser(email userEmail: String, password userPassword: String, completion: @escaping (Bool, String?) -> Void) {
        do {
            print("Attempting to authenticate: \(userEmail)")
            
            if let userData = try fetchUser(byEmail: userEmail) {
                let storedPassword = userData.2
                if storedPassword == userPassword {
                    print("Password match for \(userEmail)")
                    completion(true, nil)
                } else {
                    print("Password mismatch for \(userEmail)")
                    completion(false, "Incorrect password")
                }
            } else {
                print("No user found with email: \(userEmail)")
                completion(false, "User not found")
            }
        } catch {
            print("Authentication error: \(error)")
            completion(false, "Login failed: \(error.localizedDescription)")
        }
    }

    func printAllUsers() {
        do {
            guard let db = db else {
                print("Database connection not available")
                return
            }

            let allUsers = try db.prepare(users)
            print("=== All Users in Database ===")
            var count = 0
            
            for user in allUsers {
                do {
                    let userName = try user.get(name)
                    let userEmail = try user.get(email)
                    print("User: \(userName), Email: \(userEmail)")
                    count += 1
                } catch {
                    print("Error reading user data: \(error)")
                }
            }
            
            print("Total users found: \(count)")
            print("============================")
        } catch {
            print("Error fetching all users: \(error)")
        }
    }
}
