import 'package:flutter/material.dart';
import '../../widgets/sharexe_background1.dart';
import '../../widgets/custom_button.dart';
import '../../../app_route.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 327,
              fit: BoxFit.contain,
            ),
            const Text(
              "Thân thiện với môi trường",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 100),
            CustomButton(
              text: 'Dùng cho khách hàng',
              backgroundColor: const Color(0xFFFFD600),
              textColor: Colors.black,
              onPressed: () {
                Navigator.pushNamed(context, PassengerRoutes.splash);
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Dùng cho tài xế',
              backgroundColor: const Color(0xFF003087),
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, DriverRoutes.splash);
              },
            ),
          ],
        ),
      ),
    );
  }
}
