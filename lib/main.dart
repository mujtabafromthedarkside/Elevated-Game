import 'dart:collection';
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
      home: MyApp2(),
    );
  }
}

class MyApp2 extends StatelessWidget {
  const MyApp2({super.key});

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

class Square {
  double squareSize = 50;

  double _x = 0.0; //accelerometer x value
  double _xMax = 0.6; //this value results in maxVelocityX
  double velocityX = 0;
  double maxVelocityX = -0.4;

  double centerX = 0; //square center x coordinate
  double centerY = 0; //square center y coordinate

  double maxVelocity = -7;
  double velocityY = 0;
  double gravity = 0.25;

  double rotationAngle = 0.0;
  double rateOfRotation = 0.05;

  static late double screenWidth = 400;
  static late double screenHeight = 1000;
  static late bool gameOver = false;
  bool gameStart = true;

  static late StreamSubscription<AccelerometerEvent> subscription;

  Square() {
    subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // print(event);
      _x = event.x;
    });

    reset();
  }

  void reset(){
    gameOver = false;
    gameStart = true;

    _x = 0.0; //accelerometer x value
    velocityX = 0;

    centerX = 0; //square center x coordinate
    centerY = 0; //square center y coordinate

    velocityY = 0;

    rotationAngle = 0.0;
  }

  void updatePosition() {
    if (centerY + sqrt(2*(squareSize*squareSize)) < 0 || centerY - sqrt(2*(squareSize*squareSize)) > screenHeight) {
      print("Game over");
      gameOver = true;
      return;
    }

    rotationAngle += rateOfRotation;

    velocityX = _x / _xMax * maxVelocityX;
    centerX += velocityX;
    centerX = min(screenWidth - squareSize, centerX);
    centerX = max(0, centerX);

    centerY += velocityY;
    velocityY += gravity;
  }

  void tapFun() {
    print("Tapped");
    velocityY = maxVelocity;
  }
}

// typedef bool MyBoolCallback();
class Obstacle {
  final double velocity;
  final double thickness;
  final double squareSize;

  Obstacle({
        required this.velocity,
        required this.thickness,
        required this.squareSize
      })
  {
      // position = -(widget.thickness);
      position = 0;
      initHole();
  }

  late double position;
  late double holeSize = 100;
  late double holeTolerance = 30; // distance from edge of screen, trying that hole isn't too close to edge
  late double holePosition;
  late bool dead = false;

  void updatePosition() {
      if (position > Square.screenHeight + 200) {
        dead = true;
        print('obstacle stopped moving');
        return;
      }
      position += velocity;
  }

  void initHole() {
    assert(sqrt(2 * squareSize * squareSize) + 5 < holeSize, ["Hole is too small for object"]);

    Random randomGenerator = Random();
    holePosition = randomGenerator.nextDouble() * (Square.screenWidth - 2 * holeTolerance - holeSize) + holeTolerance;
    // holePosition = 100;
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Queue<Obstacle> obstacles = Queue<Obstacle>();
  // Obstacle obs = Obstacle(velocity: 2, thickness: 20, squareSize: 50);
  Square square = Square();
  late Timer obstacleSpawner;
  late Timer gameTimer;

  @override
  void initState() {
    super.initState();
    reset();
    // Start adding obstacles after 1 second
  }

  void reset(){
    print("reset called");
    setState(
      (){
      square.reset();
      obstacles.clear();
    });
    notClickedYet = true;
  }

  bool notClickedYet = true;
  int frameRate = 60;
  void tapFun() {
    square.tapFun();
    if(notClickedYet){
      notClickedYet = false;

      obstacleSpawner = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      setState(() {
        obstacles.add(
          Obstacle(velocity: 2, thickness: 20, squareSize: 50),
        );

        if (obstacles.isNotEmpty && obstacles.first.dead){
          obstacles.removeFirst();
          print("removed obstacle from queue");
        }
      });
        print("new obstacle dropped");
        print("queue length: ${obstacles.length}");
      });

      gameTimer = Timer.periodic(
        Duration(milliseconds: 1000~/frameRate),
        (Timer timer) {
          setState(() {
            square.updatePosition();
            for(var element in obstacles) {
              element.updatePosition();
            }

            // checkCollision();

            if(Square.gameOver == true) {
              timer.cancel();
              obstacleSpawner.cancel();
              print("both timers cancelled");
            }
          });
        },
      );
    }
  }

  // void checkCollision(){
  //   for(var element in obstacles) {
      
  // }

  @override
  void dispose() {
    Square.subscription.cancel();
    obstacleSpawner.cancel();
    gameTimer.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // var navbarHeight = MediaQuery.of(context).viewInsets.bottom;
    // print("Building again");
    if (square.gameStart) {
      Square.screenWidth = MediaQuery.of(context).size.width;
      Square.screenHeight = MediaQuery.of(context).size.height;
      print("screenWidth: ${Square.screenWidth}, screenHeight: ${Square.screenHeight}");
      var padding = MediaQuery.of(context).padding;
      //actual screenHeight
      Square.screenHeight -= padding.top;

      //square center
      square.centerY = Square.screenHeight / 2; //- squareSize;
      square.centerX = (Square.screenWidth - square.squareSize) / 2;
      print("x: ${square.centerX}, y: ${square.centerY}");

      // print(centerY);
      print("build started");
      square.gameStart = false;
    }

    return GestureDetector(
      onTap: Square.gameOver ? reset : null,
      child: Scaffold(
          // appBar: AppBar(
          //   toolbarHeight: 100,
          //   title: const Text("Elevated Game"),
          // ),
        body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
            // physics: const NeverScrollableScrollPhysics(),
            children: [
              if(Square.gameOver)
                      const Center(
                        child: Text(
                          "Game Over\nTap to restart",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ),
            ...obstacles.map((element) {
              return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(children: [
                    Positioned(
                      top: element.position,
                      left: 0,
                      child: Container(
                        height: element.thickness,
                        width: element.holePosition,
                        color: Colors.green,
                      ),
                    ),
                    Positioned(
                      top: element.position,
                      left: element.holePosition + element.holeSize,
                      child: Container(
                        height: element.thickness,
                        width: Square.screenWidth - element.holePosition - element.holeSize,
                        color: Colors.green,
                      ),
                    )
                  ]),
                );
          }).toList(),
              Transform.translate(
                offset: Offset(square.centerX, square.centerY),
                child: Transform.rotate(
                  angle: square.rotationAngle,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: tapFun,
                    child: Container(
                      width: square.squareSize,
                      height: square.squareSize,
                      color: Colors.red,
                      // decoration: const BoxDecoration(
                      //   shape: BoxShape.circle,
                      //   color: Colors.red,
                      // ),
                    ),
                  ),
                ),
              )
            ]),
      )),
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
