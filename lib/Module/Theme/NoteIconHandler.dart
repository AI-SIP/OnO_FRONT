class NoteIconHandler {
  static const List<String> noteIcons = [
    'assets/Icon/PinkNote.svg',
    'assets/Icon/YellowNote.svg',
    'assets/Icon/GreenNote.svg',
    'assets/Icon/BlueNote.svg',
    'assets/Icon/PurpleNote.svg',
    'assets/Icon/BrownNote.svg',
    'assets/Icon/WhiteNote.svg',
    'assets/Icon/GreyNote.svg',
  ];

  // 인덱스에 따라 알맞은 아이콘을 반환
  static String getNoteIcon(int index) {
    return noteIcons[index % noteIcons.length];
  }
}
