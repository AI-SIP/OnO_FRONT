import 'package:flutter/material.dart';

import '../../Util/AppAnalytics.dart';
import '../Design/AppRadius.dart';
import '../Text/StandardText.dart';
import 'FullScreenImage.dart';

/// 비교해 볼 이미지 한 묶음. 내 풀이, 문제, 정답처럼 이름을 붙인다.
class ImageCompareGroup {
  final String label;
  final List<String> imagePaths;

  const ImageCompareGroup({required this.label, required this.imagePaths});
}

/// 내 풀이와 문제, 정답을 오가며 본다.
///
/// 전에는 문제는 문제끼리, 풀이는 풀이끼리만 넘겨 볼 수 있어서, 내 풀이가
/// 정답과 어디서 갈렸는지 보려면 화면을 몇 번씩 나갔다 들어와야 했다. 위쪽
/// 칩으로 묶음을 바꾸고, 넓은 화면에서는 두 묶음을 나란히 둔다.
class ImageCompareScreen extends StatefulWidget {
  final List<ImageCompareGroup> groups;

  const ImageCompareScreen({super.key, required this.groups});

  /// 넓은 화면에서 둘로 나누는 폭.
  static const double splitWidth = 900;

  @override
  State<ImageCompareScreen> createState() => _ImageCompareScreenState();
}

class _ImageCompareScreenState extends State<ImageCompareScreen> {
  late final List<ImageCompareGroup> _groups =
      widget.groups.where((g) => g.imagePaths.isNotEmpty).toList();
  int _left = 0;
  late int _right = _groups.length > 1 ? _groups.length - 1 : 0;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('ImageCompareScreen');
  }

  @override
  Widget build(BuildContext context) {
    final split =
        MediaQuery.sizeOf(context).width >= ImageCompareScreen.splitWidth &&
            _groups.length > 1;

    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      body: SafeArea(
        bottom: false,
        child: split
            ? Row(
                children: [
                  Expanded(
                    child: _buildPane(
                      _left,
                      (i) => setState(() => _left = i),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.white24),
                  Expanded(
                    child: _buildPane(
                      _right,
                      (i) => setState(() => _right = i),
                    ),
                  ),
                ],
              )
            : _buildPane(_left, (i) => setState(() => _left = i)),
      ),
    );
  }

  Widget _buildPane(int selected, ValueChanged<int> onSelect) {
    final group = _groups[selected];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _groups.length; i++) ...[
                  _GroupChip(
                    label:
                        '${_groups[i].label} ${_groups[i].imagePaths.length}',
                    selected: i == selected,
                    onTap: () {
                      if (i == selected) return;
                      AppAnalytics.logEvent('image_compare_switch', {
                        'to': _groups[i].label,
                      });
                      onSelect(i);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          // 안쪽 뷰어가 위 여백을 한 번 더 잡지 않게 뺀다.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: FullScreenImage(
              key: ValueKey(group.label),
              imagePaths: group.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white12,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: StandardText(
            text: label,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
