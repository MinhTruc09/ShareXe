import 'package:flutter/material.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/role_screen.dart';
import 'views/screens/passenger/splash_pscreen.dart';
import 'views/screens/passenger/login_passenger.dart';
import 'views/screens/passenger/home_pscreen.dart';
import 'views/screens/passenger/register_passenger_step1.dart';
import 'views/screens/passenger/register_user_step2.dart';
import 'views/screens/driver/splash_dscreen.dart';
import 'views/screens/driver/login_driver.dart';
import 'views/screens/driver/home_dscreen.dart';
import 'views/screens/driver/register_driver_step1.dart';
import 'views/screens/driver/register_driver_step2.dart';
import 'models/registration_data.dart';
import 'views/screens/ride_details.dart';

class AppRoute {
  static const String splash = '/';
  static const String role = '/role';
  
  // Passenger routes
  static const String splashPassenger = '/splash_passenger';
  static const String loginPassenger = '/login_passenger';
  static const String homePassenger = '/home_passenger';
  static const String registerPassengerStep1 = '/register_passenger_step1';
  static const String registerUserStep2 = '/register_user_step2';
  static const String rideDetails = '/ride_details';
  
  // Driver routes
  static const String splashDriver = '/splash_driver';
  static const String loginDriver = '/login_driver';
  static const String homeDriver = '/home_driver';
  static const String registerDriverStep1 = '/register_driver_step1';
  static const String registerDriverStep2 = '/register_driver_step2';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case role:
        return MaterialPageRoute(builder: (_) => const RoleScreen());
      
      // Passenger routes
      case splashPassenger:
        return MaterialPageRoute(builder: (_) => const SplashPscreen());
      case loginPassenger:
        return MaterialPageRoute(builder: (_) => const LoginPassenger());
      case homePassenger:
        return MaterialPageRoute(builder: (_) => const HomePscreen());
      case registerPassengerStep1:
        return MaterialPageRoute(
          builder: (context) => RegisterPassengerStep1(
            role: 'PASSENGER',
            onNext: (data) => Navigator.pushNamed(
              context,
              registerUserStep2,
              arguments: data,
            ),
          ),
        );
      case registerUserStep2:
        final data = settings.arguments as RegistrationData;
        return MaterialPageRoute(
          builder: (context) => RegisterUserStep2(
            role: 'PASSENGER',
            data: data,
          ),
        );
      
      case rideDetails:
        final ride = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => RideDetailScreen(ride: ride),
        );
      
      // Driver routes
      case splashDriver:
        return MaterialPageRoute(builder: (_) => const SplashDscreen());
      case loginDriver:
        return MaterialPageRoute(builder: (_) => const LoginDriver());
      case homeDriver:
        return MaterialPageRoute(builder: (_) => const HomeDscreen());
      case registerDriverStep1:
        return MaterialPageRoute(
          builder: (context) => RegisterDriverStep1(
            onNext: (data) => Navigator.pushNamed(
              context,
              registerDriverStep2,
              arguments: data,
            ),
          ),
        );
      case registerDriverStep2:
        final data = settings.arguments as RegistrationData;
        return MaterialPageRoute(
          builder: (context) => RegisterDriverStep2(
            data: data,
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}