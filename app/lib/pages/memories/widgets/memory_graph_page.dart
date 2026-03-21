import 'package:flutter/material.dart';

/// Stub - memory graph page
class MemoryGraphPage extends StatelessWidget {
  const MemoryGraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(title: const Text('Memory Graph'), backgroundColor: Colors.transparent),
      body: const Center(child: Text('Memory graph not yet available offline', style: TextStyle(color: Colors.white70))),
    );
  }
}
