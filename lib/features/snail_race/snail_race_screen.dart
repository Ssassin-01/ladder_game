import 'package:flutter/material.dart';

class SnailRaceScreen extends StatelessWidget {
  const SnailRaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('달팽이 경주')),
      body: const Center(child: Text('준비 중...')),
    );
  }
}
