import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flymfrontend/providers/doctor_provider.dart';
import 'package:flymfrontend/models/doctor_model.dart';

/// 医生列表页
class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    if (keyword.isEmpty) {
      context.read<DoctorProvider>().refreshDoctors();
    } else {
      context.read<DoctorProvider>().searchDoctors(keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择医生'), elevation: 0),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索医生姓名、科室',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _onSearch,
              onSubmitted: _onSearch,
            ),
          ),
          // 医生列表
          Expanded(
            child: Consumer<DoctorProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.doctors.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.doctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.refreshDoctors();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.doctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无医生',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshDoctors(),
                  child: ListView.builder(
                    itemCount: provider.doctors.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.doctors.length) {
                        if (provider.hasMore) {
                          provider.loadDoctors();
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

                      final doctor = provider.doctors[index];
                      return _DoctorItem(doctor: doctor);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 医生列表项
class _DoctorItem extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorItem({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // 返回选中的医生
          context.pop(doctor);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 头像
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child:
                    doctor.avatar != null && doctor.avatar!.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: doctor.avatar!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40),
                              ),
                        )
                        : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 40),
                        ),
              ),
              const SizedBox(width: 16),
              // 医生信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (doctor.title != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        doctor.title!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    if (doctor.department != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.department!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (doctor.rating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (doctor.consultationCount != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              '${doctor.consultationCount}次问诊',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
