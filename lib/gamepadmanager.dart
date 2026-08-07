import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

class Gamepadmanager with ChangeNotifier {
  StreamSubscription<GamepadEvent>? _subscription;

  final GamepadNormalizer _normalizer = GamepadNormalizer();

  //データ格納
  double _Lstick_X = 0.0;
  double get Lstick_X => _Lstick_X;
  double _Lstick_Y = 0.0;
  double get Lstick_Y => _Lstick_Y;
  double _Rstick_X = 0.0;
  double get Rstick_X => _Rstick_X;
  double _Rstick_Y = 0.0;
  double get Rstick_Y => _Rstick_Y;
  bool _A = false;
  bool get A => _A;
  bool _B = false;
  bool get B => _B;
  bool _X = false;
  bool get X => _X;
  bool _Y = false;
  bool get Y => _Y;
  bool _LeftBumper = false;
  bool get LeftBumper => LeftBumper;
  bool _RightBumper = false;
  bool get RightBumper => _RightBumper;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Gamepadmanager() {
    _startListening();
    checkGamepadConnection();
  }

  void _startListening(){
    _subscription = Gamepads.events.listen((event) {
      final normalized = _normalizer.normalize(event);

      if (normalized.isNotEmpty){
        for (final n in normalized){
          //処理スタート
          if (n.button != null){
            //ボタン
            if (n.button == GamepadButton.a){
              //aボタン
              if (n.value > 0.5){
                //押された
                _A = true;
              } else {
                //離された
                _A = false;
              }
            } else if (n.button == GamepadButton.b) {
              //bボタン
              if (n.value > 0.5){
                _B = true;
              } else {
                _B = false;
              }
            } else if (n.button == GamepadButton.x) {
              //xボタン
              if (n.value > 0.5) {
                _X = true;
              } else {
                _X = false;
              }
            } else if (n.button == GamepadButton.y){
              //yボタン
              if (n.value > 0.5){
                _Y = true;
              } else {
                _Y = false;
              }
            } else if (n.button == GamepadButton.leftBumper){
              if (n.value > 0.5){
                _LeftBumper = true;
              } else {
                _LeftBumper = false;
              }
            } else if (n.button == GamepadButton.rightBumper){
              if (n.value > 0.5){
                _RightBumper = true;
              } else {
                _RightBumper = false;
              }
            }
          } else if (n.axis != null) {
            //スティック・十字キー
            if (n.axis == GamepadAxis.leftStickX) _Lstick_X = n.value;
            if (n.axis == GamepadAxis.leftStickY) _Lstick_Y = n.value;
            if (n.axis == GamepadAxis.rightStickX) _Rstick_X = n.value;
            if (n.axis == GamepadAxis.rightStickY) _Rstick_Y = n.value;
          }
        }
        notifyListeners();
      }
    });
  }

  void disconnect(){
    _subscription?.cancel();
  }

  /** つながっているかを把握 */
  Future<bool> checkGamepadConnection() async{
    List<GamepadController> usbDevices = await Gamepads.list();

    _isConnected = usbDevices.isNotEmpty;

    return _isConnected;
  } 
}