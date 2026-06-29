import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import 'ActivityFeedItem.dart';

class ActivityFeedTab extends StatefulWidget {
  final int roomId;
  final Future<void> Function() onRefresh;

  const ActivityFeedTab({
    super.key,
    required this.roomId,
    required this.onRefresh,
  });

  @override
  State<ActivityFeedTab> createState() => _ActivityFeedTabState();
}

class _ActivityFeedTabState extends State<ActivityFeedTab>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      if (provider.feedHasNext && !provider.isFeedLoadingMore) {
        provider.loadMoreFeed(widget.roomId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: themeProvider.primaryColor,
      child: provider.feedItems.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                themeProvider.primaryColor.withOpacity(0.1),
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
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount:
                  provider.feedItems.length + (provider.feedHasNext ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == provider.feedItems.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: themeProvider.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return ActivityFeedItem(
                  feed: provider.feedItems[i],
                  roomId: widget.roomId,
                );
              },
            ),
    );
  }
}
