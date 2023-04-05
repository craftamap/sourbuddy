import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PaddedCard extends StatelessWidget {
  Widget child;
  void Function()? onTap;
  PaddedCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
