import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final AnimationController _loadingCtrl;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));

    _loadingCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _logoCtrl.forward();
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: Colors.black12),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.home_work_rounded,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PT. ASTANA KARYA BANDAWASA',
                                  style: TextStyle(
                                    fontFamily: 'TomatoGrotesk',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mimpi Rumahmu Menjadi Nyata',
                                  style: TextStyle(
                                    fontFamily: 'TomatoGrotesk',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _loadingCtrl,
                    builder: (context, _) {
                      final t = _loadingCtrl.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: t * 6.283,
                            child: const Icon(
                              Icons.home_work_rounded,
                              color: Color(0xFFFDD096),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _pulseDot(0.0),
                          const SizedBox(width: 6),
                          _pulseDot(0.2),
                          const SizedBox(width: 6),
                          _pulseDot(0.4),
                          const SizedBox(width: 10),
                          const Text(
                            'Loading',
                            style: TextStyle(
                              fontFamily: 'TomatoGrotesk',
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseDot(double delay) {
    final value = (_loadingCtrl.value + delay) % 1.0;
    final size = 6.0 + (value < 0.5 ? value * 6 : (1 - value) * 6);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFDD096),
        shape: BoxShape.circle,
      ),
    );
  }
}
