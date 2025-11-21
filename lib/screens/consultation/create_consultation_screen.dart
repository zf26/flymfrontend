import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flymfrontend/providers/consultation_provider.dart';
import 'package:flymfrontend/services/api/upload_service.dart';
import 'package:flymfrontend/core/di/service_locator.dart';
import 'package:flymfrontend/models/doctor_model.dart';
import 'package:flymfrontend/config/app_constants.dart';

/// 创建问诊页面
class CreateConsultationScreen extends StatefulWidget {
  final String? doctorId;

  const CreateConsultationScreen({super.key, this.doctorId});

  @override
  State<CreateConsultationScreen> createState() =>
      _CreateConsultationScreenState();
}

class _CreateConsultationScreenState extends State<CreateConsultationScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final UploadService _uploadService = UploadService(
    ServiceLocator().getApiService(),
  );
  final List<String> _uploadedImageUrls = [];
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;
  bool _isSubmitting = false;
  DoctorModel? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    if (widget.doctorId != null) {
      _loadDoctor();
    }
  }

  Future<void> _loadDoctor() async {
    try {
      final doctorService = ServiceLocator().getDoctorService();
      final result = await doctorService.getDoctorDetail(widget.doctorId!);
      if (result.success && result.data != null) {
        setState(() {
          _selectedDoctor = result.data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载医生信息失败: $e')));
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await ImagePicker().pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        _uploadImages(images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        _uploadImages([image]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拍照失败: $e')));
      }
    }
  }

  Future<void> _uploadImages(List<XFile> images) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _uploadService.uploadImages(images);
      if (result.success && result.data != null) {
        setState(() {
          _uploadedImageUrls.addAll(result.data!);
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('上传图片失败: ${result.message}')));
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('上传图片失败: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  Future<void> _selectDoctor() async {
    final result = await context.push<DoctorModel>(
      AppConstants.routeDoctorList,
    );
    if (result != null) {
      setState(() {
        _selectedDoctor = result;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择医生')));
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入问诊描述')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<ConsultationProvider>();
    final success = await provider.createConsultation(
      doctorId: _selectedDoctor!.id,
      description: _descriptionController.text.trim(),
      images: _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : null,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('创建问诊成功')));
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? '创建问诊失败')),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建问诊'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择医生
            Card(
              child: InkWell(
                onTap: _selectDoctor,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            _selectedDoctor == null
                                ? const Text(
                                  '请选择医生',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDoctor!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedDoctor!.department != null)
                                      Text(
                                        _selectedDoctor!.department!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 问诊描述
            const Text(
              '问诊描述',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '请详细描述您的症状、病史等信息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),
            // 上传图片
            const Text(
              '上传图片（可选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 图片网格
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddImageButton();
                  }
                  return _buildImageItem(index);
                },
              )
            else
              _buildAddImageButton(),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 32),
            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('提交问诊', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder:
              (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('从相册选择'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('拍照'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                  ],
                ),
              ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text('添加图片', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final image = _selectedImages[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(image.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (index < _uploadedImageUrls.length)
          const Positioned(
            bottom: 4,
            left: 4,
            child: Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
      ],
    );
  }
}
