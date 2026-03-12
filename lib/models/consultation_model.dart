import 'package:json_annotation/json_annotation.dart';

part 'consultation_model.g.dart';

/// 问诊模型
@JsonSerializable()
class ConsultationModel {
  final String id;
  final String userId; // 用户ID
  final String? userName; // 用户姓名
  final String doctorId;
  final String? doctorName;
  final String? doctorAvatar;
  final String? description;
  final String status;
  final DateTime createTime;
  final DateTime? updateTime;
  final List<String>? images;

  // 新增字段 - 对应表单和数据库
  final String consultationType; // 就诊类型：初诊/复诊/咨询
  final String? department; // 就诊科室
  final String consultationMethod; // 咨询方式：文字/语音/视频
  final bool isAnonymous; // 是否匿名咨询
  final String? priceBudget; // 价格预算
  final String urgencyLevel; // 紧急程度：普通/紧急/非常紧急
  final List<String>? symptoms; // 症状标签
  final bool agreeToTerms; // 是否同意服务协议

  ConsultationModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.doctorId,
    this.doctorName,
    this.doctorAvatar,
    this.description,
    required this.status,
    required this.createTime,
    this.updateTime,
    this.images,
    this.consultationType = '初诊',
    this.department,
    this.consultationMethod = '文字',
    this.isAnonymous = false,
    this.priceBudget,
    this.urgencyLevel = '普通',
    this.symptoms,
    this.agreeToTerms = false,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) =>
      _$ConsultationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConsultationModelToJson(this);
}
