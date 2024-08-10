import '../../Model/ProblemModel.dart';

extension ProblemSorting on List<ProblemModel> {
  void sortByName() {
    sort((a, b) => (a.reference ?? '').compareTo(b.reference ?? ''));
  }

  void sortByNewest() {
    sort((a, b) => b.solvedAt!.compareTo(a.solvedAt!));
  }

  void sortByOldest() {
    sort((a, b) => a.solvedAt!.compareTo(b.solvedAt!));
  }
}