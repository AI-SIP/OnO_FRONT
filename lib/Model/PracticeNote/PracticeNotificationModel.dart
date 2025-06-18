import 'package:ono/Model/PracticeNote/RepeatType.dart';

class PracticeNotificationModel {
  final int? intervalDays;
  final int? hour;
  final int? minute;
  final RepeatType? repeatType;
  final List<int>? weekDays;

  PracticeNotificationModel({
    this.intervalDays,
    this.hour,
    this.minute,
    this.repeatType,
    this.weekDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'intervalDays': intervalDays,
      'hour': hour,
      'minute': minute,
      'repeatType': repeatType?.name,
      'weekDays': weekDays,
    };
  }

  factory PracticeNotificationModel.fromJson(Map<String, dynamic> json) {
    return PracticeNotificationModel(
      intervalDays: json['intervalDays'] ?? 7,
      hour: json['hour'] ?? 18,
      minute: json['minute'] ?? 0,
      repeatType: json['repeatType'] is String
          ? RepeatType.values.firstWhere(
              (e) => e.name == json['repeatType'],
              orElse: () => RepeatType.daily,
            )
          : RepeatType.daily,
      weekDays:
          (json['weekDays'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }
}
