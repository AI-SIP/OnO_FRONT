import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Model/StudyRoom/StudyRoomModel.dart';
import 'StudyRoomCreateScreen.dart';
import 'StudyRoomDetailScreen.dart';
import 'StudyRoomJoinScreen.dart';
import 'Widget/StudyRoomEmptyState.dart';
import 'Widget/StudyRoomThumbnail.dart';

class StudyRoomListScreen extends StatefulWidget {
  const StudyRoomListScreen({super.key});

  @override
  State<StudyRoomListScreen> createState() => _StudyRoomListScreenState();
}

class _StudyRoomListScreenState extends State<StudyRoomListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      provider.updateCurrentUserId(
        Provider.of<UserProvider>(context, listen: false).userInfoModel?.userId,
      );
      provider.fetchMyRooms();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<StudyRoomProvider>(context, listen: false).fetchMyRooms();
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudyRoomCreateScreen()),
    );
  }

  void _openJoin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudyRoomJoinScreen()),
    );
  }

  void _openDetail(int roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyRoomDetailScreen(roomId: roomId),
      ),
    );
  }

  void _showAddMenu(ThemeHandler themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.group,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '스터디룸 참여하기',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSheetItem(
                  icon: Icons.add,
                  iconColor: themeProvider.primaryColor,
                  label: '새 방 만들기',
                  onTap: () {
                    Navigator.pop(context);
                    _openCreate();
                  },
                ),
                const SizedBox(height: 10),
                _buildSheetItem(
                  icon: Icons.login,
                  iconColor: themeProvider.primaryColor,
                  label: '초대 코드로 참여하기',
                  onTap: () {
                    Navigator.pop(context);
                    _openJoin();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            StandardText(text: label, fontSize: 15, color: Colors.black87),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudyRoomProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '스터디룸',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.add, color: themeProvider.primaryColor),
              onPressed: () => _showAddMenu(themeProvider),
              tooltip: '방 추가',
            ),
          ),
        ],
      ),
      body: provider.isLoading && provider.rooms.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.primaryColor,
              ),
            )
          : provider.rooms.isEmpty
              ? StudyRoomEmptyState(
                  themeProvider: themeProvider,
                  onCreateTap: _openCreate,
                  onJoinTap: _openJoin,
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: themeProvider.primaryColor,
                  child: _buildRoomList(provider, themeProvider),
                ),
    );
  }

  Widget _buildRoomList(
      StudyRoomProvider provider, ThemeHandler themeProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: screenHeight * 0.01,
        bottom: screenHeight * 0.02,
      ),
      itemCount: provider.rooms.length,
      itemBuilder: (_, i) => _buildRoomCard(provider.rooms[i], provider,
          themeProvider, screenHeight, screenWidth),
    );
  }

  Widget _buildRoomCard(
    StudyRoomModel room,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
    double screenHeight,
    double screenWidth,
  ) {
    final isHost = provider.isHost(room);
    final weeklyTotal =
        room.members.fold<int>(0, (sum, m) => sum + m.weeklyProblemCount);
    final reviewedMemberCount = room.displayTodayPracticeMemberCount;
    final totalPractice = room.displayTodayPracticeCount;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.006,
      ),
      child: InkWell(
        onTap: () => _openDetail(room.roomId),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(screenHeight * 0.018),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  StudyRoomThumbnail(
                    imagePath: room.thumbnailImagePath,
                    themeProvider: themeProvider,
                    size: 54,
                    roomName: room.name,
                  ),
                  SizedBox(width: screenHeight * 0.015),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: StandardText(
                                text: room.name,
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isHost) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.workspace_premium_outlined,
                                size: 15,
                                color: themeProvider.primaryColor,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        StandardText(
                          text: '멤버 ${room.memberCount}명 · 이번 주 $weeklyTotal문제',
                          fontSize: 12,
                          color: Colors.grey[600]!,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'PretendardLight',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.chevron_right,
                          size: 20, color: Colors.grey[400]),
                      if (room.hasUnreadReport)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (reviewedMemberCount > 0 || totalPractice > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: Colors.deepOrange[300],
                    ),
                    const SizedBox(width: 5),
                    ...room.members.take(5).map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: _buildInitialAvatar(
                              m.name,
                              themeProvider,
                              isActive: m.hasPracticedToday,
                            ),
                          ),
                        ),
                    if (room.members.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+${room.members.length - 5}',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                                fontFamily: 'PretendardBold',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    if (room.members.isEmpty && reviewedMemberCount > 0) ...[
                      StandardText(
                        text: '$reviewedMemberCount명 · ',
                        fontSize: 12,
                        color: Colors.grey[600]!,
                      ),
                    ],
                    StandardText(
                      text: '오늘 복습 $totalPractice회',
                      fontSize: 12,
                      color: themeProvider.primaryColor,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(
    String name,
    ThemeHandler themeProvider, {
    bool isActive = false,
  }) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isActive
            ? themeProvider.primaryColor.withValues(alpha: 0.08)
            : Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? themeProvider.primaryColor : Colors.grey[300]!,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
            fontSize: 9,
            color: isActive ? themeProvider.primaryColor : Colors.grey[400],
            fontFamily: 'PretendardBold',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
