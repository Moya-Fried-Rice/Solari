import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/history_provider.dart';
import '../../core/providers/theme_provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'No history yet.',
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.w500,
                        color: theme.textColor,
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
                      Card(
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
                                  Text(
                                    history[i].text,
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: history[i].sender,
                                          style: TextStyle(
                                            fontSize: theme.fontSize * 0.85,
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' • ${timeAgo(history[i].time)}',
                                          style: TextStyle(
                                            fontSize: theme.fontSize * 0.85,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (i < history.length - 1) _buildDivider(theme),
                    ],
                  ],
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
