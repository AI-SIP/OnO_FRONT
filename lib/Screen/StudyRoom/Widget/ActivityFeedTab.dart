import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import 'ActivityFeedItem.dart';

class ActivityFeedTab extends StatelessWidget {
  final int roomId;

  const ActivityFeedTab({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context);

    if (provider.feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dynamic_feed_outlined,
                color: themeProvider.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const StandardText(
              text: '아직 활동이 없어요',
              fontSize: 16,
              color: Colors.black87,
            ),
            const SizedBox(height: 6),
            StandardText(
              text: '멤버들이 문제를 등록하면 여기에 표시돼요',
              fontSize: 13,
              color: Colors.grey[500]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: provider.feedItems.length,
      itemBuilder: (_, i) => ActivityFeedItem(
        feed: provider.feedItems[i],
        roomId: roomId,
      ),
    );
  }
}
