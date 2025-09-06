import 'package:flutter/material.dart';

// Common screens
import 'views/screens/common/splash_screen.dart';
import 'views/screens/common/role_screen.dart';
import 'views/screens/common/ride_details.dart';
import 'views/screens/common/forgot_password_screen.dart';

// Passenger screens
import 'views/screens/passenger/splash_pscreen.dart';
import 'views/screens/passenger/login_passenger.dart';
import 'views/screens/passenger/register_passenger_step1.dart';
import 'views/screens/passenger/register_user_step2.dart';
import 'views/screens/passenger/profile_screen.dart' as passenger;
import 'views/screens/passenger/edit_profile_screen.dart';
import 'views/screens/passenger/passenger_main_screen.dart';
import 'views/screens/passenger/passenger_bookings_screen.dart';

// Driver screens
import 'views/screens/driver/splash_dscreen.dart';
import 'views/screens/driver/login_driver.dart';
import 'views/screens/driver/register_driver_step1.dart';
import 'views/screens/driver/register_driver_step2.dart';
import 'views/screens/driver/edit_profile_screen.dart';
import 'views/screens/driver/create_ride_screen.dart';
import 'views/screens/driver/my_rides_screen.dart';
import 'views/screens/driver/driver_bookings_screen.dart';
import 'views/screens/driver/driver_ride_detail_screen.dart';
import 'views/screens/driver/driver_main_screen.dart';
import 'views/screens/driver/driver_profile_screen.dart';

// Chat screens
import 'views/screens/chat/user_list_screen.dart';
import 'views/screens/chat/chat_room_screen.dart';

// Notification screens
import 'views/screens/notifications/notifications_screen.dart';
import 'views/screens/notifications/notification_tabs_screen.dart';

// Models
import 'models/registration_data.dart';
import 'models/user_profile.dart';
import 'models/ride.dart';

// Services
import 'services/ride_service.dart';

// Passenger routes namespace
class PassengerRoutes {
  static const String splash = '/passenger/splash';
  static const String login = '/passenger/login';
  static const String home = '/passenger/home';
  static const String registerStep1 = '/passenger/register-step1';
  static const String registerStep2 = '/passenger/register-step2';
  static const String profile = '/passenger/profile';
  static const String editProfile = '/passenger/edit-profile';
  static const String bookings = '/passenger/bookings';
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
  static const String forgotPassword = '/forgot-password';

  // Notification routes
  static const String notifications = '/notifications';
  static const String notificationTabs = '/notification-tabs';

  // Chat routes
  static const String chatRoom = '/chat_room';
  static const String chatList = '/chat_list';
  static const String chatUserList = '/chat/user-list';

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
  static const String passengerBookings = PassengerRoutes.bookings;
  static const String passengerMainScreen = PassengerRoutes.home;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String? routeName = settings.name;

