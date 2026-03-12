import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/models/consultation_recommendation_model.dart';
import 'package:flymfrontend/providers/consultation_provider.dart';

/// 推荐结果页面
/// 显示NLP分析后的推荐科室、医生、疾病概率等信息
class RecommendationScreen extends StatefulWidget {
  final ConsultationRecommendation recommendation;

  const RecommendationScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  bool _isCreatingConsultation = false;
  DoctorRecommendation? _selectedDoctor;

  Future<void> _createConsultation() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择医生')),
      );
      return;
    }

    setState(() {
      _isCreatingConsultation = true;
    });

    try {
      final provider = context.read<ConsultationProvider>();
      final success = await provider.createConsultation(
        doctorId: _selectedDoctor!.doctorId,
        description: widget.recommendation.symptomDescription,
        consultationType: '初诊',
        department: _selectedDoctor!.department,
        consultationMethod: '文字',
        symptoms: widget.recommendation.diseases
            .expand((disease) => disease.symptoms)
            .toList(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('问诊创建成功')),
          );
          context.go(AppConstants.routeHome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? '创建问诊失败')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingConsultation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析结果'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 症状描述
            _buildSymptomSummary(),
            const SizedBox(height: 24),

            // 疾病概率
            if (widget.recommendation.diseases.isNotEmpty) ...[
              _buildDiseaseRecommendations(),
              const SizedBox(height: 24),
            ],

            // 推荐科室
            if (widget.recommendation.departments.isNotEmpty) ...[
              _buildDepartmentRecommendations(),
              const SizedBox(height: 24),
            ],

            // 推荐医生
            if (widget.recommendation.doctors.isNotEmpty) ...[
              _buildDoctorRecommendations(),
              const SizedBox(height: 32),
            ],

            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomSummary() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '您的症状描述',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.recommendation.symptomDescription,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '可能的疾病',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recommendation.diseases.map((disease) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            disease.diseaseName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getProbabilityColor(disease.probability),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(disease.probability * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      disease.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (disease.treatments.isNotEmpty) ...[
                      const Text(
                        '推荐治疗方案',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...disease.treatments.map((treatment) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        treatment.method,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(treatment.successRate * 100).toStringAsFixed(1)}% 成功率',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (treatment.duration.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '治疗周期: ${treatment.duration}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (treatment.medications.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '推荐药物: ${treatment.medications.join('、')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDepartmentRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '推荐就诊科室',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recommendation.departments.map((dept) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.local_hospital,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  dept.departmentName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(dept.description),
                trailing: Text(
                  '${(dept.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDoctorRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '推荐医生',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recommendation.doctors.map((doctor) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile<DoctorRecommendation>(
                value: doctor,
                groupValue: _selectedDoctor,
                onChanged: (value) {
                  setState(() {
                    _selectedDoctor = value;
                  });
                },
                title: Text(
                  doctor.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${doctor.title} · ${doctor.department}'),
                    Text('${doctor.hospital} · ${doctor.specialty}'),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          '${doctor.rating.toStringAsFixed(1)} (${doctor.consultationCount}次咨询)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                secondary: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    doctor.doctorName.substring(0, 1),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedDoctor != null && !_isCreatingConsultation
                ? _createConsultation
                : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isCreatingConsultation
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    '创建问诊单',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              context.go(AppConstants.routeHome);
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text(
              '先看看其他医生',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 0.7) return Colors.red;
    if (probability >= 0.4) return Colors.orange;
    return Colors.green;
  }
}
