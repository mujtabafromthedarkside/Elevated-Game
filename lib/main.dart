import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future hideSystemBars() {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    hideSystemBars();
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
        body: SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: double.infinity,
            height: 200,
            child: Center(
              child: Text(
                "ELEVATED",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            height: 50,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const GamePage(),
                    ),
                  );
                },
                child: const Text(
                  "Play",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                )),
          ),
          Container(
            margin: const EdgeInsets.only(top: 50),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: 'How to Play:\n',
                  ),
                  TextSpan(
                    text: '- Tap anywhere to jump\n- Tilt your phone to move sideways\n- Do not let the square fall\n- Dodge the falling obstacles\n',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/value.txt');
  }

  Future<int> readValue() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  Future<File> writeValue(int value) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString('$value');
  }
}

class Square {
  double squareSize = 50;

  double _x = 0.0; //accelerometer x value
  double _xMax = 0.6; //this value results in maxVelocityX
  double velocityX = 0;
  double maxVelocityX = -0.7;

  double topLeftX = 0; //square center x coordinate
  double topLeftY = 0; //square center y coordinate
  double centerX = 0;
  double centerY = 0;

  double maxVelocity = -7;
  double velocityY = 0;
  double gravity = 0.27;

  double rotationAngle = 0.0;
  double rateOfRotation = 0.05;
  // double rateOfRotation = 0.00;

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

  void updatePoints() {
    centerX = topLeftX + squareSize / 2;
    centerY = topLeftY + squareSize / 2;
  }

  List<double> findPoint(double startAngle) {
    const double pi = 3.141592654;
    double tmp = startAngle;
    while (startAngle > pi / 4 || startAngle < -pi / 4) {
      if (startAngle > pi / 4) {
        startAngle -= pi / 2;
      } else if (startAngle < -pi / 4) {
        startAngle += pi / 2;
      }
    }

    double length = (squareSize / 2 / cos(startAngle)).abs();
    length -= 2;
    startAngle = tmp;

    double rotatedPointX = centerX - length * cos(startAngle - rotationAngle);
    double rotatedPointY = centerY + length * sin(startAngle - rotationAngle);

    return [rotatedPointX, rotatedPointY];
  }

  void reset() {
    gameOver = false;
    gameStart = true;

    _x = 0.0; //accelerometer x value
    velocityX = 0;

    topLeftX = 0; //square center x coordinate
    topLeftY = 0; //square center y coordinate
    updatePoints();

    velocityY = 0;

    rotationAngle = 0.0;
  }

