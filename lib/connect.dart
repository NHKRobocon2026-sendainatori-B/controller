import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';
import 'gamepadmanager.dart';

class ConnectionPage extends StatefulWidget{
  final PageController pageController;
  ConnectionPage({super.key, required this.pageController});

  @override
  State<ConnectionPage> createState() => ConnectionPagestate();
}

class ConnectionPagestate extends State<ConnectionPage> {
  final TextEditingController textController = TextEditingController(text: "192.168.1.XX");

  bool corner = false; //青ならfalse, 赤ならtrue

  void ChangeCorner(){
    setState(() {
      corner = !corner;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wsManager = context.read<Websocketmanager>();
    final gamepad = context.watch<Gamepadmanager>();

    return Center(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("コントローラー接続："),
                Text((gamepad.isConnected) ? "完了" : "未完了")
              ],
            ),

            TextField(
              decoration: InputDecoration(
                labelText: "IPアドレス",
                border: OutlineInputBorder(),
              ),
              controller: textController,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("コーナー："),
                ElevatedButton(
                  onPressed: ChangeCorner, 
                  child: (corner) ? Text("赤") : Text("青"),
                  style: (corner) 
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(30),
                        shape: CircleBorder()
                      )
                    : ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(30),
                        shape: CircleBorder()
                      ),
                )
              ],
            ),

            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await Future.delayed(const Duration(milliseconds: 300));
                wsManager.setCorner(corner);
                wsManager.connect(textController.text);
                if (context.mounted) {
                  widget.pageController.animateToPage(
                    1, 
                    duration: const Duration(milliseconds: 500), 
                    curve: Curves.ease,
                  );
                }
              }, 
              child: Text("接続する")
            )
          ],
        ),
      ),
    );
  }
}