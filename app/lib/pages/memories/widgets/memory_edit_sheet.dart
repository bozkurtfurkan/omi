import 'package:flutter/material.dart';
import 'package:omi/backend/schema/memory.dart';
import 'package:omi/providers/memories_provider.dart';

/// Stub - memory edit bottom sheet
class MemoryEditSheet extends StatelessWidget {
  final Memory memory;
  final MemoriesProvider provider;
  final Function(BuildContext, Memory, MemoriesProvider)? onDelete;

  const MemoryEditSheet({super.key, required this.memory, required this.provider, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(child: Text('Memory editing not yet available offline', style: TextStyle(color: Colors.white70))),
    );
  }
}
