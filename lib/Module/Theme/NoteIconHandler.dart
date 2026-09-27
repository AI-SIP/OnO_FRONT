class NoteIconHandler {
  /// 공책 색깔 돌림판. 폴더 카드가 여기서 그림을 받아 간다.
  ///
  /// 점토 재질로 다시 그리면서 **여덟 색에서 일곱 색이 되었다.** 회색 공책은
  /// 새로 그린 것이 없어서 뺐다. 한 자리만 예전 플랫 SVG 로 남겨 두면 여덟 번째
  /// 폴더마다 혼자 다른 세계 물건으로 보인다. 색은 폴더 순서로만 정해지고
  /// 저장하지 않으니, 기존 폴더의 색이 한 칸씩 밀리는 것 말고는 영향이 없다.
  static const List<String> noteIcons = [
    'assets/Icon/PinkNote.png',
    'assets/Icon/YellowNote.png',
    'assets/Icon/GreenNote.png',
    'assets/Icon/BlueNote.png',
    'assets/Icon/PurpleNote.png',
    'assets/Icon/BrownNote.png',
    'assets/Icon/WhiteNote.png',
  ];

  // 인덱스에 따라 알맞은 아이콘을 반환
  static String getNoteIcon(int index) {
    return noteIcons[index % noteIcons.length];
  }
}
