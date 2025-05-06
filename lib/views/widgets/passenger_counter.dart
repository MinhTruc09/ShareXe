import 'package:flutter/material.dart';

class PassengerCounter extends StatefulWidget {
  final Function(int) onCountChanged;
  final int initialCount;
  final int maxCount;
  final IconData icon;
  final String hintText;

  const PassengerCounter({
    Key? key,
    required this.onCountChanged,
    this.initialCount = 1,
    this.maxCount = 10,
    required this.icon,
    required this.hintText,
  }) : super(key: key);

  @override
  State<PassengerCounter> createState() => _PassengerCounterState();
}

class _PassengerCounterState extends State<PassengerCounter> {
  late int _count;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _updateDisplay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementCount() {
    if (_count < widget.maxCount) {
      setState(() {
        _count++;
        _updateDisplay();
        widget.onCountChanged(_count);
      });
    }
  }

  void _decrementCount() {
    if (_count > 1) {
      setState(() {
        _count--;
        _updateDisplay();
        widget.onCountChanged(_count);
      });
    }
  }

  void _updateDisplay() {
    _controller.text = '$_count người';
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
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _decrementCount,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.remove, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _incrementCount,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AEEF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 