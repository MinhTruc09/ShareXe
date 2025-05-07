import 'package:flutter/material.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/role_screen.dart';
import 'views/screens/passenger/splash_pscreen.dart';
import 'views/screens/passenger/login_passenger.dart';
import 'views/screens/passenger/home_pscreen.dart';
import 'views/screens/passenger/register_passenger_step1.dart';
import 'views/screens/passenger/register_user_step2.dart';
import 'views/screens/passenger/profile_screen.dart';
import 'views/screens/driver/splash_dscreen.dart';
import 'views/screens/driver/login_driver.dart';
import 'views/screens/driver/home_dscreen.dart';
import 'views/screens/driver/register_driver_step1.dart';
import 'views/screens/driver/register_driver_step2.dart';
import 'models/registration_data.dart';
import 'models/user_profile.dart';
import 'views/screens/ride_details.dart';
import 'views/screens/passenger/edit_profile_screen.dart';
import 'views/screens/driver/edit_profile_screen.dart';
import 'views/screens/driver/profile_screen.dart';
import 'views/screens/driver/post_ride_screen.dart';
import 'views/screens/chat/chat_list_screen.dart';
import 'views/screens/chat/chat_detail_screen.dart';
import 'models/driver_profile.dart';

class AppRoute {
  static const String splash = '/splash';
  static const String role = '/role';
  
  // Passenger routes
  static const String splashPassenger = '/splash-passenger';
  static const String loginPassenger = '/login-passenger';
  static const String homePassenger = '/home-passenger';
  static const String registerPassengerStep1 = '/register-passenger-step1';
  static const String registerUserStep2 = '/register-user-step2';
  static const String profilePassenger = '/profile-passenger';
  static const String rideDetails = '/ride-details';
  static const String editProfilePassenger = '/edit-profile-passenger';
  
  // Driver routes
  static const String splashDriver = '/splash-driver';
  static const String loginDriver = '/login-driver';
  static const String homeDriver = '/home-driver';
  static const String registerDriverStep1 = '/register-driver-step1';
  static const String registerDriverStep2 = '/register-driver-step2';
  static const String profileDriver = '/profile-driver';
  static const String editProfileDriver = '/edit-profile-driver';
  static const String postRide = '/post-ride';

  // Add route constants
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';

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
      
      case profilePassenger:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case rideDetails:
        final ride = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => RideDetailScreen(ride: ride),
        );
      
      case editProfilePassenger:
        return MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            userProfile: ModalRoute.of(context)!.settings.arguments as UserProfile,
          ),
        );
      
      // Driver routes
      case splashDriver:
        return MaterialPageRoute(builder: (_) => const SplashDscreen());
      case loginDriver:
        return MaterialPageRoute(builder: (_) => const LoginDriver());
      case homeDriver:
        return MaterialPageRoute(builder: (_) => const HomeDscreen());
      case postRide:
        return MaterialPageRoute(builder: (_) => const PostRideScreen());
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
      
      case profileDriver:
        return MaterialPageRoute(builder: (_) => const DriverProfileScreen());
      
      case editProfileDriver:
        return MaterialPageRoute(
          builder: (context) => DriverEditProfileScreen(
            userProfile: ModalRoute.of(context)!.settings.arguments as DriverProfile,
          ),
        );
        
      // Chat routes
      case chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case chatDetail:
        final chatRoomId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatRoomId: chatRoomId),
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