  void updatePosition() {
    if (topLeftY + sqrt(2 * (squareSize * squareSize)) < 0 || topLeftY - sqrt(2 * (squareSize * squareSize)) > screenHeight) {
      print("Game over");
      gameOver = true;
      return;
    }

    rotationAngle += rateOfRotation;

    velocityX = _x / _xMax * maxVelocityX;
    topLeftX += velocityX;
    topLeftX = min(screenWidth - squareSize, topLeftX);
    topLeftX = max(0, topLeftX);

    topLeftY += velocityY;
    velocityY += gravity;

    updatePoints();
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
    required this.squareSize,
    required this.position,
  }) {
    // position = -(widget.thickness);
    // position = 0;
    initHole();
  }

  late double position;
  late double holeSize = 100;
  late double holeTolerance = 30; // distance from edge of screen, trying that hole isn't too close to edge
  late double holePosition;
  late bool dead = false;

  void updatePosition() {
    if (dead) {
      return;
    } else if (position > Square.screenHeight + 200) {
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
  final Storage storage = Storage();
  final double pi = 3.141592654;
  final int numberOfBoundaryPointsToCheck = 200;
  int score = 0;
  int highScore = 0;
  bool pauseFlag = false;
  bool exitFlag = false;

  late Timer obstacleSpawner;
  late Timer gameTimer;
  late Timer scoreTimer;

  // late AudioCache _audioCache;

  @override
  void initState() {
    super.initState();
    print("init state called");
    // _audioCache = AudioCache(prefix: "audio/", fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
  }

  void reset() {
    print("reset called");
    setState(() {
      square.reset();
      obstacles.clear();
      obstacles.add(
        Obstacle(velocity: 2, thickness: 20, squareSize: 50, position: 240),
      );
      obstacles.add(
        Obstacle(velocity: 2, thickness: 20, squareSize: 50, position: 0),
      );

      readHighScore();
      score = 0;
      obstacleSpawnerCounter = 0;
    });

    notClickedYet = true;
  }

  void readHighScore() {
    storage.readValue().then((int value) {
      print("read high score: $value");
      highScore = value;
    });
  }

  void updateHighScore() {
    highScore = max(score, highScore);

    // Write the variable as a string to the file.
    print('writing high score: $highScore');
    storage.writeValue(highScore);
  }

  bool notClickedYet = true;
  int frameRate = 60;
  int spawnSeconds = 2;
  int obstacleSpawnerCounter = 0;
  void tapFun() {
    square.tapFun();
    // AudioPlayer().play(AssetSource('audio/playerPress4.mp3'));

    if (notClickedYet) {
      notClickedYet = false;

      obstacleSpawner = Timer.periodic(Duration(milliseconds: 1000 ~/ frameRate), (Timer timer) {
        if (pauseFlag) return;
        if (exitFlag) return;
        obstacleSpawnerCounter++;
        if (obstacleSpawnerCounter < spawnSeconds * frameRate)
          return;
        else
          obstacleSpawnerCounter = 0;

        setState(() {
          obstacles.add(
            Obstacle(velocity: 2, thickness: 20, squareSize: 50, position: 0),
          );

          if (obstacles.isNotEmpty && obstacles.first.dead) {
            obstacles.removeFirst();
            print("removed obstacle from queue");
          }
        });

        print("new obstacle dropped");
        print("queue length: ${obstacles.length}");
      });

      gameTimer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ frameRate),
        (Timer timer) {
          if (pauseFlag) return;
          if (exitFlag) return;

          setState(() {
            square.updatePosition();
            for (var element in obstacles) {
              element.updatePosition();
            }

            checkCollision();

            if (Square.gameOver == true) {
              // AudioPlayer().play(AssetSource('audio/end1.mp3'));
              timer.cancel();
              obstacleSpawner.cancel();
              scoreTimer.cancel();
              print("all timers cancelled");
            }
          });
        },
      );

      scoreTimer = Timer.periodic(
        const Duration(seconds: 1),
        (Timer timer) {
          if (pauseFlag) return;
          if (exitFlag) return;

          setState(() {
            score++;
            updateHighScore();
          });
        },
      );
    }
  }

  void checkCollision() {
    for (var element in obstacles) {
      for (double startAngle = 0; startAngle < 2 * pi; startAngle += pi / numberOfBoundaryPointsToCheck) {
        List<double> point = square.findPoint(startAngle);
        double x = point[0];
        double y = point[1];

        bool collided = true;
        if (x > element.holePosition && x < element.holePosition + element.holeSize) {
          collided = false;
        }

        if (y < element.position || y > element.position + element.thickness) {
          collided = false;
        }

        if (collided) {
          Square.gameOver = true;
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    Square.subscription.cancel();
    obstacleSpawner.cancel();
    gameTimer.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void changePause() {
    if (Square.gameOver) return;
    if (notClickedYet) return;
    setState(() {
      pauseFlag = !pauseFlag;
    });
    print("pause state: $pauseFlag");
  }

  void changeExit() {
    setState(() {
      exitFlag = !exitFlag;
      if (exitFlag && !pauseFlag) {
        changePause();
      }
    });

    print("exit state: $exitFlag");
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle exitButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: EdgeInsets.all(5),
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    // var navbarHeight = MediaQuery.of(context).viewInsets.bottom;
    // print("Building again");
    if (square.gameStart) {
      print("Starting game");
      reset();
      Square.screenWidth = MediaQuery.of(context).size.width;
      Square.screenHeight = MediaQuery.of(context).size.height;
      print("screenWidth: ${Square.screenWidth}, screenHeight: ${Square.screenHeight}");
      var padding = MediaQuery.of(context).padding;
      //actual screenHeight
      Square.screenHeight -= padding.top;

      //square center
      square.topLeftY = Square.screenHeight - 200; //- squareSize;
      square.topLeftX = (Square.screenWidth - square.squareSize) / 2;
      square.updatePoints();
      print("x: ${square.topLeftX}, y: ${square.topLeftY}");

      // print(topLeftY);
      print("build started");
      square.gameStart = false;
    }

    return GestureDetector(
      onTap: Square.gameOver
          ? reset
          : pauseFlag
              ? changePause
              : tapFun,
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
                Row(
                  children: [
                    Transform.scale(
                      scale: 2,
                      child: IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: changePause,
                      ),
                    ),
                    Transform.scale(
                      scale: 2,
                      child: IconButton(
                        icon: const Icon(Icons.exit_to_app),
                        onPressed: changeExit,
                        // color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (!notClickedYet)
                  Container(
                      alignment: Alignment.bottomRight,
                      margin: const EdgeInsets.only(bottom: 20, right: 10),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: 'Score: $score\n',
                            ),
                            TextSpan(
                              text: 'Max Score: $highScore',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                Transform.translate(
                  offset: Offset(square.topLeftX, square.topLeftY),
                  child: Transform.rotate(
                    angle: square.rotationAngle,
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
                if (Square.gameOver && !exitFlag)
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'GAME OVER!\n',
                          ),
                          TextSpan(
                            text: 'Tap to Restart',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (notClickedYet && !exitFlag)
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 100),
                    child: const Text(
                      'Tap to jump',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (pauseFlag && !exitFlag)
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 100),
                    child: const Text(
                      'Tap to Continue',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (exitFlag)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 100),
                        child: const Text(
                          'Exit?',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: exitButtonStyle,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(width: 60, child:  Center(child: Text('Yes'))),
                      ),
                      ElevatedButton(
                        style: exitButtonStyle,
                        onPressed: changeExit,
                        child: Container(width: 60, child: Center(child: Text('No'))),
                      )
                    ],
                  ),
              ]),
        ),
      ),
    );
  }
}
