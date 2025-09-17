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
        padding: const EdgeInsets.all(16.0),
        child: history.isEmpty
            ? const Center(child: Text('No history yet.'))
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    for (var entry in history) ...[
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.memory(
                              entry.image,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              entry.text,
                              style: TextStyle(
                                fontSize: theme.fontSize,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${entry.sender} • ${timeAgo(entry.time)}',
                              style: TextStyle(
                                fontSize: theme.fontSize * 0.85,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
