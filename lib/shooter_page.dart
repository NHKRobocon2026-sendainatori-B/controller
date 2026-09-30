import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'websocketmanager.dart';

class ShooterPage extends StatefulWidget {
  ShooterPage({super.key});

  @override
  State<ShooterPage> createState() => ShooterPageState();
}

class ShooterPageState extends State<ShooterPage> with AutomaticKeepAliveClientMixin {
  int first385 = 80;
  final int minfirst385 = 50;
  final int maxfirst385 = 110;
  int last385 = 150;
  final int minlast385 = 120;
  final int maxlast385 = 180;
  int first735 = 90;
  final int minfirst735 = 60;
  final int maxfirst735 = 130;
  int last735 = 145;
  final int minlast735 = 115;
  final int maxlast735 = 175;
  int photointerrupter = 41;
  int mode = 0; //0:旗、1:机、2:バケツ

  bool first385up = false;
  bool first385down = false;
  bool last385up = false;
  bool last385down = false;
  bool first735up = false;
  bool first735down = false;
  bool last735up = false;
  bool last735down = false;
  bool interrupterup = false;
  bool interrupterdown = false;

  Timer? _updatetimer;

  final TextEditingController _first385controller = TextEditingController();
  final TextEditingController _last385controller = TextEditingController();
  final TextEditingController _first735controller = TextEditingController();
  final TextEditingController _last735controller = TextEditingController();
  final TextEditingController _interruptercontroller = TextEditingController();

  void _updatefirst385(int delta) {
    setState(() {
      first385 += delta;

      if (delta > 0) first385up = true;
      if (delta < 0) first385down = true;

      if (first385 < minfirst385) first385 = minfirst385;
      if (first385 > maxfirst385) first385 = maxfirst385;

      if (first385 > last385) first385 = last385;

      _first385controller.text = first385.toString();
    });
  }

  void _updatelast385(int delta) {
    setState(() {
      last385 += delta;

      if (delta > 0) last385up = true;
      if (delta < 0) last385down = true;

      if (last385 < minlast385) last385 = minlast385;
      if (last385 > maxlast385) last385 = maxlast385;
      
      if (last385 < first385) last385 = first385;

      _last385controller.text = last385.toString();
    });
  }

  void _updatefirst735(int delta) {
    setState(() {
      first735 += delta;

      if (delta > 0) first735up = true;
      if (delta < 0) first735down = true;

      if (first735 < minfirst735) first735 = minfirst735;
      if (first735 > maxfirst735) first735 = maxfirst735;

      if (first735 > last735) first735 = last735;

      _first735controller.text = first735.toString();
    });
  }

  void _updatelast735(int delta) {
    setState(() {
      last735 += delta;

      if (delta > 0) last735up = true;
      if (delta < 0) last735down = true;

      if (last735 < minlast735) last735 = minlast735;
      if (last735 > maxlast735) last735 = maxlast735;
      
      if (last735 < first735) last735 = first735;

      _last735controller.text = last735.toString();
    });
  }

  void _updatephotointerrupter(int delta) {
    setState(() {
      photointerrupter += delta;

      if (delta > 0) interrupterup = true;
      if (delta < 0) interrupterdown = true;

      if (photointerrupter < 0) photointerrupter = 0;

      _interruptercontroller.text = photointerrupter.toString();
    });
  }

