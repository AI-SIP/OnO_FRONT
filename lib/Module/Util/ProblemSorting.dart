import '../../Model/Problem/ProblemModelWithTemplate.dart';

extension ProblemSorting on List<ProblemModelWithTemplate> {
  void sortByName() {
    sort((a, b) => (a.reference ?? '').compareTo(b.reference ?? ''));
  }

  void sortByNewest() {
    sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  }

  void sortByOldest() {
    sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
  }
}
