import 'dart:async';

import 'package:web_socket_channel/io.dart';

/// WebSocketManager is a singleton class that manages a single WebSocket connection
/// and allows multiple subscriptions to the incoming message stream.
///
/// Usage:
///   - Call [initWebSocket] once to establish a connection.
///   - Use [sendRequestData] to send messages.
///   - Use [subscribe] to listen for messages and handle events.
///   - Use [unsubscribe] to remove a subscription.
///   - Use [closeWebSocket] to close the connection and clean up.
class WebSocketManager {
  /// The underlying WebSocket channel (null if not connected)
  IOWebSocketChannel? _channel;

  /// Broadcast stream controller for incoming WebSocket messages
  StreamController<dynamic>? _streamController;

  /// Map of active subscriptions (by subscription name)
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Singleton instance
  static final WebSocketManager _instance = WebSocketManager._internal();

  /// Factory constructor returns the singleton instance
  factory WebSocketManager() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  WebSocketManager._internal();

  /// Initializes the WebSocket connection.
  ///
  /// [sokcketApi]: The WebSocket server URL (e.g., wss://example.com/ws)
  /// [socketCookie]: Optional cookies for authentication (can be null)
  ///
  /// Only the first call will establish the connection; subsequent calls are ignored if already connected.
  Future<void> initWebSocket(
    String? sokcketApi,
    String? socketCookie,
  ) async {
    if (_channel != null) {
      debugPrint("✅ WebSocket already initialized.");
      return;
    }

    try {
      // If cookies are provided, add them to the connection headers
      if (socketCookie != null && socketCookie.isNotEmpty) {
        _channel = IOWebSocketChannel.connect(Uri.parse(sokcketApi!), headers: {
          "Cookie": socketCookie,
        });
      } else {
        _channel = IOWebSocketChannel.connect(Uri.parse(sokcketApi!));
      }

      // Wait for the connection to be ready
      await _channel!.ready;
      debugPrint("🟢 WebSocket Connected!");

      // Use a broadcast stream so multiple listeners can subscribe
      _streamController = StreamController.broadcast();
      _streamController!.addStream(_channel!.stream);
    } catch (e, st) {
      debugPrint("❌ WebSocket Error: $e\nStacktrace: $st");
    }
  }

  /// Sends a message to the WebSocket server.
  ///
  /// [requestData]: The message to send (as a string)
  ///
  /// If the WebSocket is not initialized, this method does nothing.
  void sendRequestData(String requestData) {
    if (_channel == null) {
      debugPrint("⚠️ WebSocket not initialized. Call initWebSocket() first.");
      return;
    }
    _channel?.sink.add(requestData); // Send the message
    debugPrint("⚠️ WebSocket sendRequestData :: $requestData");
  }

  /// Subscribes to the WebSocket message stream with custom event handlers.
  ///
  /// [subscriptionName]: Unique name for this subscription (used for management)
  /// [timeout]: Optional timeout in seconds (default: 30s + 20s buffer)
  /// [onMessage]: Called when a message is received
  /// [onError]: Called if an error occurs
  /// [onDone]: Called when the stream is closed
  /// [onTimeOut]: Called if no message is received within the timeout
  /// [onSessionTimeOut]: Called if the WebSocket session times out (closeCode == 1005)
  ///
  /// If the WebSocket is not initialized, this method does nothing.
  void subscribe(String subscriptionName, int? timeout,
      {required Function(String? response) onMessage,
      required Function(String? error) onError,
      required Function() onDone,
      required Function() onTimeOut,
      required Function() onSessionTimeOut}) {
    if (_channel == null || _streamController == null) {
      debugPrint("⚠️ WebSocket not initialized. Call initWebSocket() first.");
      return;
    }

    // If the server closed the connection with code 1005, treat as session timeout
    if (_channel!.closeCode == 1005) {
      debugPrint("⚠️ WebSocket session timeout.");
      closeWebSocket();
      onSessionTimeOut();
      return;
    }

    // Start a timer to enforce a timeout for this subscription
    Timer timeoutTimer = Timer(Duration(seconds: (timeout ?? 30) + 20), () {
      WebSocketManager().unsubscribe(subscriptionName);
      onTimeOut();
    });

    // Prevent duplicate subscriptions with the same name
    if (_subscriptions.containsKey(subscriptionName)) {
      debugPrint("⚠️ Already subscribed to $subscriptionName.");
      return;
    }

    debugPrint(
      "📢 Subscribing to $subscriptionName... Listeners:  [33m [1m [4m [0m");

    // Listen to the broadcast stream for messages
    final subscription = _streamController!.stream.listen(
      (message) {
        timeoutTimer.cancel(); // Cancel the timer on message
        debugPrint("📌 [$subscriptionName] Message Received: $message");
        onMessage(message);
      },
      onError: (error) {
        timeoutTimer.cancel();
        debugPrint("❌ [$subscriptionName] Error: $error");
        onError(error);
      },
      onDone: () {
        timeoutTimer.cancel();
        debugPrint("🔻 [$subscriptionName] Stream closed.");
        onDone();
      },
    );

    // Store the subscription for later management
    _subscriptions[subscriptionName] = subscription;
  }

  /// Unsubscribes from a specific subscription by name.
  ///
  /// [subscriptionName]: The name of the subscription to cancel.
  ///
  /// If no such subscription exists, this method does nothing.
  void unsubscribe(String subscriptionName) {
    if (_subscriptions.containsKey(subscriptionName)) {
      _subscriptions[subscriptionName]?.cancel();
      _subscriptions.remove(subscriptionName);
      debugPrint("🔴 Unsubscribed from $subscriptionName.");
    } else {
      debugPrint("⚠️ No active subscription for $subscriptionName.");
    }
  }

  /// Cancels all active subscriptions.
  ///
  /// This is useful for cleanup before closing the WebSocket connection.
  Future clearAllSubscription() async {
    if (_subscriptions.isNotEmpty) {
      final keys = _subscriptions.keys.toList(); // Create a list of keys
      for (var key in keys) {
        unsubscribe(key);
      }
      _subscriptions.clear();
      debugPrint("🚪 All subscriptions closed.");
    }
  }

  /// Closes the WebSocket connection and all subscriptions.
  ///
  /// This should be called when you are done using the WebSocket to free resources.
  void closeWebSocket() {
    _subscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();

    _streamController?.close();
    _channel?.sink.close();
    _channel = null;
    debugPrint("🚪 WebSocket and all subscriptions closed.");
  }

  /// Prints debug messages only in debug mode (not in production).
  ///
  /// [message]: The message to print.
  void debugPrint(String message) {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

    if (isDebug) {
      print(message);
    }
  }
}
