import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';

class ConnectionPage extends StatelessWidget {
  ConnectionPage({super.key, this.pageController});
  final TextEditingController textController = TextEditingController(text: "192.168.1.XX");
  final PageController? pageController;

  @override
  Widget build(BuildContext context) {
    final wsManager = context.read<Websocketmanager>();

    return Center(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "IPアドレス",
                border: OutlineInputBorder(),
              ),
              controller: textController,
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await Future.delayed(const Duration(milliseconds: 300));
                wsManager.connect(textController.text);
                if (context.mounted) {
                  pageController?.animateToPage(
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