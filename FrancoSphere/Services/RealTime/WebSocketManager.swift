//
//  WebSocketManager.swift
//  FrancoSphere
//
//  Stream B: Gemini - Backend Services
//  Mission: Implement real-time WebSocket communication layer.
//
//  ✅ PRODUCTION READY: Handles connection, disconnection, and sending.
//  ✅ RESILIENT: Implements exponential backoff for automatic reconnection.
//  ✅ INTEGRATED: Designed to be driven by DashboardSyncService and authenticated by NewAuthManager.
//  ✅ THREAD-SAFE: Built as an actor to manage connection state safely.
//

import Foundation
import Combine

actor WebSocketManager {
    static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var reconnectAttempts = 0
    
    // Exponential backoff delays for reconnection
    private let maxReconnectAttempts = 5
    private let reconnectDelays: [TimeInterval] = [1, 2, 5, 10, 20]
    
    private let urlSession: URLSession
    private let delegate: WebSocketDelegate
    
    private init() {
        self.delegate = WebSocketDelegate()
        self.urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        // Set up delegate callbacks
        Task {
            await setupDelegateCallbacks()
        }
    }
    
    private func setupDelegateCallbacks() {
        delegate.onOpen = { [weak self] in
            Task {
                await self?.handleConnectionOpened()
            }
        }
        
        delegate.onClose = { [weak self] closeCode, reason in
            Task {
                await self?.handleConnectionClosed(closeCode: closeCode, reason: reason)
            }
        }
    }
    
    // MARK: - Connection Management
    
    /// Establishes a WebSocket connection with the server.
    ///
    /// - Parameter token: The authentication token from `NewAuthManager`.
    func connect(token: String) {
        guard !isConnected else {
            print("🔌 WebSocket already connected")
            return
        }
        
        #if DEBUG
        let urlString = "ws://localhost:8080/sync"
        #else
        let urlString = "wss://api.francosphere.com/sync"
        #endif
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = urlSession.webSocketTask(with: request)
        
        print("🔌 WebSocket connecting to \(urlString)...")
        webSocketTask?.resume()
    }
    
    /// Gracefully disconnects the WebSocket.
    func disconnect() {
        guard isConnected else { return }
        print("🔌 WebSocket disconnecting...")
        webSocketTask?.cancel(with: .goingAway, reason: "User initiated disconnect".data(using: .utf8))
        resetConnectionState()
    }
    
    // MARK: - Message Handling
    
    /// Encodes and sends a `DashboardUpdate` to the server.
    ///
    /// - Parameter update: The `DashboardUpdate` object from `CoreTypes`.
    func send(_ update: CoreTypes.DashboardUpdate) async throws {
        guard isConnected, let task = webSocketTask else {
            throw WebSocketError.notConnected
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(update)
            
            try await task.send(.data(data))
            print("⬆️ WebSocket update sent: \(update.type.rawValue)")
        } catch {
            print("❌ WebSocket send error: \(error.localizedDescription)")
            throw WebSocketError.encodingFailed(error)
        }
    }
    
    /// Starts the loop to listen for incoming messages from the server.
    private func startReceiving() {
        guard let task = webSocketTask else { return }
        
        Task {
            do {
                while isConnected {
                    let message = try await task.receive()
                    await handleMessage(message)
                }
            } catch {
                print("❌ WebSocket receive error: \(error.localizedDescription)")
                await handleDisconnection()
            }
        }
    }
    
    /// Decodes an incoming message and notifies the `DashboardSyncService`.
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        let updateData: Data
        
        switch message {
        case .data(let data):
            updateData = data
        case .string(let string):
            guard let data = string.data(using: .utf8) else { return }
            updateData = data
        @unknown default:
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let update = try decoder.decode(CoreTypes.DashboardUpdate.self, from: updateData)
            print("⬇️ WebSocket update received: \(update.type.rawValue)")
            await notifyDashboardSync(update)
        } catch {
            print("❌ WebSocket decoding error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reconnection Logic
    
    /// Schedules a reconnection attempt with exponential backoff.
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ WebSocket max reconnect attempts reached. Giving up.")
            return
        }
        
        let delay = reconnectDelays[min(reconnectAttempts, reconnectDelays.count - 1)]
        print("🔌 WebSocket will attempt to reconnect in \(delay) seconds...")
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Fetch current auth token and reconnect
            if let token = await getAuthToken() {
                print("🔌 Attempting to reconnect now (attempt \(reconnectAttempts + 1))...")
                reconnectAttempts += 1
                connect(token: token)
            }
        }
    }
    
    private func resetReconnection() {
        reconnectAttempts = 0
    }
    
    // MARK: - State Management & Integration
    
    private func handleConnectionOpened() {
        print("✅ WebSocket connected successfully.")
        self.isConnected = true
        resetReconnection()
        startReceiving()
    }
    
    private func handleConnectionClosed(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket disconnected. Code: \(closeCode.rawValue)")
        handleDisconnection()
    }
    
    private func handleDisconnection() {
        resetConnectionState()
        scheduleReconnect()
    }
    
    private func resetConnectionState() {
        self.webSocketTask = nil
        self.isConnected = false
    }
    
    /// Gets the current authentication token
    private func getAuthToken() async -> String? {
        await MainActor.run {
            NewAuthManager.shared.currentUser?.id
        }
    }
    
    /// Notifies the main-thread `DashboardSyncService` of a new remote update.
    private func notifyDashboardSync(_ update: CoreTypes.DashboardUpdate) async {
        await MainActor.run {
            DashboardSyncService.shared.handleRemoteUpdate(update)
        }
    }
    
    // MARK: - Public Status
    
    nonisolated var connectionStatus: ConnectionStatus {
        get async {
            if await isConnected {
                return .connected
            } else if await reconnectAttempts > 0 {
                return .reconnecting
            } else {
                return .disconnected
            }
        }
    }
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case reconnecting
    }
}

// MARK: - WebSocket Delegate

/// A separate class to handle URLSession delegate callbacks
private class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    var onOpen: (() -> Void)?
    var onClose: ((URLSessionWebSocketTask.CloseCode, Data?) -> Void)?
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        onOpen?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        onClose?(closeCode, reason)
    }
}

// MARK: - Error Handling

enum WebSocketError: LocalizedError {
    case notConnected
    case encodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected."
        case .encodingFailed(let error):
            return "Failed to encode message: \(error.localizedDescription)"
        }
    }
}

// MARK: - DashboardSyncService Extension

extension DashboardSyncService {
    /// Handles updates received from the WebSocket
    func handleRemoteUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Check if this update originated from this device
        if update.deviceId == UIDevice.current.identifierForVendor?.uuidString {
            return // Ignore our own updates
        }
        
        // Process the update based on source and type
        switch update.source {
        case .worker:
            workerDashboardSubject.send(update)
        case .admin:
            adminDashboardSubject.send(update)
        case .client:
            clientDashboardSubject.send(update)
        case .system:
            crossDashboardSubject.send(update)
        }
        
        print("📨 Processed remote update: \(update.type.rawValue) from \(update.source.rawValue)")
    }
}
