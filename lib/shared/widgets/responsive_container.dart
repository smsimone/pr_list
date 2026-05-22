import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  const ResponsiveContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    assert(true);
    final double width = MediaQuery.of(context).size.width;
    final double maxWidth = width > 900 ? 900 : width;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: maxWidth, child: child),
    );
  }
}
