import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideSearchCard extends StatefulWidget {
  final Function(String, String, DateTime?) onSearch;

  const RideSearchCard({
    Key? key,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<RideSearchCard> createState() => _RideSearchCardState();
}

class _RideSearchCardState extends State<RideSearchCard> {
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002D72),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Departure field
            TextField(
              controller: _departureController,
              decoration: const InputDecoration(
                hintText: 'Điểm đi',
                prefixIcon: Icon(Icons.circle_outlined, color: Color(0xFF002D72)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Destination field
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                hintText: 'Điểm đến',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF002D72)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Date selection field
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF002D72)),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null
                          ? 'Chọn ngày khởi hành'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSearch(
                    _departureController.text,
                    _destinationController.text,
                    _selectedDate,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Tìm chuyến',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 