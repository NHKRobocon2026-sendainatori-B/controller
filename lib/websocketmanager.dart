import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Websocketmanager {
  WebSocketChannel? channel;
  Function? ShutDown_Success;
  bool get isConnected => channel != null;

  void connect(String ipAddress) {
    if(channel != null) return;
    try{
      final uri = Uri.parse('ws://$ipAddress:9090');
      channel = IOWebSocketChannel.connect(uri);
      //最初にsendしてsubscrideしよう
      /*
      send({
        'op': 'subscribe',
        'topic': '/shutdown_result',
        'type': 'std_msgs/msg/Bool',
      });
      */

      /**
       * 情報を受け取ったときの動き
       */
      channel!.stream.listen((message){
        final decoded = jsonDecode(message);
        //ここからどんな情報なのかをチェック
        /*
        if(decoded['op'] == 'publish' && decoded['topic'] == '/shutdown_result'){
          final bool isError = decoded['msg']['data'];
          print('Shutdown Result: ${isError ? 'Error' : 'Success'}');

          if(isError == false){
            if(ShutDown_Success != null) ShutDown_Success!();
            disconnect();
          }else{
            print("ShutDown Error!!");
          }
        }
        */
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
}