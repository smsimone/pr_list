import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    assert(message.trim().isNotEmpty, 'message must not be empty');
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
