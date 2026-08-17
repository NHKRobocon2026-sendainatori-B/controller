import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';
import 'gamepadmanager.dart';
import 'CustomPainter.dart';

enum SetZeroState { 
  ready, 
  running, 
  error;
}

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
  SetZeroState setZeroState = SetZeroState.ready;

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

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final wsManager = context.read<Websocketmanager>();

      wsManager.setZeroResult = (bool success) {
        if (mounted) return;
        setZeroState = (success) ? SetZeroState.ready : SetZeroState.error;
      };
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _SetzeroString {
    return switch(setZeroState){
      SetZeroState.ready => '完了',
      SetZeroState.running => '準備中',
      SetZeroState.error => 'エラー',
    };
  }

  Color get _SetzeroColor {
    return switch (setZeroState) {
      SetZeroState.ready => Colors.blue,
      SetZeroState.running => Colors.orange,
      SetZeroState.error => Colors.red,
    };
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
    final robotX = context.select<Websocketmanager, double>((m) => m.robotX);
    final robotY = context.select<Websocketmanager, double>((m) => m.robotY);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 10,
            ),
            Container(
              height: 30,
              width: double.infinity,
              color: (isRedCorner) ? Colors.red : Colors.blue,
              child: Text((isRedCorner) ? "赤コーナー" : "青コーナー"),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.asset(
                              '',//imgファイルを入れよう
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.fill,
                            ),

                            Positioned.fill(
                              child: CustomPaint(
                                painter: RobotMapPainter(
                                  robotX: robotX, 
                                  robotY: robotY
                                ),
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
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
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: (isRedCorner) ? Colors.red : Colors.blue,
                                width: 1
                              ),
                              borderRadius: BorderRadiusGeometry.circular(8)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: "足回り:  ",
                                      style: TextStyle(color: Colors.black, fontSize: 20),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: _SetzeroString,
                                          style:  TextStyle(fontSize: 20, color: _SetzeroColor)
                                        )
                                      ]
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: "射出:  ",
                                      style: TextStyle(color: Colors.black, fontSize: 20),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: (shooterProblem) ? "問題発生!!" : "問題なし",
                                          style: TextStyle(fontSize: 20, color: (shooterProblem) ? Colors.red : Colors.blue)
                                        )
                                      ]
                                    )
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: "装填:  ",
                                      style: TextStyle(color: Colors.black, fontSize: 20),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: (loaderProblem) ? "問題発生!!" : "問題なし",
                                          style: TextStyle(fontSize: 20, color: (loaderProblem) ? Colors.red : Colors.blue)
                                        )
                                      ]
                                    )
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: "自動操縦:  ",
                                      style: TextStyle(color: Colors.black, fontSize: 20),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: (autoProblem) ? "問題発生!!" : "問題なし",
                                          style: TextStyle(fontSize: 20, color: (autoProblem) ? Colors.red : Colors.blue)
                                        )
                                      ]
                                    )
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: "非常停止:  ",
                                      style: TextStyle(color: Colors.black, fontSize: 20),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: (lockProblem) ? "問題発生!!" : "問題なし",
                                          style: TextStyle(fontSize: 20, color: (lockProblem) ? Colors.red : Colors.blue)
                                        )
                                      ]
                                    )
                                  ),
                                ],
                              ),
                            )
                          )
                        ),
                      ],
                    )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}