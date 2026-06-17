import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool elevated;

  const BrandLogo({super.key, this.size = 44, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x1F007A31),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        'assets/icon/logo.png',
        fit: BoxFit.contain,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
