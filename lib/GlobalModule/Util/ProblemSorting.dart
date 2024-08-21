import '../../Model/ProblemModel.dart';

extension ProblemSorting on List<ProblemModel> {
  void sortByName() {
    sort((a, b) => (a.reference ?? '').compareTo(b.reference ?? ''));
  }

  void sortByNewest() {
    sort((a, b) => b.updateAt!.compareTo(a.updateAt!));
  }

  void sortByOldest() {
    sort((a, b) => a.updateAt!.compareTo(b.updateAt!));
  }
}