
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String role;

  const RoleSelectionScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: 375,
        height: 812,
        clipBehavior: Clip.antiAlias,
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
              child: SizedBox(
                width: 305,
                height: 28,
                child: Text(
                  '$role Profile',
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 28,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.14,
                    letterSpacing: -0.80,
                  ),
                ),
              ),
            ),

            const Positioned(
              left: 35,
              top: 89,
              child: Opacity(
                opacity: 0.20,
                child: SizedBox(
                  width: 305,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFF8F92A1)),
                  ),
                ),
              ),
            ),

            // PROMPT
            Positioned(
              left: 45,
              top: 321,
              child: SizedBox(
                width: 305,
                child: Text(
                  'Would you like to Sign Up or Log In as a $role?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ),
            ),

            // LOGIN BUTTON
            Positioned(
              left: 67,
              top: 400,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    role == 'Farmer' ? '/farmerLogIn' : '/customerLogIn',
                  );
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
                  child: const Center(
                    child: Text(
                      'LOG IN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // SIGN UP BUTTON
            Positioned(
              left: 68,
              top: 476,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    role == 'Farmer' ? '/createFarmerProfile' : '/createCustomerProfile',
                  );
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
                  child: const Center(
                    child: Text(
                      'SIGN UP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Fade
            const Positioned(
              left: 0,
              top: 778,
              child: Opacity(
                opacity: 0.05,
                child: SizedBox(
                  width: 375,
                  height: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
