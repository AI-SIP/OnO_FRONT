import 'PracticeNotificationModel.dart';

class PracticeNoteUpdateModel {
  final int practiceNoteId;
  String? practiceTitle;
  final List<int> addProblemIdList;
  final List<int> removeProblemIdList;
  PracticeNotificationModel? practiceNotificationModel;

  PracticeNoteUpdateModel({
    required this.practiceNoteId,
    this.practiceTitle,
    required this.addProblemIdList,
    required this.removeProblemIdList,
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
      'practiceNoteId': practiceNoteId,
      'practiceTitle': practiceTitle,
      'addProblemIdList': addProblemIdList,
      'removeProblemIdList': removeProblemIdList,
      if (practiceNotificationModel != null)
        'practiceNotification': practiceNotificationModel!.toJson(),
    };
  }
}
