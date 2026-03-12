import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/services/api/symptom_analysis_service.dart';
import 'package:flymfrontend/core/di/service_locator.dart';

/// 症状输入页面
/// 用户输入症状描述，调用NLP接口进行分析
class SymptomInputScreen extends StatefulWidget {
  final bool showAppBar;

  const SymptomInputScreen({super.key, this.showAppBar = true});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final SymptomAnalysisService _analysisService = SymptomAnalysisService(
    ServiceLocator().getApiService(),
  );

  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSymptoms() async {
    final symptomText = _symptomController.text.trim();

    if (symptomText.isEmpty) {
      setState(() {
        _errorMessage = '请输入症状描述';
      });
      return;
    }

    if (symptomText.length < 5) {
      setState(() {
        _errorMessage = '症状描述至少需要5个字符';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final recommendation = await _analysisService.analyzeSymptoms(
        symptomText,
      );

      if (mounted) {
        // 导航到推荐结果页面
        context.pushNamed(
          AppConstants.routeConsultationRecommendation,
          extra: recommendation,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '分析失败，请稍后重试: $e';
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: const Text('症状描述'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context.pop();
                  },
                ),
                elevation: 0,
              )
              : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              '请描述您的症状',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '详细描述您的症状表现、持续时间、严重程度等信息，我们将为您提供专业的医疗建议',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // 症状输入框
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _symptomController,
                maxLines: 8,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '例如：我最近总是打喷嚏，流鼻涕，眼睛发痒，持续了三天...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
                onChanged: (value) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
            ),

            // 字数提示
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_symptomController.text.length}/500',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),

            const SizedBox(height: 16),

            // 错误提示
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // 分析按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeSymptoms,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child:
                    _isAnalyzing
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          '开始分析',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 24),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '温馨提示',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 请详细描述症状表现和持续时间\n• 包含相关的生活习惯和既往病史\n• 我们的AI将基于专业医学知识进行分析\n• 分析结果仅供参考，建议结合医生诊断',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
