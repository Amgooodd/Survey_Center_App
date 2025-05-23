import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _sparkleAnimation;
  bool _showSparkle = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    _orbitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showSparkle = true);
        _sparkleController.repeat(reverse: true);
      }
    });

    _mainController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacementNamed(context, '/first');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_mainController, _sparkleController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(10, (index) {
                    final angle = 2 * pi * (_orbitAnimation.value + index / 10);
                    final distance = 170.0;

                    return Transform.translate(
                      offset: Offset(
                        cos(angle) * distance,
                        sin(angle) * distance,
                      ),
                      child: Transform.scale(
                        scale: 0.8 +
                            0.2 *
                                Curves.easeInOut
                                    .transform(_orbitAnimation.value),
                        child: Icon(
                          index.isEven ? Icons.star : Icons.bolt,
                          color: index.isEven
                              ? Color.fromARGB(255, 253, 200, 0)
                                  .withOpacity(0.7)
                              : Color.fromARGB(255, 28, 51, 95)
                                  .withOpacity(0.7),
                          size: 13 +
                              18 *
                                  Curves.easeInOut
                                      .transform(_orbitAnimation.value),
                        ),
                      ),
                    );
                  }),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return SweepGradient(
                        colors: [
                          Color.fromARGB(255, 253, 200, 0),
                          Color.fromARGB(255, 28, 51, 95),
                          Color.fromARGB(255, 253, 200, 0),
                        ],
                        stops: [0.0, 0.5, 1.0],
                        transform:
                            GradientRotation(2 * pi * _shimmerAnimation.value),
                      ).createShader(rect);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'Survey '),
                          WidgetSpan(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Text(
                                  'c',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_showSparkle)
                                  ...List.generate(10, (index) {
                                    return SparkleParticle(
                                      index: index,
                                      pulse: _sparkleAnimation.value,
                                    );
                                  }),
                              ],
                            ),
                            alignment: PlaceholderAlignment.middle,
                          ),
                          const TextSpan(text: 'enter'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SparkleParticle extends StatelessWidget {
  static const List<IconData> shapes = [
    Icons.star,
    Icons.diamond,
  ];

  final int index;
  final double pulse;

  const SparkleParticle({
    required this.index,
    required this.pulse,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    final baseAngle = 2 * pi * (index / 10);
    final distance = 25 + random.nextDouble() * 10;

    return Transform.translate(
      offset: Offset(
        cos(baseAngle) * distance * pulse,
        sin(baseAngle) * distance * pulse,
      ),
      child: Transform.scale(
        scale: 0.8 + 0.6 * sin(pulse * pi * 2),
        child: Icon(
          shapes[index % shapes.length],
          color: Color.lerp(
            Color.fromARGB(255, 28, 51, 95),
            Color.fromARGB(255, 255, 242, 175),
            random.nextDouble(),
          )?.withOpacity(0.8 + 0.2 * sin(pulse * pi)),
          size: 20 + 18 * sin(pulse * pi),
        ),
      ),
    );
  }
}
