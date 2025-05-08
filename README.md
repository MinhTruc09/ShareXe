# ShareXe Mobile App

ShareXe is a carpooling application that connects passengers with drivers for ride-sharing.

## Project Structure

The project is organized with a clear separation between passenger and driver workflows:

### Directory Structure

```
lib/
├── app_route.dart             # Routing with separate namespaces for driver and passenger
├── main.dart                  # App initialization
├── services/                  # API services and business logic
├── models/                    # Data models
├── controllers/               # Controllers for state management
├── utils/                     # Utility functions and helpers
└── views/                     # UI components
    ├── screens/               # App screens
    │   ├── common/            # Shared screens (splash, role selection, etc.)
    │   ├── passenger/         # Passenger-specific screens
    │   ├── driver/            # Driver-specific screens
    │   └── chat/              # Chat functionality screens
    ├── widgets/               # Reusable UI components
    └── theme/                 # Theme configuration
```

### Route Organization

Routes are organized by user role:

- **Common Routes**: Used by both passengers and drivers (splash screen, role selection)
- **PassengerRoutes**: Namespace for passenger-specific screens
- **DriverRoutes**: Namespace for driver-specific screens

## Features

### Passenger Features
- Authentication (login/register)
- Browse available rides
- Book rides
- View booking history
- Chat with drivers

### Driver Features
- Authentication (login/register)
- Create and manage rides
- Accept/reject booking requests
- View ride history
- Chat with passengers

## Development

This application is built with Flutter and communicates with a Java Spring Boot backend API.
