import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elevated Game',
      home: _MyApp(),
    );
  }
}

class _MyApp extends StatelessWidget {
  const _MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   title: const Text("Elevated Game"),
        // ),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => const GamePage(),
                        ),
                      );
                    },
                    child: const Text("Play")),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => const TestAccelerometer(),
                        ),
                      );
                    },
                    child: const Text("Accelerometer")),
              ],
            )));
  }
}

class Square extends StatefulWidget {
  const Square({super.key});

  @override
  _SquareState createState() => _SquareState();
}

class _SquareState extends State<Square> with SingleTickerProviderStateMixin {
  double squareSize = 50;

  double _x = 0.0;                        //accelerometer x value
  double _xMax = 0.6;                     //this value results in maxVelocityX
  double velocityX = 0;
  double maxVelocityX = -0.4;

  double centerX = 0;                    //square center x coordinate
  double centerY = 0;                    //square center y coordinate
  
  double maxVelocity = -7;
  double velocityY = 0;
  double gravity = 0.25;

  double rotationAngle = 0.0;
  double rateOfRotation = 0.05;

  late double screenWidth;
  late double screenHeight;
  bool gameStart = true;
  late AnimationController _animationController;
  StreamSubscription<AccelerometerEvent>? _subscription;


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    );
    
    _animationController.addListener(updatePosition);
    _animationController.addListener(
      () {
        // JUST FOR TESTING ONCE GAME IS COMPLETED, TURN + TO -
        if ((centerY + squareSize / 2) > screenHeight) {
          _animationController.stop();
        }
      },
    );

    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // print(event);
      setState(() {
        _x = event.x;
      });
    });
    // _animationController.forward();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    if (!_animationController.isAnimating) {
      print("start animating");
      _animationController.reset();
      _animationController.forward();
    }
  }

  void updatePosition() {
    // print('updating position');
    // if (velocity <= 0){
      setState((){
        rotationAngle += rateOfRotation;

        velocityX = _x/_xMax * maxVelocityX;
        centerX += velocityX;
        centerX = min(screenWidth - squareSize, centerX);
        centerX = max(0, centerX);

        centerY += velocityY;
        velocityY += gravity;
        if(centerY < 0){
          centerY = screenHeight;
        }
        // print("updating position to $centerY");
      // velocity += gravity;
      });
    // }
  }

  void tapFun() {
    print("Tapped");
    // if (!_animationController.isAnimating) {
      setState(() {
        // Move the square up by a certain amount
        // velocityX = _x/_xMax * maxVelocityX;
        // velocityY = sqrt(maxVelocity;
        velocityY = maxVelocity;
      });
      startAnimation();
    // }
  }

  @override
  Widget build(BuildContext context) {
    if(gameStart){
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
      var padding = MediaQuery.of(context).padding;
      var navbarHeight = MediaQuery.of(context).viewInsets.bottom;
      
      //actual screenHeight
      screenHeight -= padding.top;

      //square center
      centerY = screenHeight/2;//- squareSize;
      centerX = (screenWidth - squareSize)/2;
      print("x: $centerX, y: $centerY");

      // print(centerY);
      print("build started");
      gameStart = false;
    }

    return Transform.translate(
        offset: Offset(centerX, centerY),
        child: Transform.rotate(
          angle: rotationAngle,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tapFun,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                        width: squareSize,
                        height: squareSize,
                        // color: Colors.red,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      );
                },
              ),
            ),
        ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   toolbarHeight: 100,
      //   title: const Text("Elevated Game"),
      // ),
      body: Square(),
    );
  }
}

class TestAccelerometer extends StatefulWidget {
  const TestAccelerometer({super.key});

  @override
  State<TestAccelerometer> createState() => _TestAccelerometerState();
}

class _TestAccelerometerState extends State<TestAccelerometer> {
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      // print(event);
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the accelerometer values (_x, _y, _z) to determine the angle or tilt
    // of the phone and update your game logic accordingly.
    // For example, you can check the value of _x to determine if the phone is
    // leaning to the right or left.
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Angle Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('X: $_x'),
            Text('Y: $_y'),
            Text('Z: $_z'),
          ],
        ),
      ),
    );
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   // Remember to cancel the accelerometer listener when the widget is disposed
  //   accelerometerEvents.cancel();
  // }
}