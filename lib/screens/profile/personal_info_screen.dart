import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flymfrontend/providers/auth_provider.dart';

/// 个人信息页面
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  int? _selectedAge;
  File? _selectedImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _phoneController.text = user.phone ?? '';
      _selectedGender = user.gender;
      _selectedAge = user.age;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await showModalBottomSheet<XFile>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('拍照'),
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(image);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<void> _selectAge() async {
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempAge = _selectedAge ?? 25;
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('选择年龄'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('当前年龄: $tempAge 岁'),
                    Slider(
                      value: tempAge.toDouble(),
                      min: 1,
                      max: 120,
                      divisions: 119,
                      label: '$tempAge 岁',
                      onChanged: (double value) {
                        setState(() {
                          tempAge = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(tempAge),
                    child: const Text('确定'),
                  ),
                ],
              ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedAge = result;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // final authProvider = context.read<AuthProvider>();

      // TODO: 调用API更新用户信息
      // 创建更新的用户信息对象传给API
      /*
      final updatedUser = UserModel(
        id: authProvider.user!.id,
        phone: authProvider.user!.phone,
        name: _nameController.text.trim(),
        gender: _selectedGender,
        age: _selectedAge,
        avatar: authProvider.user!.avatar,
      );
      await authProvider.updateProfile(updatedUser, avatarFile: _selectedImage);
      */

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('个人信息更新成功')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = user?.avatar;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage:
                _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
            child:
                avatarUrl == null && _selectedImage == null
                    ? Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: _pickImage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              _buildAvatar(),
              const SizedBox(height: 32),

              // 基本信息表单
              const Text(
                '基本信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 姓名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  hintText: '请输入您的姓名',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 手机号（只读）
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone),
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // 性别选择
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: '性别',
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('男')),
                  DropdownMenuItem(value: 'female', child: Text('女')),
                  DropdownMenuItem(value: 'other', child: Text('其他')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 年龄选择
              InkWell(
                onTap: _selectAge,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '年龄',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    _selectedAge != null ? '$_selectedAge 岁' : '请选择年龄',
                    style: TextStyle(
                      color:
                          _selectedAge != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '您的个人信息将被严格保护，仅用于为您提供更好的医疗服务。手机号作为登录账号不可修改。',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
