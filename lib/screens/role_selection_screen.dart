import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key}); // ✅ No required parameters

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            // BACK ARROW
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),

            // TITLE
            Positioned(
              left: 35,
              top: 50,
              child: const SizedBox(
                width: 305,
                height: 28,
                child: Text(
                  'Select Role',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 28,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.14,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),

            // Prompt Text
            Positioned(
              left: 45,
              top: 150,
              child: const SizedBox(
                width: 305,
                child: Text(
                  'Please choose your role to continue:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ),
            ),

            // FARMER BUTTON
            Positioned(
              left: 68,
              top: 220,
              child: GestureDetector(
                onTap: () {
                  print('Selected role: Farmer');
                  Navigator.pushNamed(context, '/farmerLogIn');
                },
                child: roleButton('FARMER'),
              ),
            ),

            // CUSTOMER BUTTON
            Positioned(
              left: 68,
              top: 300,
              child: GestureDetector(
                onTap: () {
                  print('Selected role: Customer');
                  Navigator.pushNamed(context, '/customerLogIn');
                },
                child: roleButton('CUSTOMER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button widget
  Widget roleButton(String label) {
    return Container(
      width: 260,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC02C697),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.11,
          letterSpacing: 1,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
