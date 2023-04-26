import 'package:flutter/material.dart';

String printDuration(Duration duration,
    {bool absolute = true, bool seconds = false}) {
  if (absolute) {
    duration = duration.abs();
  }
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitsHours = twoDigits(duration.inHours.remainder(24).abs());
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "${duration.inDays}d $twoDigitsHours:${twoDigitMinutes}h";
}

class PaddedCard extends StatelessWidget {
  Widget child;
  void Function()? onTap;
  PaddedCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
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
