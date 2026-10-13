import 'package:flutter/material.dart';
import '../models/prediction_model.dart';

class DiseaseCard extends StatefulWidget {
  final DiseaseInfo diseaseInfo;
  
  const DiseaseCard({super.key, required this.diseaseInfo});

  @override
  State<DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<DiseaseCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: const Text('Disease Information', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Description', widget.diseaseInfo.description),
                  const SizedBox(height: 16),
                  _buildListSection('Symptoms', widget.diseaseInfo.symptoms),
                  const SizedBox(height: 16),
                  _buildSection('Causes', widget.diseaseInfo.causes),
                  const SizedBox(height: 16),
                  _buildListSection('Management', widget.diseaseInfo.management, isNumbered: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items, {bool isNumbered = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          String text = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isNumbered
                    ? Text('${idx + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                    : const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Expanded(child: Text(text)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
