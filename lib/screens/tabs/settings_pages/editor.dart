import 'package:flutter/material.dart';
import 'package:solari/theme.dart';
import 'package:solari/main.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  int _selectedMode = 0;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    // Initialize selected mode based on current theme
    _selectedMode = themeModeNotifier.value == ThemeMode.dark ? 0 : 1;
  }

  void _onItemTapped(int mode) {
    setState(() {
      _selectedMode = mode;
    });
    // Update the global theme mode
    themeModeNotifier.value = mode == 0 ? ThemeMode.dark : ThemeMode.light;
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(12.0, 32.0);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(12.0, 32.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<StatusButtonColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font & Display'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Display Mode",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _selectedMode == 0 ? 2 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () => _onItemTapped(0),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Center(
                          child: Icon(
                            Icons.dark_mode,
                            size: 48,
                            color: _selectedMode == 0
                                ? Colors.white
                                : Colors.grey,
                          ),
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
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () => _onItemTapped(1),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Center(
                          child: Icon(
                            Icons.light_mode,
                            size: 48,
                            color: _selectedMode == 1
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Font Size",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: statusColors.leftSelected,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: _decreaseFontSize,
                        borderRadius: BorderRadius.circular(12.0),
                        child: Icon(
                          Icons.remove,
                          size: 48,
                          color: statusColors.iconSelected,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: statusColors.rightSelected,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: _increaseFontSize,
                        borderRadius: BorderRadius.circular(12.0),
                        child: Icon(
                          Icons.add,
                          size: 48,
                          color: statusColors.iconSelected,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Example Text",
                      style: TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}