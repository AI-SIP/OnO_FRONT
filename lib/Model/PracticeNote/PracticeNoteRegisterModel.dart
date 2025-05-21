import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';

class PracticeNoteRegisterModel {
  final int? practiceId;
  String practiceTitle;
  final List<int> registerProblemIdList;
  PracticeNotificationModel? practiceNotificationModel;

  PracticeNoteRegisterModel({
    this.practiceId,
    required this.practiceTitle,
    required this.registerProblemIdList,
    this.practiceNotificationModel,
  });

  void setPracticeTitle(String newTitle) {
    practiceTitle = newTitle;
  }

  void setPracticeNotificationModel(practiceNotificationModel) {
    this.practiceNotificationModel = practiceNotificationModel;
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'practiceTitle': practiceTitle,
      'problemIdList': registerProblemIdList,
      if (practiceNotificationModel != null)
        'practiceNotification': practiceNotificationModel!.toJson(),
    };
  }
}
