import 'package:flutter/material.dart';

/// 问诊详情页
class ConsultationDetailScreen extends StatefulWidget {
  final String consultationId;

  const ConsultationDetailScreen({super.key, required this.consultationId});

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '问诊信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('问诊ID: ${widget.consultationId}'),
                    // TODO: 显示问诊详情
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
