import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Websocketmanager {
  WebSocketChannel? channel;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  bool get isConnected => channel != null;

  void connect(String ipAddress) {
    if(channel != null) return;
    try{
      final uri = Uri.parse('ws://$ipAddress:9090');
      channel = IOWebSocketChannel.connect(uri);
      //最初にsendしてsubscrideしよう
      send({
        'op': 'subscribe',
        'topic': '/shutdown_result',
        'type': 'std_msgs/msg/Bool',
      });

      /**
       * 情報を受け取ったときの動き
       */
      channel!.stream.listen((message){
        _handleIncomingMessage(message);
      });
    }catch(e){
      print("Connect Error!!");
    }
  }

  void disconnect(){
    if(channel != null){
      channel!.sink.close();
      channel = null;
    }
  }

  void send(Map<String, dynamic> data){
    if (channel == null) {
      print("Send failed: Not connected");
      return;
    }
    channel!.sink.add(jsonEncode(data));
  }
  
  void _handleIncomingMessage(String message) {
    final decoded = jsonDecode(message);

    if (decoded['op'] == 'service_response') {
      final String requestId = decoded['id'];

      // 💡 送信時に記録したIDが存在するかチェック
      if (_pendingRequests.containsKey(requestId)) {
        // マップから取り出して削除
        final completer = _pendingRequests.remove(requestId);
        // 待機していた Future に ROS 2 の返り値を渡して完了させる
        completer?.complete(decoded['values'] ?? {});
      }
    }
  }

  Future<Map<String, dynamic>> sendService(
    {required String service,
    required String type,
    Map<String, dynamic>? args}) async {
    final requestId = "req_${DateTime.now().microsecondsSinceEpoch}";
    final completer = Completer<Map<String, dynamic>>();

    // IDとCompleterを記録
    _pendingRequests[requestId] = completer;

    send({
      'op': 'call_service',
      'service': service,
      'type': type,
      'args': args ?? {},
      'id': requestId,
    });

    return completer.future;
  }
}