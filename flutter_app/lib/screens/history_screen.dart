import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<DetectionProvider>().loadHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetectionProvider>();
    final history = provider.history;
    final isLoading = provider.state == DetectionState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
      ),
      body: isLoading && history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = context.read<AuthProvider>().user;
                    if (user != null) {
                      await context.read<DetectionProvider>().loadHistory(user.uid);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return HistoryTile(history: history[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No detections yet.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Scan your first leaf!'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate handled by parent changing tab in real app,
              // for standalone it could push replacement
            },
            child: const Text('Go to Scan'),
          )
        ],
      ),
    );
  }
}
