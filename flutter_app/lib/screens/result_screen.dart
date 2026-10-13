import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/disease_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final image = arguments['image'] as XFile;
    final imageBytes = arguments['bytes'] as Uint8List;
    final detectionProvider = context.watch<DetectionProvider>();
    final result = detectionProvider.currentResult;
    
    if (result == null) {
      return const Scaffold(body: Center(child: Text('No result available')));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isHighConfidence = result.confidence >= 0.8;
    final isMedConfidence = result.confidence >= 0.6 && result.confidence < 0.8;
    
    Color confidenceColor = isHighConfidence ? Colors.green : (isMedConfidence ? Colors.orange : Colors.red);
    String confidenceText = isHighConfidence ? 'High Confidence' : (isMedConfidence ? 'Medium Confidence' : 'Low Confidence');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing coming soon!')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (result.isMock)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('MOCK DATA: Backend model not connected.'),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              height: 250,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          result.plantName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: result.isHealthy ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(result.isHealthy ? Icons.check_circle : Icons.coronavirus, 
                                 size: 16, 
                                 color: result.isHealthy ? Colors.green : Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              result.isHealthy ? 'HEALTHY' : 'DISEASED',
                              style: TextStyle(
                                color: result.isHealthy ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!result.isHealthy) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.diseaseName,
                      style: TextStyle(fontSize: 18, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('AI Confidence', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearPercentIndicator(
                          lineHeight: 14.0,
                          percent: result.confidence,
                          backgroundColor: Colors.grey.shade300,
                          progressColor: confidenceColor,
                          barRadius: const Radius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(result.confidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                  Text(confidenceText, style: TextStyle(color: confidenceColor, fontSize: 12)),
                  const SizedBox(height: 24),
                  
                  if (result.diseaseInfo != null)
                    DiseaseCard(diseaseInfo: result.diseaseInfo!),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save to History'),
                      onPressed: () async {
                        final uid = context.read<AuthProvider>().user?.uid;
                        if (uid != null) {
                          await context.read<DetectionProvider>().saveDetection(image, uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved successfully!')),
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
