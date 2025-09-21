import 'dart:ui';
import 'package:flutter/material.dart';

class GlassyBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? size;
  final EdgeInsetsGeometry? margin;

  const GlassyBackButton({
    Key? key,
    this.onPressed,
    this.iconColor,
    this.size = 50,
    this.margin = const EdgeInsets.only(top: 40, left: 20),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onPressed ?? () => Navigator.of(context).pop(),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: iconColor ?? Colors.white,
                    size: size! * 0.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}