    // Root route and common routes
    if (routeName == '/' || routeName == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (routeName == role) {
      return MaterialPageRoute(builder: (_) => const RoleScreen());
    } else if (routeName == rideDetails) {
      final arguments = settings.arguments;

      // Nếu arguments là Map chứa rideId, cần lấy thông tin chuyến đi từ API
      if (arguments is Map<String, dynamic> &&
          arguments.containsKey('rideId')) {
        final rideId = arguments['rideId'] as int;
        final rideService = RideService();
        return MaterialPageRoute(
          builder:
              (context) => FutureBuilder<Ride?>(
                future: rideService.getRideDetails(rideId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Lỗi')),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text('Không thể tải thông tin chuyến đi'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Quay lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return RideDetailScreen(ride: snapshot.data!);
                  }
                },
              ),
        );
      } else {
        // Trường hợp arguments là ride object trực tiếp (backward compatibility)
        final ride = arguments;
        return MaterialPageRoute(
          builder: (context) => RideDetailScreen(ride: ride),
        );
      }
    } else if (routeName == forgotPassword) {
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    } else if (routeName == notifications) {
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    } else if (routeName == notificationTabs) {
      return MaterialPageRoute(builder: (_) => const NotificationTabsScreen());
    }
    // Passenger routes
    else if (routeName == PassengerRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashPscreen());
    } else if (routeName == PassengerRoutes.login) {
      return MaterialPageRoute(builder: (_) => const LoginPassenger());
    } else if (routeName == PassengerRoutes.home) {
      return MaterialPageRoute(builder: (_) => const PassengerMainScreen());
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
      return MaterialPageRoute(builder: (_) => const passenger.ProfileScreen());
    } else if (routeName == PassengerRoutes.editProfile) {
      return MaterialPageRoute(
        builder:
            (context) => EditProfileScreen(
              userProfile:
                  ModalRoute.of(context)!.settings.arguments as UserProfile,
            ),
      );
    } else if (routeName == PassengerRoutes.bookings) {
      return MaterialPageRoute(builder: (_) => const PassengerBookingsScreen());
    }
    // Driver routes
    else if (routeName == DriverRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashDscreen());
    } else if (routeName == DriverRoutes.login) {
      return MaterialPageRoute(builder: (_) => const LoginDriver());
    } else if (routeName == DriverRoutes.home) {
      return MaterialPageRoute(builder: (_) => const DriverMainScreen());
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
      final userProfile = settings.arguments;
      if (userProfile is UserProfile) {
        return MaterialPageRoute(
          builder:
              (context) => DriverEditProfileScreen(userProfile: userProfile),
        );
      } else {
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: const Center(
                  child: Text(
                    'Không thể tải thông tin hồ sơ. Vui lòng thử lại sau.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        );
      }
    } else if (routeName == DriverRoutes.createRide) {
      final existingRide = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => CreateRideScreen(existingRide: existingRide),
      );
    } else if (routeName == DriverRoutes.myRides) {
      return MaterialPageRoute(builder: (_) => const MyRidesScreen());
    } else if (routeName == DriverRoutes.bookings) {
      // Check if a ride object was passed as argument
      final ride = settings.arguments as Map<String, dynamic>?;
      if (ride != null) {
        // Create a simple Ride object from the map data
        final rideObj = Ride(
          id: ride['id'] ?? 0,
          departure: ride['fromLocation'] ?? ride['departure'] ?? 'Điểm đi',
          startLat:
              ride['startLat'] != null
                  ? (ride['startLat'] as num).toDouble()
                  : 0.0,
          startLng:
              ride['startLng'] != null
                  ? (ride['startLng'] as num).toDouble()
                  : 0.0,
          startAddress: ride['startAddress'] ?? '',
          startWard: ride['startWard'] ?? '',
          startDistrict: ride['startDistrict'] ?? '',
          startProvince: ride['startProvince'] ?? '',
          endLat:
              ride['endLat'] != null ? (ride['endLat'] as num).toDouble() : 0.0,
          endLng:
              ride['endLng'] != null ? (ride['endLng'] as num).toDouble() : 0.0,
          endAddress: ride['endAddress'] ?? '',
          endWard: ride['endWard'] ?? '',
          endDistrict: ride['endDistrict'] ?? '',
          endProvince: ride['endProvince'] ?? '',
          destination: ride['toLocation'] ?? ride['destination'] ?? 'Điểm đến',
          startTime: ride['startTime'] ?? DateTime.now().toIso8601String(),
          totalSeat: ride['totalSeat'] ?? 0,
          status: ride['status'] ?? 'ACTIVE',
          driverEmail: ride['driverEmail'] ?? 'no-email@example.com',
          driverName: ride['driverName'] ?? 'Tài xế',
          availableSeats: ride['availableSeats'] ?? 0,
          pricePerSeat: ride['pricePerSeat'],
        );
        return MaterialPageRoute(
          builder: (_) => DriverBookingsScreen(ride: rideObj),
        );
      } else {
        // Return error page if no ride data is provided
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: const Center(child: Text('Không có dữ liệu chuyến đi')),
              ),
        );
      }
    } else if (routeName == DriverRoutes.rideDetails) {
      final ride = settings.arguments;
      return MaterialPageRoute(
        builder: (context) => DriverRideDetailScreen(ride: ride),
      );
    }
    // Chat routes
    else if (routeName == chatList) {
      return MaterialPageRoute(builder: (_) => const UserListScreen());
    } else if (routeName == chatUserList) {
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
    // Additional routes for hardcoded paths
    else if (routeName == '/driver/bookings') {
      // Create a default ride object for the bookings screen
      final defaultRide = Ride(
        id: 0,
        departure: 'Tất cả điểm đi',
        startLat: 0.0,
        startLng: 0.0,
        startAddress: '',
        startWard: '',
        startDistrict: '',
        startProvince: '',
        endLat: 0.0,
        endLng: 0.0,
        endAddress: '',
        endWard: '',
        endDistrict: '',
        endProvince: '',
        destination: 'Tất cả điểm đến',
        startTime: DateTime.now().toIso8601String(),
        totalSeat: 0,
        status: 'ACTIVE',
        availableSeats: 0,
        driverName: 'Tài xế',
        driverEmail: 'example@sharexe.com',
        pricePerSeat: null,
      );
      return MaterialPageRoute(
        builder: (_) => DriverBookingsScreen(ride: defaultRide),
      );
    } else if (routeName == '/driver/profile') {
      return MaterialPageRoute(builder: (_) => const DriverProfileScreen());
    } else if (routeName == '/driver/edit-profile') {
      final userProfile = settings.arguments;
      if (userProfile is UserProfile) {
        return MaterialPageRoute(
          builder:
              (context) => DriverEditProfileScreen(userProfile: userProfile),
        );
      } else {
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: const Center(
                  child: Text(
                    'Không thể tải thông tin hồ sơ. Vui lòng thử lại sau.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        );
      }
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
