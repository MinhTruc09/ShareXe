import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final String hintText;
  final IconData icon;
  final DateTime? initialDate;
  final bool includeTime;

  const DatePickerField({
    Key? key,
    required this.onDateSelected,
    required this.hintText,
    required this.icon,
    this.initialDate,
    this.includeTime = true,
  }) : super(key: key);

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
      _updateDisplayText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDisplayText() {
    if (_selectedDate != null) {
      if (widget.includeTime && _selectedTime != null) {
        final DateTime dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        _controller.text = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
        
        _selectedDate = dateTime;
        
        widget.onDateSelected(_selectedDate!);
      } else {
        _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        widget.onDateSelected(_selectedDate!);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00AEEF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && (picked != _selectedDate || _selectedTime == null)) {
      setState(() {
        _selectedDate = picked;
        
        if (_selectedTime == null) {
          _selectedTime = TimeOfDay.now();
        }
        
        if (widget.includeTime) {
          _selectTime(context);
        } else {
          _updateDisplayText();
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00AEEF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Colors.grey[200],
              hourMinuteTextColor: Colors.blue,
              dayPeriodTextColor: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDisplayText();
      });
    } else if (_selectedTime == null) {
      setState(() {
        _selectedTime = TimeOfDay.now();
        _updateDisplayText();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            readOnly: true,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffixIcon: widget.includeTime ? 
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.grey),
                  onPressed: () {
                    if (_selectedDate == null) {
                      _selectDate(context);
                    } else {
                      _selectTime(context);
                    }
                  },
                ) : null,
            ),
            onTap: () => _selectDate(context),
          ),
        ),
      ],
    );
  }
}