  void _startfirst385Timer(int delta) {
    _updatefirst385(delta);
    _updatetimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _updatefirst385(delta);
      }
    );
  }

  void _startlast385Timer(int delta) {
    _updatelast385(delta);
    _updatetimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _updatelast385(delta);
      }
    );
  }

  void _startfirst735Timer(int delta) {
    _updatefirst735(delta);
    _updatetimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _updatefirst735(delta);
      }
    );
  }

  void _startlast735Timer(int delta) {
    _updatelast735(delta);
    _updatetimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _updatelast735(delta);
      }
    );
  }

  void _startphotointerrupter(int delta) {
    _updatephotointerrupter(delta);
    _updatetimer = Timer.periodic(
      const Duration(milliseconds: 100), 
      (timer) {
        _updatephotointerrupter(delta);
      }
    );
  }

  void _stopUpdateTimer(){
    _updatetimer?.cancel();
    setState(() {
      first385up = false;
      first385down = false;
      last385up = false;
      last385down = false;
      first735up = false;
      first735down = false;
      last735up = false;
      last735down = false;
      interrupterup = false;
      interrupterdown = false;
    });
    _senddata();
  }

  Future<void> _changeMode() async {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;

    int next = mode + 1;
    if (next > 2) next = 0;

    final response = await wsManager.sendService(
      service: "/shootermode", 
      type: "custom_msg/srv/SelectMode",
      args: {"mode" : next},
      timeout: Duration(seconds: 1)
    );

    if (response['success'] == true) {
      setState(() {
        mode = next;
        photointerrupter = (mode == 1) ? 39 : 41;
        _interruptercontroller.text = photointerrupter.toString();
      });
    }
  }

  void _senddata() {
    final wsManager = context.read<Websocketmanager>();
    if (!wsManager.isConnected) return;

    Map<String, dynamic> data = {
      "op" : "publish",
      "topic" : "/shooter_out",
      "type" : "std_msgs/msg/UInt8MultiArray",
      "msg" : {
        "layout": {
          "dim": [],
          "data_offset": 0
        },
        "data" : [
          first385,
          last385,
          first735,
          last735,
          photointerrupter
        ]
      }
    };

    wsManager.send(data);
  }

  String get _shootermode {
    String? str;
    if (mode == 0) {
      str = "旗";
    } else if (mode == 1) {
      str = "机";
    } else if (mode == 2) {
      str = "バケツ";
    }
    return str!;
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _first385controller.text = first385.toString();
    _last385controller.text = last385.toString();
    _first735controller.text = first735.toString();
    _last735controller.text = last735.toString();
    _interruptercontroller.text = photointerrupter.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "385: ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _startfirst385Timer(5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (first385up) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_upward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder()
                          ),
                          controller: _first385controller,
                          onSubmitted: (value) {
                            int latest = int.parse(value);

                            if (latest < minfirst385) latest = minfirst385;
                            if (latest > maxfirst385) latest = maxfirst385;
                            if (latest > last385) latest = last385;

                            first385 = latest;

                            _first385controller.text = latest.toString();

                            _senddata();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startfirst385Timer(-5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (first385down) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_downward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_circle_right_sharp,
                    color: Colors.purple,
                    size: 45,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _startlast385Timer(5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (last385up) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_upward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder()
                          ),
                          controller: _last385controller,
                          onSubmitted: (value) {
                            int latest = int.parse(value);

                            if (latest < minlast385) latest = minlast385;
                            if (latest > maxlast385) latest = maxlast385;
                            if (latest < first385) latest = first385;

                            last385 = latest;

                            _last385controller.text = latest.toString();

                            _senddata();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startlast385Timer(-5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (last385down) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_downward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ),

            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "735: ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _startfirst735Timer(5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (first735up) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_upward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder()
                          ),
                          controller: _first735controller,
                          onSubmitted: (value) {
                            int latest = int.parse(value);

                            if (latest < minfirst735) latest = minfirst735;
                            if (latest > maxfirst735) latest = maxfirst735;
                            if (latest > last735) latest = last735;

                            first735 = latest;

                            _first735controller.text = latest.toString();

                            _senddata();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startfirst735Timer(-5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (first735down) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_downward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_circle_right_sharp,
                    color: Colors.purple,
                    size: 45,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _startlast735Timer(5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (last735up) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_upward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder()
                          ),
                          controller: _last735controller,
                          onSubmitted: (value) {
                            int latest = int.parse(value);

                            if (latest < minlast735) latest = minlast735;
                            if (latest > maxlast735) latest = maxlast735;
                            if (latest < first735) latest = first735;

                            last735 = latest;

                            _last735controller.text = latest.toString();

                            _senddata();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startlast735Timer(-5),
                        onTapUp: (_) => _stopUpdateTimer(),
                        onTapCancel: () => _stopUpdateTimer(),
                        child: AnimatedContainer(
                          duration: const Duration(microseconds: 100),
                          color: (last735down) ? Colors.red : Colors.blue,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_downward_outlined, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "photointerrupter: ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => _startphotointerrupter(-1),
                    onTapUp: (_) => _stopUpdateTimer(),
                    onTapCancel: () => _stopUpdateTimer(),
                    child: AnimatedContainer(
                      duration: const Duration(microseconds: 100),
                      color: (interrupterdown) ? Colors.red : Colors.blue,
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.arrow_downward_outlined, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder()
                      ),
                      controller: _interruptercontroller,
                      onSubmitted: (value) {
                        int latest = int.parse(value);

                        if (latest < 0) latest = 0;

                        photointerrupter = latest;

                        _interruptercontroller.text = latest.toString();

                        _senddata();
                      },
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => _startphotointerrupter(1),
                    onTapUp: (_) => _stopUpdateTimer(),
                    onTapCancel: () => _stopUpdateTimer(),
                    child: AnimatedContainer(
                      duration: const Duration(microseconds: 100),
                      color: (interrupterup) ? Colors.red : Colors.blue,
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.arrow_upward_outlined, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            ),

            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Mode: ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _changeMode, 
                    icon: const Icon(Icons.change_circle_outlined, color: Colors.white),
                    label: Text(
                      _shootermode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      foregroundColor: Colors.white,
                      splashFactory: InkRipple.splashFactory,
                      overlayColor: Colors.white.withValues(alpha: 0.3), 
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      elevation: 4, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                    ),
                  )
                ],
              )
            )
          ],
        ),
      ),
    );
  }
}