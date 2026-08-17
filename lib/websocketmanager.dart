import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Websocketmanager with ChangeNotifier {
  WebSocketChannel? channel;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  bool get isConnected => channel != null;
  bool corner = false;
  double robotX = 0;
  double robotY = 0;
  Function? setZeroResult;

  void setCorner(bool isRed) {
    corner = isRed;
    notifyListeners();
  }

  void connect(String ipAddress) {
    if(channel != null) return;
    try{
      final uri = Uri.parse('ws://$ipAddress:9090');
      channel = IOWebSocketChannel.connect(uri);
      //最初にsendしてsubscrideしよう
      send({
        'op': 'subscribe',
        'topic': '/amcl_pose',
        'type': 'geometry_msgs/msg/PoseWithCovarianceStamped',
      });

      send({
        'op': 'subscribe',
        'topic': '/setZero_success',
        'type': 'std_msgs/msg/Bool',
      });

      notifyListeners();

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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect(); // 切断を実行
    super.dispose();
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

    if (decoded['op'] == 'publish') {
      //ros2からのデータ
      if (decoded['topic'] == '/setZero_success'){
        //setZeroの設定
        final bool error = decoded['msg']['data'];
        if (setZeroResult == null) return;
        setZeroResult!(error);
      }
      if (decoded['topic'] == '/amcl_pose') {
        //自己位置
        robotX = decoded['msg']['pose']['pose']['pose']['position']['x'];
        robotY = decoded['msg']['pose']['pose']['pose']['position']['y'];
        notifyListeners();
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