# Flutter Example for web_socket_manager

This example demonstrates how to use the `web_socket_manager` package in a Flutter app.

## How to Run

1. Navigate to the `example` directory:
   ```sh
   cd example
   ```
2. Get dependencies:
   ```sh
   flutter pub get
   ```
3. Run the example app:
   ```sh
   flutter run -d <device_id>
   ```
   Replace `<device_id>` with your emulator or device ID.

## What the Example Does

- Shows a single button labeled **Start socket** in the center of the screen.
- When pressed, it:
  - Connects to a public WebSocket echo server (`wss://echo.websocket.events`).
  - Sends a message (`Hello WebSocket!`).
  - Listens for the response and prints it to the console.
  - Closes the connection after a short delay.

## Example Code

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web_socket_channel_manager/web_socket_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WebSocket Manager Example'),
        ),
        body: const Center(
          child: StartSocketButton(),
        ),
      ),
    );
  }
}

class StartSocketButton extends StatelessWidget {
  const StartSocketButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        initSocket();
      },
      child: const Text('Start socket'),
    );
  }

  void initSocket() async {
    final wsUrl = 'wss://echo.websocket.events';
    final wsManager = WebSocketManager();
    const sentRequest = 'echo_subscription';
    const consent = 'Hello WebSocket!';
    await wsManager.initWebSocket(wsUrl, null);
    try {
      wsManager.sendRequestData(consent);
      try {
        wsManager.subscribe(
          sentRequest,
          10,
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
        print('Inner error: $e');
        wsManager.unsubscribe(sentRequest);
      }
    } catch (e) {
      print('Outer error: $e');
      wsManager.unsubscribe(sentRequest);
    }
    await Future.delayed(Duration(seconds: 5));
    wsManager.closeWebSocket();
    print('WebSocket connection closed.');
  }
}
```

Check the debug console for WebSocket connection and message logs.
