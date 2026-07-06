import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';
import 'gamepadmanager.dart';

class Controller extends StatefulWidget {
  final PageController pageController;
  Controller({super.key, required this.pageController});

  @override
  State<Controller> createState() => ControllerPage();
}

class ControllerPage extends State<Controller> {
  Timer? _timer;

  void _startTimer(){
    /*
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      send_steering();
    });
    */
  }

  void send_steering(){
    final wsManager = context.read<Websocketmanager>();
    final gmManager = context.read<Gamepadmanager>();
    if (!wsManager.isConnected) return;
    if (!gmManager.isConnected) return;

    Map<String, dynamic> data = {
      "op" : "publish",
      "topic" : "/cmd_vel",
      "type" : "geometry_msgs/Twist",
      "msg" : {
        "linear" : {
          "x": gmManager.Lstick_X,
          "y": gmManager.Lstick_Y,
          "z": 0,
        },
        "angular": {
          "x": 0,
          "y": 0,
          "z": gmManager.Rstick_X,
        }
      }
    };
    wsManager.send(data);
  }

  @override
  void initState(){
    super.initState();
    //_startTimer();

    //始まったときの処理
  }

  @override
  Widget build(BuildContext context) {
    final gamepad = context.watch<Gamepadmanager>();
    
    return Scaffold(
      body: Center(
        //なんかつけるか
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Connected:${gamepad.isConnected}"),
            Text("A:${gamepad.A}"),
            Text("B:${gamepad.B}"),
            Text("X:${gamepad.X}"),
            Text("Y:${gamepad.Y}"),
            Text("LS_X:${gamepad.Lstick_X.toStringAsFixed(2)}"),
            Text("LS_Y:${gamepad.Lstick_Y.toStringAsFixed(2)}"),
            Text("RS_X:${gamepad.Rstick_X.toStringAsFixed(2)}"),
            Text("RS_Y:${gamepad.Rstick_Y.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}