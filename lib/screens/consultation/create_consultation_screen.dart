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
  final bool showAppBar;

  const CreateConsultationScreen({super.key, this.doctorId, this.showAppBar = true});

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

  // 新增表单字段 - 针对年轻人优化
  String _consultationType = '初诊'; // 初诊/复诊/咨询
  String? _selectedDepartment;
  String _consultationMethod = '文字'; // 文字/语音/视频
  bool _isAnonymous = false;
  String? _priceBudget;
  String _urgencyLevel = '普通'; // 普通/紧急/非常紧急
  List<String> _selectedSymptoms = [];
  bool _agreeToTerms = false;

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

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择就诊科室')));
      return;
    }

    if (_descriptionController.text.trim().isEmpty &&
        _selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写问诊描述或选择症状标签')));
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请同意隐私政策和服务协议')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 组合问诊描述
    String fullDescription = '';
    if (_selectedSymptoms.isNotEmpty) {
      fullDescription += '症状标签：${_selectedSymptoms.join('、')}\n\n';
    }
    fullDescription += _descriptionController.text.trim();

    final provider = context.read<ConsultationProvider>();
    final success = await provider.createConsultation(
      doctorId: _selectedDoctor!.id,
      description: fullDescription,
      images: _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : null,
      consultationType: _consultationType,
      department: _selectedDepartment,
      consultationMethod: _consultationMethod,
      isAnonymous: _isAnonymous,
      priceBudget: _priceBudget,
      urgencyLevel: _urgencyLevel,
      symptoms: _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      agreeToTerms: _agreeToTerms,
    );

    // 调试：打印新增字段信息
    if (success) {
      debugPrint('=== 问诊创建成功，详细信息 ===');
      debugPrint('就诊类型: $_consultationType');
      debugPrint('科室: $_selectedDepartment');
      debugPrint('咨询方式: $_consultationMethod');
      debugPrint('匿名咨询: $_isAnonymous');
      debugPrint('价格预算: $_priceBudget');
      debugPrint('紧急程度: $_urgencyLevel');
      debugPrint('症状标签: $_selectedSymptoms');
      debugPrint('同意协议: $_agreeToTerms');
      debugPrint('========================');
    }

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
      appBar: widget.showAppBar ? AppBar(title: const Text('创建问诊'), elevation: 0) : null,
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

            // 就诊类型
            const Text(
              '就诊类型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children:
                  ['初诊', '复诊', '咨询'].map((type) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: _consultationType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _consultationType = type);
                            }
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // 科室选择
            const Text(
              '就诊科室',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ['内科', '皮肤科', '心理咨询', '运动康复', '眼科', '口腔科', '妇科', '其他'].map((
                    department,
                  ) {
                    return FilterChip(
                      label: Text(department),
                      selected: _selectedDepartment == department,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDepartment = selected ? department : null;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // 常见症状标签
            const Text(
              '常见症状（可多选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    '头痛',
                    '失眠',
                    '焦虑',
                    '皮肤问题',
                    '胃部不适',
                    '关节痛',
                    '疲劳',
                    '情绪低落',
                    '感冒',
                    '过敏',
                    '便秘',
                    '月经不调',
                    '其他',
                  ].map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom);
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
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

            // 匿名咨询选项
            Card(
              child: SwitchListTile(
                title: const Text('匿名咨询'),
                subtitle: const Text('医生将看不到您的真实姓名'),
                value: _isAnonymous,
                onChanged: (value) => setState(() => _isAnonymous = value),
                secondary: Icon(
                  _isAnonymous ? Icons.visibility_off : Icons.visibility,
                  color:
                      _isAnonymous
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 紧急程度
            const Text(
              '紧急程度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

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
            const SizedBox(height: 16),

            // 隐私协议勾选
            Card(
              child: CheckboxListTile(
                title: const Text('我已阅读并同意'),
                subtitle: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 打开隐私政策页面
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('隐私政策页面开发中')),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('《隐私政策》'),
                    ),
                    const Text('和'),
                    TextButton(
                      onPressed: () {
                        // TODO: 打开服务协议页面
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('服务协议页面开发中')),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('《服务协议》'),
                    ),
                  ],
                ),
                value: _agreeToTerms,
                onChanged:
                    (value) => setState(() => _agreeToTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
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
