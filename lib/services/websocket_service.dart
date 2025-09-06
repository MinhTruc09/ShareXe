import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../utils/app_config.dart';

class WebSocketService {
  final AppConfig _appConfig = AppConfig();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _currentToken;
  String? _currentUserEmail;
  Timer? _heartbeatTimer;
  
  // Callbacks for different message types
  Function(ChatMessage)? onChatMessageReceived;
  Function(Map<String, dynamic>)? onTrackingDataReceived;
  Function(String)? onConnectionStatusChanged;

  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<void> initialize(String baseUrl, String token, String userEmail) async {
    _currentToken = token;
    _currentUserEmail = userEmail;
    
    if (_channel != null) {
      await disconnect();
    }

    try {
      print('🔌 Initializing WebSocket connection...');
      print('Base URL: $baseUrl');
      print('User Email: $userEmail');

      // Convert http to ws
      final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final fullUrl = '$wsUrl/ws?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(fullUrl));

      // Listen to messages
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print("❌ WebSocket Error: $error");
          _isConnected = false;
          onConnectionStatusChanged?.call('error');
        },
        onDone: () {
          print("🔌 WebSocket disconnected");
          _isConnected = false;
          onConnectionStatusChanged?.call('disconnected');
        },
      );

      _isConnected = true;
      onConnectionStatusChanged?.call('connected');
      
      // Start heartbeat
      _startHeartbeat();

      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
      _isConnected = false;
      onConnectionStatusChanged?.call('error');
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final messageType = message['type'] as String?;
      
      switch (messageType) {
        case 'chat':
          final chatMessage = ChatMessage.fromJson(message['data']);
          print('📨 Received chat message: ${chatMessage.content}');
          onChatMessageReceived?.call(chatMessage);
          break;
        case 'tracking':
          final trackingData = message['data'] as Map<String, dynamic>;
          print('📍 Received tracking data: ${trackingData['lat']}, ${trackingData['lng']}');
          onTrackingDataReceived?.call(trackingData);
          break;
        default:
          print('📨 Received unknown message type: $messageType');
      }
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  // Connect to chat room
  Future<void> connectForChat(String roomId) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected. Call initialize() first.');
    }

    try {
      print('🔌 Subscribing to chat room: $roomId');

      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'topic': 'chat',
        'roomId': roomId,
      }));

      print('✅ Successfully subscribed to chat room: $roomId');
    } catch (e) {
      print('❌ Error subscribing to chat room: $e');
      rethrow;
    }
  }

  // Send chat message via WebSocket
  Future<void> sendChatMessage(String roomId, String receiverEmail, String content) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    try {
      print('📤 Sending chat message to room: $roomId');

      final message = ChatMessage(
        roomId: roomId,
        senderEmail: _currentUserEmail,
        receiverEmail: receiverEmail,
        content: content,
        timestamp: DateTime.now(),
        read: false,
        status: 'sending',
      );

      _channel!.sink.add(jsonEncode({
        'type': 'chat',
        'roomId': roomId,
        'data': message.toJson(),
        'token': _currentToken,
      }));

      print('✅ Chat message sent successfully');
    } catch (e) {
      print('❌ Error sending chat message: $e');
      rethrow;
    }
  }

  // Connect to tracking for a ride
  Future<void> connectForTracking(String rideId) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected. Call initialize() first.');
    }

    try {
      print('🔌 Subscribing to tracking for ride: $rideId');

      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'topic': 'tracking',
        'rideId': rideId,
      }));

      print('✅ Successfully subscribed to tracking for ride: $rideId');
    } catch (e) {
      print('❌ Error subscribing to tracking: $e');
      rethrow;
    }
  }

  // Send tracking data (for drivers)
  Future<void> sendTrackingData(String rideId, double latitude, double longitude, {double? speed}) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    try {
      print('📍 Sending tracking data for ride: $rideId');

      final trackingData = {
        'rideId': rideId,
        'driverEmail': _currentUserEmail,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        if (speed != null) 'speed': speed,
      };

      _channel!.sink.add(jsonEncode({
        'type': 'tracking',
        'rideId': rideId,
        'data': trackingData,
      }));

      print('✅ Tracking data sent successfully');
    } catch (e) {
      print('❌ Error sending tracking data: $e');
      rethrow;
    }
  }

  // Disconnect WebSocket
  Future<void> disconnect() async {
    if (_channel != null) {
      print('🔌 Disconnecting WebSocket...');
      _heartbeatTimer?.cancel();
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      onConnectionStatusChanged?.call('disconnected');
    }
  }

  // Check connection and reconnect if needed
  Future<void> ensureConnection() async {
    if (!_isConnected && _currentToken != null && _currentUserEmail != null) {
      print('🔄 Attempting to reconnect WebSocket...');
      await initialize(_appConfig.getBaseUrl(), _currentToken!, _currentUserEmail!);
    }
  }

  // Legacy method for backward compatibility
  Future<void> connectForChatLegacy(
    String roomId,
    Function(ChatMessage) onMessage,
  ) async {
    onChatMessageReceived = onMessage;
    await connectForChat(roomId);
  }

  // Legacy method for backward compatibility
  Future<void> sendMessage(String roomId, ChatMessage message) async {
    await sendChatMessage(
      roomId,
      message.receiverEmail ?? '',
      message.content ?? '',
    );
  }
}