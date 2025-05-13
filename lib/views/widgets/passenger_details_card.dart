import 'package:flutter/material.dart';
import '../../models/booking.dart';

class PassengerDetailsCard extends StatelessWidget {
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String? passengerAvatarUrl;
  final List<FellowPassenger> fellowPassengers;
  final int totalSeats;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  const PassengerDetailsCard({
    Key? key,
    required this.passengerName,
    required this.passengerPhone,
    required this.passengerEmail,
    this.passengerAvatarUrl,
    this.fellowPassengers = const [],
    required this.totalSeats,
    this.onCall,
    this.onMessage,
  }) : super(key: key);

  // Constructor to create from BookingDTO
  factory PassengerDetailsCard.fromBookingDTO(
    BookingDTO booking, {
    VoidCallback? onCall,
    VoidCallback? onMessage,
    Key? key,
  }) {
    return PassengerDetailsCard(
      key: key,
      passengerName: booking.passengerName,
      passengerPhone: booking.passengerPhone,
      passengerEmail: booking.passengerEmail,
      passengerAvatarUrl: booking.passengerAvatarUrl,
      fellowPassengers: booking.fellowPassengers,
      totalSeats: booking.seatsBooked,
      onCall: onCall,
      onMessage: onMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main passenger info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: passengerAvatarUrl != null && passengerAvatarUrl!.isNotEmpty
                      ? NetworkImage(passengerAvatarUrl!)
                      : null,
                  child: passengerAvatarUrl == null || passengerAvatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Passenger details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            passengerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$totalSeats ghế',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            passengerPhone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            passengerEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Action buttons
            if (onCall != null || onMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onMessage != null)
                      TextButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Nhắn tin'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    if (onCall != null)
                      TextButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Gọi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
              
            // Fellow passengers list
            if (fellowPassengers.isNotEmpty) ...[
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Hành khách đồng hành',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              ...fellowPassengers.map((fellow) => _buildFellowPassengerItem(fellow)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFellowPassengerItem(FellowPassenger fellow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: fellow.avatarUrl != null && fellow.avatarUrl!.isNotEmpty
                ? NetworkImage(fellow.avatarUrl!)
                : null,
            child: fellow.avatarUrl == null || fellow.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fellow.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fellow.phone != null)
                  Text(
                    fellow.phone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 