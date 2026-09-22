import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';
import 'gamepadmanager.dart';

class Check extends StatefulWidget {
  final PageController pageController;
  Check({super.key, required this.pageController});

  @override
  State<Check> createState() => CheckPage();
}

class CheckPage extends State<Check> {
  Timer? _timer;

  //それぞれとつながっているか
  bool gamepad = false;
  bool rasberrypi = false;
  bool stm32 = false;

  String state = "";

  void _StartTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _requestCheck();
    });
  }

  Future<void> _requestCheck() async {
    final wsManager = context.read<Websocketmanager>();
    final gmManager = context.read<Gamepadmanager>();
  
    bool isGamepad = gmManager.isConnected;
    bool isRasPi = false;
    bool isStm32 = false;
    String newState = "";

    if (!wsManager.isConnected) {
      isRasPi = false;
      newState = "E: don't connected rasberrypi";
    } else {
      try {
        final response = await wsManager.sendService(
          service: "/check", 
          type: 'example_interfaces/srv/Trigger',
          timeout: const Duration(seconds: 3)
        );
        if (response['success'] == true) {
          isRasPi = true;

          final msg = response['message']?.toString();
          if (msg == "STM32_OK") {
            isStm32 = true;
            newState = "No Problem!!";
          } else {
            isStm32 = false;
            newState = "Timeout: stm32";
          }
        } else {
          isRasPi = false;
          newState = "Recieve failure";
        }
      } on TimeoutException {
        isRasPi = false;
        newState = "Timeout: RasberryPi";
      }
    }

    if (!mounted) return;

    setState(() {
      gamepad = isGamepad;
      rasberrypi = isRasPi;
      stm32 = isStm32;
      state = newState;
    });
  }

  @override
  void initState() {
    super.initState();
    _requestCheck();
    _StartTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsManager = context.read<Websocketmanager>();

    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 50,
            ),
            Container(
              height: 50,
              width: double.infinity,
              color: Colors.purple,
              child: Center(
                child: Text(
                  "接続チェック画面",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.lightBlue,
                    width: 1
                  ),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "Gamepad:  ",
                          style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold,),
                            children: <TextSpan>[
                              TextSpan(
                              text: (gamepad) ? "SUCCESS" : "FAILED",
                              style: TextStyle(fontSize: 30, color: (gamepad) ? Colors.lightGreen : Colors.red)
                            )
                          ]
                        )
                      ),
                      RichText(
                        text: TextSpan(
                          text: "RasPi:  ",
                          style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold,),
                            children: <TextSpan>[
                              TextSpan(
                              text: (rasberrypi) ? "SUCCESS" : "FAILED",
                              style: TextStyle(fontSize: 30, color: (rasberrypi) ? Colors.lightGreen : Colors.red)
                            )
                          ]
                        )
                      ),
                      RichText(
                        text: TextSpan(
                          text: "Stm32:  ",
                          style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold,),
                            children: <TextSpan>[
                              TextSpan(
                              text: (stm32) ? "SUCCESS" : "FAILED",
                              style: TextStyle(fontSize: 30, color: (stm32) ? Colors.lightGreen : Colors.red)
                            )
                          ]
                        )
                      ),
                      Text(
                        "Message-> {${state}}",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 30
                        ),
                      )
                    ],
                  ),
                ),
              )
            ),
            FractionallySizedBox(
               widthFactor: 0.2,
               child: ElevatedButton.icon(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 300));
                  wsManager.send(
                    {
                      "op" : "publish",
                      "topic" : "/start_flag",
                      "type" : "std_msgs/msg/Empty",
                      "msg" : {}
                    }
                  );
                  if (context.mounted) {
                    widget.pageController.animateToPage(
                      2, 
                      duration: const Duration(milliseconds: 500), 
                      curve: Curves.ease,
                    );
                  }
                }, 
                icon: const Icon(Icons.play_circle_fill, color: Colors.white,),
                label: const Text(
                  "Start",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  splashFactory: InkRipple.splashFactory,
                  overlayColor: Colors.white.withValues(alpha: 0.3), 
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  elevation: 4, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), 
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}