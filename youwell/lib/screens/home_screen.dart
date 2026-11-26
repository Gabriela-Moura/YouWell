import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nomeSetor;

  const HomeScreen({super.key, required this.nomeSetor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 48 || constraints.maxHeight <= 0) {
            return const SizedBox.shrink();
          }

          final logoSize = math.min(
            constraints.maxWidth * 1.15,
            constraints.maxHeight * 0.62,
          );
          final buttonWidth = math.min(constraints.maxWidth - 48, 360.0);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF78AA9B),
                        Color(0xFF46BE9F),
                        Color(0xFF20AC8D),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -logoSize * 0.2,
                left: (constraints.maxWidth - logoSize) / 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: Image.asset(
                    'assets/images/logo_branco.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: scale,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.12),
                        ],
                        stops: const [0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'BEM-ESTAR NO TRABALHO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'YouWell',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Saúde e bem-estar corporativo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: buttonWidth,
                          height: 62,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoginScreen(
                                    nomeSetor: nomeSetor,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF16866E),
                              elevation: 8,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Login'),
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: Color(0xFFE5F5EF),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 21,
                                    color: Color(0xFF16866E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
