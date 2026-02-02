import 'package:flutter/material.dart';
import 'package:solari/theme.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  int _selectedMode = 0;

  void _onItemTapped(int mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<StatusButtonColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Icon(Icons.battery_unknown, size: 240),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: _selectedMode == 0 ? 2 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: _selectedMode == 0
                          ? statusColors.leftSelected
                          : statusColors.leftUnselected,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      onTap: () => _onItemTapped(0),
                      borderRadius: BorderRadius.circular(12.0),
                      child: Icon(
                        Icons.phone_android,
                        size: 72,
                        color: _selectedMode == 0
                            ? statusColors.iconSelected
                            : statusColors.iconUnselected,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: _selectedMode == 1 ? 2 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: _selectedMode == 1
                          ? statusColors.rightSelected
                          : statusColors.rightUnselected,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      onTap: () => _onItemTapped(1),
                      borderRadius: BorderRadius.circular(12.0),
                      child: Icon(
                        Icons.visibility,
                        size: 72,
                        color: _selectedMode == 1
                            ? statusColors.iconSelected
                            : statusColors.iconUnselected,
                      ),
                    ),
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