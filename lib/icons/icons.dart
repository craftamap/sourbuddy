import 'package:flutter/cupertino.dart';

class SourdoughIcon extends StatelessWidget {
  final double? size;
  const SourdoughIcon({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return ImageIcon(AssetImage("assets/sourdough-icon.png"), size: size);
  }
}
