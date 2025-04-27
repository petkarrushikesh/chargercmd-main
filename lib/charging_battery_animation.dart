import 'package:flutter/material.dart';

class ChargingBatteryAnimation extends StatefulWidget {
  const ChargingBatteryAnimation({Key? key}) : super(key: key);

  @override
  State<ChargingBatteryAnimation> createState() => _ChargingBatteryAnimationState();
}

class _ChargingBatteryAnimationState extends State<ChargingBatteryAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.green),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    heightFactor: _animation.value,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Positioned(
                top: -12,
                child: Icon(Icons.battery_charging_full, color: Colors.green, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
