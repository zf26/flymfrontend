import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/providers/consultation_provider.dart';
import 'package:flymfrontend/models/consultation_model.dart';

/// 问诊列表页
class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().loadConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.consultations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.consultations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadConsultations();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.consultations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medical_services,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无问诊记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.push(AppConstants.routeCreateConsultation);
                    },
                    child: const Text('开始问诊'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshConsultations(),
            child: ListView.builder(
              itemCount: provider.consultations.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.consultations.length) {
                  if (provider.hasMore) {
                    provider.loadConsultations();
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                final consultation = provider.consultations[index];
                return _ConsultationItem(consultation: consultation);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppConstants.routeCreateConsultation);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 问诊列表项
class _ConsultationItem extends StatelessWidget {
  final ConsultationModel consultation;

  const _ConsultationItem({required this.consultation});

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.consultationStatusPending:
        return '待接诊';
      case AppConstants.consultationStatusInProgress:
        return '进行中';
      case AppConstants.consultationStatusCompleted:
        return '已完成';
      case AppConstants.consultationStatusCancelled:
        return '已取消';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.consultationStatusPending:
        return Colors.orange;
      case AppConstants.consultationStatusInProgress:
        return Colors.blue;
      case AppConstants.consultationStatusCompleted:
        return Colors.green;
      case AppConstants.consultationStatusCancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.medical_services)),
        title: Text(consultation.doctorName ?? '医生'),
        subtitle: Text(
          consultation.description ?? '问诊描述',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(
            _getStatusText(consultation.status),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: _getStatusColor(consultation.status),
        ),
        onTap: () {
          context.push(
            '${AppConstants.routeConsultationDetail}/${consultation.id}',
          );
        },
      ),
    );
  }
}
