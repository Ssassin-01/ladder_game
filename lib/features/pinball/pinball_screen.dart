import 'package:flutter/material.dart';

class PinballScreen extends StatelessWidget {
  const PinballScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('핀볼 게임')),
      body: const Center(child: Text('준비중..')),
    );
  }
}
