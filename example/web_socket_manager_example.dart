import 'dart:async';

import 'package:web_socket_channel_manager/web_socket_manager.dart';

void main() async {
  // =============================
  // 1. Define WebSocket endpoint
  // =============================
  // This is the URL of the WebSocket server you want to connect to.
  // For demonstration, we use a public echo server that simply sends back any message you send.
  final wsUrl = 'wss://echo.websocket.events';

  // =====================================
  // 2. Create WebSocketManager instance
  // =====================================
  // WebSocketManager is implemented as a singleton, so you always get the same instance.
  final wsManager = WebSocketManager();

  // =====================================
  // 3. Define subscription and message
  // =====================================
  // sentRequest: a unique name for this subscription. You can use any string.
  // consent: the message you want to send to the WebSocket server.
  const sentRequest = 'echo_subscription';
  const consent = 'Hello WebSocket!';

  // =====================================================
  // 4. Initialize the WebSocket connection (connect once)
  // =====================================================
  // The first parameter is the WebSocket server URL.
  // The second parameter is for cookies (if your server requires authentication via cookies).
  // For most public servers, you can pass null for cookies.
  await wsManager.initWebSocket(wsUrl, null);

  try {
    // =====================================================
    // 5. Send a message to the WebSocket server
    // =====================================================
    // This sends the 'consent' string to the server. For an echo server, you'll get the same message back.
    wsManager.sendRequestData(consent);

    // =====================================================
    // 6. Subscribe to the WebSocket stream
    // =====================================================
    // This sets up listeners for messages, errors, completion, and timeouts.
    // Each callback is explained in detail below.
    try {
      wsManager.subscribe(
        sentRequest, // Unique name for this subscription. Used for managing multiple subscriptions.
        10, // Timeout in seconds. If no message is received in this time, onTimeOut is called.
        // =============================
        // Called when a message is received from the server.
        // 'response' contains the message data.
        // For an echo server, this will be the same as what you sent.
        // =============================
        onMessage: (response) async {
          print('Received: $response');
          // It's good practice to unsubscribe after receiving the expected message to avoid memory leaks.
          wsManager.unsubscribe(sentRequest);
        },
        // =============================
        // Called if an error occurs in the WebSocket stream.
        // 'error' contains error details.
        // =============================
        onError: (error) async {
          print('Error: $error');
          wsManager.unsubscribe(sentRequest);
        },
        // =============================
        // Called when the WebSocket stream is closed by the server or client.
        // =============================
        onDone: () async {
          print('WebSocket closed');
          wsManager.unsubscribe(sentRequest);
        },
        // =============================
        // Called if the subscription times out (no message received within the timeout period).
        // =============================
        onTimeOut: () {
          print('Subscription timed out');
          wsManager.unsubscribe(sentRequest);
        },
        // =============================
        // Called if the WebSocket session itself times out (e.g., server closes the connection).
        // =============================
        onSessionTimeOut: () {
          print('Session timed out');
          wsManager.unsubscribe(sentRequest);
        },
      );
    } catch (e) {
      // Handles errors that occur during subscription setup.
      print('Inner error: $e');
      wsManager.unsubscribe(sentRequest);
    }
  } catch (e) {
    // Handles errors that occur during sending or outer logic.
    print('Outer error: $e');
    wsManager.unsubscribe(sentRequest);
  }

  // =====================================================
  // 7. Wait for a short period to allow message exchange
  // =====================================================
  // This gives the server time to respond before closing the connection.
  await Future.delayed(Duration(seconds: 5));

  // =====================================================
  // 8. Close the WebSocket connection and clean up
  // =====================================================
  wsManager.closeWebSocket();
  print('WebSocket connection closed.');
}
