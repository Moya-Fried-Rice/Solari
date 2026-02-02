// Bottom Navigation Bar Home Screen
// Actions:
// 1. Navigate to 2 tabs: Solari and Settings
// 2. Create new chat in Solari tab (tap and hold Solari tab)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:solari/screens/tabs/solari.dart';
import 'package:solari/screens/tabs/settings.dart';
import 'package:solari/screens/tabs/chat.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  String? _chatText;
  File? _chatImage;

  List<Widget> get _widgetOptions => [
    SolariTab(chatText: _chatText, chatImage: _chatImage),
    const SettingsTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: GestureDetector(
          onLongPress: () async {
            if (_selectedIndex == 0) {
              final ImagePicker picker = ImagePicker();
              final ImageSource? source = await showDialog<ImageSource>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Image Source'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Gallery'),
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Camera'),
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (source != null && mounted) {
                final XFile? image = await picker.pickImage(source: source);
                if (image != null && mounted) {
                  final imageFile = File(image.path);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          imageFile: imageFile,
                          onRecordingComplete: (text, file) {
                            setState(() {
                              _chatText = text;
                              _chatImage = file;
                              _selectedIndex = 0;
                            });
                          },
                        ),
                      ),
                    );
                  }
                }
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: _selectedIndex == 0 ? 2 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 
                        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: InkWell(
                    onTap: () => _onItemTapped(0),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Icon(
                      Icons.home,
                      size: 72,
                      color: _selectedIndex == 0
                          ? Theme.of(context).bottomNavigationBarTheme.selectedIconTheme?.color
                          : Theme.of(context).bottomNavigationBarTheme.unselectedIconTheme?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: _selectedIndex == 1 ? 2 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 
                        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: InkWell(
                    onTap: () => _onItemTapped(1),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Icon(
                      Icons.settings,
                      size: 72,
                      color: _selectedIndex == 1
                          ? Theme.of(context).bottomNavigationBarTheme.selectedIconTheme?.color
                          : Theme.of(context).bottomNavigationBarTheme.unselectedIconTheme?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}