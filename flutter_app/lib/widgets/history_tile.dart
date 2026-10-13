import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';

class HistoryTile extends StatelessWidget {
  final DetectionHistory history;

  const HistoryTile({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: history.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: history.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
        ),
        title: Text(
          history.plantName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(history.isHealthy ? 'Healthy' : history.diseaseName),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy - h:mm a').format(history.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: history.isHealthy ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(history.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          // Could navigate to a detailed view in the future
        },
      ),
    );
  }
}
