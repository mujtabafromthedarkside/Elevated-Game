import 'package:flutter/material.dart';

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
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const GamePage(),
                    ),
                  );
                },
                child: const Text("Play"))));
  }
}

class Square extends StatefulWidget {
  final double size;

  Square({required this.size});

  @override
  _SquareState createState() => _SquareState();
}

class _SquareState extends State<Square> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double center_x = 0;
  double center_y = 0;
  double velocity = -2;
  double changeInVelocity = 2;
  double gravity = 1;
  late double screenWidth;
  late double screenHeight;
  bool gameStart = true;

  @override
  void initState() {
    super.initState();

    // _animationController = AnimationController(
    //   vsync: this
    //   duration: const Duration(milliseconds: 16),
    // );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _animationController.addListener(updatePosition);
    // _animationController.forward();
  }

  @override
  void dispose() {
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
    print('updating position');
    if (velocity <= 0){
      setState((){
        center_y += velocity;
        if(center_y < 0){
          center_y = screenHeight;
        }
        print("updating position to $center_y");
      // velocity += gravity;
      });
    }
  }

  void TapFun() {
    print("Tapped");
    // if (!_animationController.isAnimating) {
      setState(() {
        // Move the square up by a certain amount
        velocity = -2.0;
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
      center_y = screenHeight/2;//- widget.size;
      center_x = (screenWidth - widget.size)/2;
      print("x: $center_x, y: $center_y");

      // print(center_y);
      print("build started");
      gameStart = false;
    }

    return Transform.translate(
      offset: Offset(center_x, center_y),
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: TapFun,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                    width: widget.size,
                    height: widget.size,
                    color: Colors.red,
                  );
            },
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
  double squareSize = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   toolbarHeight: 100,
      //   title: const Text("Elevated Game"),
      // ),
      body: Square(size: squareSize),
    );
  }
}
