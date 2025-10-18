import 'package:flutter/material.dart';
import '../../widgets/select_to_speak_text.dart';
import '../../widgets/screen_reader_gesture_detector.dart';
import 'package:provider/provider.dart';

import '../../core/providers/history_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/screen_reader_focusable.dart';

String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return '0m ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Helper method to get text shadows for high contrast mode
  List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;
    final shadowColor = theme.isDarkMode ? Colors.white : Colors.black;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 3.0, color: shadowColor),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final history = Provider.of<HistoryProvider>(context).history;
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: ScreenReaderGestureDetector(
        child: GestureDetector(
          onTap: () {
            clearSelectToSpeakSelection();
          },
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    SelectToSpeakText(
                      'No history yet.',
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.w500,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    for (int i = 0; i < history.length; i++) ...[
                      ScreenReaderFocusable(
                        label: 'History entry ${i + 1}',
                        hint: '${history[i].sender} said: ${history[i].text}, ${timeAgo(history[i].time)}',
                        child: Card(
                          shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0.0),
                            topRight: Radius.circular(0.0),
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                          side: BorderSide(color: theme.primaryColor, width: 5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.memory(
                              history[i].image,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show the text/response from Solari
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.smart_toy,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectToSpeakText(
                                          history[i].text,
                                          style: TextStyle(
                                            fontSize: theme.fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                            shadows: _getTextShadows(theme),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      SelectToSpeakText(
                                        history[i].sender,
                                        style: TextStyle(
                                          fontSize: theme.fontSize * 0.85,
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          shadows: _getTextShadows(theme),
                                        ),
                                      ),
                                      SelectToSpeakText(
                                        ' • ${timeAgo(history[i].time)}',
                                        style: TextStyle(
                                          fontSize: theme.fontSize * 0.85,
                                          color: Colors.grey[600],
                                          shadows: _getTextShadows(theme),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                      const SizedBox(height: 16),
                      if (i < history.length - 1) _buildDivider(theme),
                    ],
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider theme) => Column(
    children: [
      Container(
        height: 10,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

