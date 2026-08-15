import 'dart:async';
import 'dart:nativewrappers/_internal/vm/bin/common_patch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
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

  bool shooter = false;
  bool shooterProblem = false;
  bool loaderProblem = false;
  bool auto = false;
  bool autoProblem = false;
  bool slow = false;
  bool lock = false;
  bool lockProblem = false;

  //service通信用フラッグ
  bool _wasBPressed = false;
  bool _isShooting = false;
  bool _wasAPressed = false;
  bool _isLoading = false;
  bool _wasYPressed = false;
  bool _isAuto = false;
  bool _wasBumperPressed = false;
  bool _isLock = false;

  void _startTimer(){
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      send_steering();
    });
  }

  void send_steering(){
    final wsManager = context.read<Websocketmanager>();
    final gmManager = context.read<Gamepadmanager>();
    if (!wsManager.isConnected) return;
    if (!gmManager.isConnected) return;

    Map<String, dynamic> data = {
      "op" : "publish",
      "topic" : "/steer_flutter",
      "type" : "sensor_msgs/msg/Joy",
      "msg" : {
        "header": {},
        "axes": [
          (slow) ? gmManager.Lstick_X / 3 : gmManager.Lstick_X, // axes[0]
          (slow) ? gmManager.Lstick_Y / 3 : gmManager.Lstick_Y, // axes[1]
          (slow) ? gmManager.Rstick_X / 3 : gmManager.Rstick_X, // axes[2]
          (slow) ? gmManager.Rstick_Y / 3 : gmManager.Rstick_Y  // axes[3]
        ],
        "buttons": []
      }
    };
    wsManager.send(data);
  }

  Future<void> _requestShooter() async {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;
    if (_isShooting) return; // 通信中は重複送信しない
    _isShooting = true;

    final response = await wsManager.sendService(
      service: "/shooter_service", 
      type:'example_interfaces/srv/SetBool',
      args: {"data" : !shooter}
    );

    if (response['success'] == true){
      setState(() {
        shooter = !shooter; //ここで描画が変化される？まだ用意してないけど
        shooterProblem = true;
      });
    } else {
      setState(() {
        shooterProblem = false;
      });
    }

    _isShooting = false;
  }

  Future<void> _requestLoader() async {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;
    if (_isLoading) return; // 通信中は重複送信しない
    _isLoading = true;

    final response = await wsManager.sendService(
      service: '/loader_service', 
      type: 'example_interfaces/srv/Trigger'
    );

    if (response['success'] == true) {
      setState(() {
        loaderProblem = false;
      }); 
    } else {
      setState(() {
        loaderProblem = true;
      }); 
    }

    _isLoading = false;
  }

  Future<void> _requestAUTO() async {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;
    if (_isAuto) return; // 通信中は重複送信しない
    _isAuto = true;

    final respose = await wsManager.sendService(
      service: "/set_goal", 
      type: "example_interfaces/srv/SetBool",
      args: { "data" : !auto }
    );

    if (respose['success'] == true){
      setState(() {
        auto = !auto;
        autoProblem = false;
      });
    } else {
      setState(() {
        autoProblem = true;
      });
    }

    _isAuto = false;
  }

  Future<void> _requestLock() async {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;
    if (!_isLock) return;
    _isLock = true;

    final response = await wsManager.sendService(
      service: "/lock_service", 
      type: "example_interfaces/srv/SetBool",
      args: {"data" : !lock}
    );

    if (response['success'] == true){
      setState(() {
        lock = !lock;
        lockProblem = false;
      });
    } else {
      setState(() {
        lockProblem = true;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    _startTimer();

    //始まったときの処理
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamepad = context.watch<Gamepadmanager>();
    final bPressed = context.select<Gamepadmanager, bool>((m) => m.B);
    final aPressed = context.select<Gamepadmanager, bool>((m) => m.A);
    final yPressed = context.select<Gamepadmanager, bool>((m) => m.Y);
    final blPressed = context.select<Gamepadmanager, bool>((m) => m.LeftBumper);
    final brPressed = context.select<Gamepadmanager, bool>((m) => m.RightBumper);
    final isRedCorner = context.watch<Websocketmanager>().corner;

    if (bPressed && !_wasBPressed) {
      _wasBPressed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestShooter();
      });
    } else if (!bPressed && _wasBPressed) {
      _wasBPressed = false; // ボタンが離されたらリセット
    }

    if (aPressed && !_wasAPressed) {
      _wasAPressed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestLoader();
      });
    } else if (!aPressed && _wasAPressed) {
      _wasAPressed = false; // ボタンが離されたらリセット
    }

    if (yPressed && !_wasYPressed) {
      _wasYPressed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestAUTO();
      });
    } else if (!yPressed && _wasYPressed) {
      _wasYPressed = false; // ボタンが離されたらリセット
    }

    if (blPressed || brPressed && !_wasBumperPressed){
      _wasBumperPressed = true;
      WidgetsBinding.instance.addPostFrameCallback((_){
        slow = true;
      });
    } else if (!blPressed && !brPressed && _wasBumperPressed){
      _wasBumperPressed = false;
      WidgetsBinding.instance.addPostFrameCallback((_){
        slow = false;
      });
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 30,
              color: (isRedCorner) ? Colors.red : Colors.blue,
              child: Text((isRedCorner) ? "赤コーナー" : "青コーナー"),
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //何らかのなんか,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "AUTO:  ",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                          children: <TextSpan>[
                            TextSpan(
                              text: (auto) ? "ON" : "OFF",
                              style: TextStyle(fontSize: 20, color: (auto) ? Colors.red : Colors.black)
                            )
                          ]
                        )
                      ),
                      RichText(
                        text: TextSpan(
                          text: "SLOW:  ",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                          children: <TextSpan>[
                            TextSpan(
                              text: (slow) ? "ON" : "OFF",
                              style: TextStyle(fontSize: 20, color: (auto) ? Colors.red : Colors.black)
                            )
                          ]
                        )
                      ),
                      
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}