/// 问诊推荐结果模型
class ConsultationRecommendation {
  final String symptomDescription;
  final List<DiseaseRecommendation> diseases;
  final List<DepartmentRecommendation> departments;
  final List<DoctorRecommendation> doctors;

  const ConsultationRecommendation({
    required this.symptomDescription,
    required this.diseases,
    required this.departments,
    required this.doctors,
  });

  factory ConsultationRecommendation.fromJson(Map<String, dynamic> json) {
    return ConsultationRecommendation(
      symptomDescription: json['symptomDescription'] as String? ?? '',
      diseases:
          (json['diseases'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DiseaseRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      departments:
          (json['departments'] as List<dynamic>?)
              ?.map(
                (e) => DepartmentRecommendation.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      doctors:
          (json['doctors'] as List<dynamic>?)
              ?.map(
                (e) => DoctorRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptomDescription': symptomDescription,
      'diseases': diseases.map((e) => e.toJson()).toList(),
      'departments': departments.map((e) => e.toJson()).toList(),
      'doctors': doctors.map((e) => e.toJson()).toList(),
    };
  }
}

/// 疾病推荐
class DiseaseRecommendation {
  final String diseaseName;
  final double probability;
  final String description;
  final List<String> symptoms;
  final List<TreatmentRecommendation> treatments;

  const DiseaseRecommendation({
    required this.diseaseName,
    required this.probability,
    required this.description,
    required this.symptoms,
    required this.treatments,
  });

  factory DiseaseRecommendation.fromJson(Map<String, dynamic> json) {
    return DiseaseRecommendation(
      diseaseName: json['diseaseName'] as String? ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
      treatments:
          (json['treatments'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TreatmentRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diseaseName': diseaseName,
      'probability': probability,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments.map((e) => e.toJson()).toList(),
    };
  }
}

/// 治疗推荐
class TreatmentRecommendation {
  final String method;
  final double successRate;
  final List<String> medications;
  final String duration;
  final String notes;

  const TreatmentRecommendation({
    required this.method,
    required this.successRate,
    required this.medications,
    required this.duration,
    required this.notes,
  });

  factory TreatmentRecommendation.fromJson(Map<String, dynamic> json) {
    return TreatmentRecommendation(
      method: json['method'] as String? ?? '',
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      medications:
          (json['medications'] as List<dynamic>?)?.cast<String>() ?? [],
      duration: json['duration'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'successRate': successRate,
      'medications': medications,
      'duration': duration,
      'notes': notes,
    };
  }
}

/// 科室推荐
class DepartmentRecommendation {
  final String departmentName;
  final String description;
  final double confidence;

  const DepartmentRecommendation({
    required this.departmentName,
    required this.description,
    required this.confidence,
  });

  factory DepartmentRecommendation.fromJson(Map<String, dynamic> json) {
    return DepartmentRecommendation(
      departmentName: json['departmentName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentName': departmentName,
      'description': description,
      'confidence': confidence,
    };
  }
}

/// 医生推荐
class DoctorRecommendation {
  final String doctorId;
  final String doctorName;
  final String department;
  final String title;
  final String hospital;
  final double rating;
  final int consultationCount;
  final String specialty;

  const DoctorRecommendation({
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.title,
    required this.hospital,
    required this.rating,
    required this.consultationCount,
    required this.specialty,
  });

  factory DoctorRecommendation.fromJson(Map<String, dynamic> json) {
    return DoctorRecommendation(
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      department: json['department'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hospital: json['hospital'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      consultationCount: json['consultationCount'] as int? ?? 0,
      specialty: json['specialty'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'department': department,
      'title': title,
      'hospital': hospital,
      'rating': rating,
      'consultationCount': consultationCount,
      'specialty': specialty,
    };
  }
}
