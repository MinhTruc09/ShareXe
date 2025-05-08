import 'package:flutter/material.dart';

// Common screens
import 'views/screens/common/splash_screen.dart';
import 'views/screens/common/role_screen.dart';
import 'views/screens/common/ride_details.dart';

// Passenger screens
import 'views/screens/passenger/splash_pscreen.dart';
import 'views/screens/passenger/login_passenger.dart';
import 'views/screens/passenger/home_pscreen.dart';
import 'views/screens/passenger/register_passenger_step1.dart';
import 'views/screens/passenger/register_user_step2.dart';
import 'views/screens/passenger/profile_screen.dart';
import 'views/screens/passenger/edit_profile_screen.dart';

// Driver screens
import 'views/screens/driver/splash_dscreen.dart';
import 'views/screens/driver/login_driver.dart';
import 'views/screens/driver/home_dscreen.dart';
import 'views/screens/driver/register_driver_step1.dart';
import 'views/screens/driver/register_driver_step2.dart';
import 'views/screens/driver/profile_screen.dart';
import 'views/screens/driver/edit_profile_screen.dart';
import 'views/screens/driver/create_ride_screen.dart';
import 'views/screens/driver/my_rides_screen.dart';
import 'views/screens/driver/driver_bookings_screen.dart';
import 'views/screens/driver/driver_ride_detail_screen.dart';

// Chat screens
import 'views/screens/chat/user_list_screen.dart';
import 'views/screens/chat/chat_room_screen.dart';

// Models
import 'models/registration_data.dart';
import 'models/user_profile.dart';

// Passenger routes namespace
class PassengerRoutes {
  static const String splash = '/passenger/splash';
  static const String login = '/passenger/login';
  static const String home = '/passenger/home';
  static const String registerStep1 = '/passenger/register-step1';
  static const String registerStep2 = '/passenger/register-step2';
  static const String profile = '/passenger/profile';
  static const String editProfile = '/passenger/edit-profile';
}

// Driver routes namespace
class DriverRoutes {
  static const String splash = '/driver/splash';
  static const String login = '/driver/login';
  static const String home = '/driver/home';
  static const String registerStep1 = '/driver/register-step1';
  static const String registerStep2 = '/driver/register-step2';
  static const String profile = '/driver/profile';
  static const String editProfile = '/driver/edit-profile';
  static const String createRide = '/driver/create-ride';
  static const String myRides = '/driver/my-rides';
  static const String bookings = '/driver/bookings';
  static const String rideDetails = '/driver/ride-details';
}

class AppRoute {
  // Common routes
  static const String splash = '/splash';
  static const String role = '/role';
  static const String rideDetails = '/ride-details';

  // Chat routes
  static const String chatRoom = '/chat_room';
  static const String chatList = '/chat_list';

  // Driver routes - adding these to fix references in driver screens
  static const String profileDriver = DriverRoutes.profile;
  static const String myRides = DriverRoutes.myRides;
  static const String createRide = DriverRoutes.createRide;
  static const String driverBookings = DriverRoutes.bookings;
  static const String homeDriver = DriverRoutes.home;
  static const String loginDriver = DriverRoutes.login;
  static const String splashDriver = DriverRoutes.splash;
  static const String registerDriverStep1 = DriverRoutes.registerStep1;
  static const String driverRideDetails = DriverRoutes.rideDetails;

  // Passenger routes - adding these to fix references in passenger screens
  static const String homePassenger = PassengerRoutes.home;
  static const String loginPassenger = PassengerRoutes.login;
  static const String splashPassenger = PassengerRoutes.splash;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String? routeName = settings.name;

    // Common routes
    if (routeName == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (routeName == role) {
      return MaterialPageRoute(builder: (_) => const RoleScreen());
    } else if (routeName == rideDetails) {
      final ride = settings.arguments;
      return MaterialPageRoute(
        builder: (context) => RideDetailScreen(ride: ride),
      );
    }
    // Passenger routes
    else if (routeName == PassengerRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashPscreen());
    } else if (routeName == PassengerRoutes.login) {
      return MaterialPageRoute(builder: (_) => const LoginPassenger());
    } else if (routeName == PassengerRoutes.home) {
      return MaterialPageRoute(builder: (_) => const HomePscreen());
    } else if (routeName == PassengerRoutes.registerStep1) {
      return MaterialPageRoute(
        builder:
            (context) => RegisterPassengerStep1(
              role: 'PASSENGER',
              onNext:
                  (data) => Navigator.pushNamed(
                    context,
                    PassengerRoutes.registerStep2,
                    arguments: data,
                  ),
            ),
      );
    } else if (routeName == PassengerRoutes.registerStep2) {
      final data = settings.arguments as RegistrationData;
      return MaterialPageRoute(
        builder: (context) => RegisterUserStep2(role: 'PASSENGER', data: data),
      );
    } else if (routeName == PassengerRoutes.profile) {
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    } else if (routeName == PassengerRoutes.editProfile) {
      return MaterialPageRoute(
        builder:
            (context) => EditProfileScreen(
              userProfile:
                  ModalRoute.of(context)!.settings.arguments as UserProfile,
            ),
      );
    }
    // Driver routes
    else if (routeName == DriverRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashDscreen());
    } else if (routeName == DriverRoutes.login) {
      return MaterialPageRoute(builder: (_) => const LoginDriver());
    } else if (routeName == DriverRoutes.home) {
      return MaterialPageRoute(builder: (_) => const HomeDscreen());
    } else if (routeName == DriverRoutes.registerStep1) {
      return MaterialPageRoute(
        builder:
            (context) => RegisterDriverStep1(
              onNext:
                  (data) => Navigator.pushNamed(
                    context,
                    DriverRoutes.registerStep2,
                    arguments: data,
                  ),
            ),
      );
    } else if (routeName == DriverRoutes.registerStep2) {
      final data = settings.arguments as RegistrationData;
      return MaterialPageRoute(
        builder: (context) => RegisterDriverStep2(data: data),
      );
    } else if (routeName == DriverRoutes.profile) {
      return MaterialPageRoute(builder: (_) => const DriverProfileScreen());
    } else if (routeName == DriverRoutes.editProfile) {
      return MaterialPageRoute(
        builder:
            (context) => DriverEditProfileScreen(
              userProfile:
                  ModalRoute.of(context)!.settings.arguments as UserProfile,
            ),
      );
    } else if (routeName == DriverRoutes.createRide) {
      final existingRide = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => CreateRideScreen(existingRide: existingRide),
      );
    } else if (routeName == DriverRoutes.myRides) {
      return MaterialPageRoute(builder: (_) => const MyRidesScreen());
    } else if (routeName == DriverRoutes.bookings) {
      return MaterialPageRoute(builder: (_) => const DriverBookingsScreen());
    } else if (routeName == DriverRoutes.rideDetails) {
      final ride = settings.arguments;
      return MaterialPageRoute(
        builder: (context) => DriverRideDetailScreen(ride: ride),
      );
    }
    // Chat routes
    else if (routeName == chatList) {
      return MaterialPageRoute(builder: (_) => const UserListScreen());
    } else if (routeName == chatRoom) {
      final args = settings.arguments;
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder:
              (_) => ChatRoomScreen(
                roomId: args['roomId'],
                partnerName: args['partnerName'],
                partnerEmail: args['partnerEmail'],
              ),
        );
      }
      return _errorRoute();
    }
    // Default error route
    else {
      return MaterialPageRoute(
        builder:
            (_) => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
      );
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(body: Center(child: Text('Error: Invalid route'))),
    );
  }
}
