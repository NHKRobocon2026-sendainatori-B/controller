import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocketmanager.dart';
import 'gamepadmanager.dart';
import 'package:nhk_robocon_2026_controller/connect.dart';
import 'package:nhk_robocon_2026_controller/controller_page.dart';

void main(){
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Websocketmanager(), 
        ),
        ChangeNotifierProvider(
          create: (_) => Gamepadmanager(),
        )
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final PageController controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ConnectionPage(pageController: controller),
          Controller(pageController: controller,),
        ],
        controller: controller,
      ),
    );
  }
}