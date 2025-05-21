class PracticeNotificationModel {
  final int? intervalDays;
  final int? hour;
  final int? minute;
  final int? notifyCount;

  PracticeNotificationModel({
    this.intervalDays,
    this.hour,
    this.minute,
    this.notifyCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'intervalDays': intervalDays,
      'hour': hour,
      'minute': minute,
      'notifyCount': notifyCount,
    };
  }

  factory PracticeNotificationModel.fromJson(Map<String, dynamic> json) {
    return PracticeNotificationModel(
      intervalDays: json['intervalDays'] ?? 7,
      hour: json['hour'] ?? 18,
      minute: json['minute'] ?? 0,
      notifyCount: json['notifyCount'] ?? 3,
    );
  }
}
