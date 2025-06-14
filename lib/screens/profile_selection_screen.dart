import 'package:flutter/material.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 375,
        height: 812,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            // Title: Agrimate
            const Positioned(
              left: 35,
              top: 228,
              child: SizedBox(
                width: 305,
                child: Text(
                  'Agrimate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -1,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),

            // Subtitle
            const Positioned(
              left: 35,
              top: 268,
              child: SizedBox(
                width: 305,
                child: Text(
                  'Empowering Farmers. Connecting Markets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 2.13,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),

            // Farmer Button
            Positioned(
              left: 58,
              top: 463,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/farmerSelection');
                },
                child: Container(
                  width: 260,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: const Color(0xCC02C697),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'FARMER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.11,
                      letterSpacing: 1,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ),

            // Customer Button
            Positioned(
              left: 58,
              top: 539,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/customerSelection');
                },
                child: Container(
                  width: 260,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: const Color(0xCC02C697),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'CUSTOMER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.11,
                      letterSpacing: 1,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
