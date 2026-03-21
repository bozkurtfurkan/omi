import 'package:flutter/material.dart';
import 'package:omi/providers/memories_provider.dart';

/// Stub - memory management bottom sheet
class MemoryManagementSheet extends StatelessWidget {
  final MemoriesProvider provider;

  const MemoryManagementSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Text('Memory management not yet available offline', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
