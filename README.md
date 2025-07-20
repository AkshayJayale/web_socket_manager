# web_socket_manager

A Dart package for managing WebSocket connections with ease. This package provides a singleton WebSocket manager that supports connection initialization, message sending, multiple subscriptions, automatic timeout handling, and clean resource management. Ideal for Dart and Flutter projects that require robust WebSocket communication.

## Features

- Singleton WebSocket connection management
- Easy initialization and cleanup
- Send messages to the WebSocket server
- Subscribe to incoming messages with custom handlers
- Automatic timeout and session management
- Multiple named subscriptions
- Clean unsubscription and resource release
- Debug logging (only in debug mode)

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  web_socket_manager: 1.0.0
```

Import the package in your Dart or Flutter project:

```dart
import 'package:web_socket_manager/web_socket_manager.dart';
```

## Usage

Here's a complete example demonstrating how to use the package to connect to a WebSocket server, send a message, subscribe to responses, and handle cleanup:

```dart
import 'package:web_socket_manager/web_socket_manager.dart';
import 'dart:async';

void main() async {
  // 1. Define the WebSocket server URL
  final wsUrl = 'wss://echo.websocket.events'; // Public echo server for demo

  // 2. Create the WebSocketManager instance (singleton)
  final wsManager = WebSocketManager();

  // 3. Define a unique subscription name and the message to send
  const sentRequest = 'echo_subscription';
  const consent = 'Hello WebSocket!';

  // 4. Initialize the WebSocket connection
  await wsManager.initWebSocket(wsUrl, null); // Pass cookies if needed, else null

  try {
    // 5. Send a message to the server
    wsManager.sendRequestData(consent);

    // 6. Subscribe to the WebSocket stream
    wsManager.subscribe(
      sentRequest, // Unique subscription name
      10, // Timeout in seconds
      onMessage: (response) async {
        print('Received: $response');
        wsManager.unsubscribe(sentRequest);
      },
      onError: (error) async {
        print('Error: $error');
        wsManager.unsubscribe(sentRequest);
      },
      onDone: () async {
        print('WebSocket closed');
        wsManager.unsubscribe(sentRequest);
      },
      onTimeOut: () {
        print('Subscription timed out');
        wsManager.unsubscribe(sentRequest);
      },
      onSessionTimeOut: () {
        print('Session timed out');
        wsManager.unsubscribe(sentRequest);
      },
    );
  } catch (e) {
    print('Error: $e');
    wsManager.unsubscribe(sentRequest);
  }

  // Wait a bit to allow for message exchange
  await Future.delayed(Duration(seconds: 5));
  wsManager.closeWebSocket();
  print('WebSocket connection closed.');
}
```

## API Overview

- `initWebSocket(String url, String? cookie)`: Initializes the WebSocket connection. Call once before sending or subscribing.
- `sendRequestData(String data)`: Sends a message to the server.
- `subscribe(String name, int? timeout, {onMessage, onError, onDone, onTimeOut, onSessionTimeOut})`: Subscribes to the message stream with custom handlers.
- `unsubscribe(String name)`: Cancels a specific subscription.
- `clearAllSubscription()`: Cancels all active subscriptions.
- `closeWebSocket()`: Closes the connection and cleans up resources.

## Additional information

- The package is suitable for both Dart and Flutter projects.
- Only one WebSocket connection is managed at a time (singleton pattern).
- Debug logs are printed only in debug mode.
- For advanced usage, see the detailed example in `/example/web_socket_manager_example.dart`.
- Contributions, issues, and suggestions are welcome!

---

For more information, see the source code and examples in this repository. If you encounter issues or have feature requests, please open an issue or submit a pull request.
