class JobModel {
  final int id;
  final int companyId;
  final String title;
  final String? description;
  final String? location;
  final String? salary;
  final String? jobType;
  final DateTime? lastDate;
  final String? companyName;

  JobModel({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.location,
    this.salary,
    this.jobType,
    this.lastDate,
    this.companyName,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      location: json['location'],
      salary: json['salary'],
      jobType: json['job_type'],
      lastDate: json['last_date'] != null ? DateTime.parse(json['last_date']) : null,
      companyName: json['company_name'],
    );
  }
}
