import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/StudyRoom/StudyRoomModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/User/ProfileAvatar.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Util/AppErrorReporter.dart';
import '../Tutorial/TutorialTargets.dart';
import 'StudyRoomCreateScreen.dart';
import 'StudyRoomDetailScreen.dart';
import 'StudyRoomJoinScreen.dart';
import 'Widget/StudyRoomEmptyState.dart';
import 'Widget/StudyRoomThumbnail.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppToast.dart';

class StudyRoomListScreen extends StatefulWidget {
  final TutorialTargets? tutorialTargets;

  const StudyRoomListScreen({super.key, this.tutorialTargets});

  @override
  State<StudyRoomListScreen> createState() => _StudyRoomListScreenState();
}

class _StudyRoomListScreenState extends State<StudyRoomListScreen> {
  @override
  void initState() {
    super.initState();
    // 이 화면은 홈의 IndexedStack 안에 있어서 initState 가 탭을 누를 때가
    // 아니라 홈이 뜰 때 한 번 돈다. 여기서 남기던 study_room_list_view 는 앱을
    // 켠 횟수와 같아서 뺐다. 탭 진입은 ScreenIndexProvider 가 남긴다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      provider.updateCurrentUserId(
        Provider.of<UserProvider>(context, listen: false).userInfoModel?.userId,
      );
      _loadRooms(provider);
    });
  }

  Future<void> _refresh() async {
    await _loadRooms(Provider.of<StudyRoomProvider>(context, listen: false));
  }

  /// 목록을 불러온다. 실패해도 던지지 않는다.
  ///
  /// 실패는 HttpService 가 이미 스낵바로 알린다. 여기서 받지 않으면 예외가
  /// 끝까지 올라가 앱이 죽은 것처럼 fatal 로 보고됐다.
  Future<void> _loadRooms(StudyRoomProvider provider) async {
    try {
      await provider.fetchMyRooms();
    } catch (error, stackTrace) {
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'study_room_fetch',
        severity: AppErrorSeverity.warning,
      );
    }
  }

  /// 방을 만들면 그 방을 열고 초대 코드까지 보여 준다. 전에는 목록으로만
  /// 돌아와서 초대 코드를 찾으려고 방에 다시 들어가야 했다.
  Future<void> _openCreate() async {
    final roomId = await Navigator.push<int>(
      context,
      TossPageRoute(builder: (_) => const StudyRoomCreateScreen()),
    );
    if (roomId == null || !mounted) return;
    AppToast.success('방을 만들었어요. 초대 코드로 친구를 불러 보세요');
    _openDetail(roomId, showInviteCode: true);
  }

  /// 참여하면 그 방을 바로 연다. 전에는 아무 말 없이 목록으로 돌아와서
  /// 참여가 됐는지 알 수 없었다.
  Future<void> _openJoin() async {
    final roomId = await Navigator.push<int>(
      context,
      TossPageRoute(builder: (_) => const StudyRoomJoinScreen()),
    );
    if (roomId == null || !mounted) return;
    AppToast.success('방에 참여했어요');
    _openDetail(roomId);
  }

  void _openDetail(int roomId, {bool showInviteCode = false}) {
    Navigator.push(
      context,
      TossPageRoute(
        builder: (_) => StudyRoomDetailScreen(
          roomId: roomId,
          showInviteCodeOnOpen: showInviteCode,
        ),
      ),
    );
  }

  void _showAddMenu(ThemeHandler themeProvider) {
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
      context: context,
      useRootNavigator: true,
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
                        borderRadius: BorderRadius.circular(AppRadius.small),
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
                      color: AppColors.textPrimary,
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
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
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
            StandardText(
                text: label, fontSize: 15, color: AppColors.textPrimary),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        height: 50,
        child: FloatingActionButton.extended(
          heroTag: 'study_room_join_fab',
          onPressed: () => _showAddMenu(themeProvider),
          backgroundColor: themeProvider.primaryColor,
          elevation: 2,
          tooltip: '방 만들기 또는 참여하기',
          icon: const Icon(Icons.add, color: Colors.white),
          // 누르면 만들기와 참여하기가 함께 나와서 '참여' 만 적으면 맞지 않았다.
          label: const StandardText(
            text: '방 추가',
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // 다른 탭처럼 화면 폭을 다 쓴다. 전에는 폭을 줄여 가운데에 두고 카드
      // 여백을 또 둬서, 태블릿에서 이 화면만 양옆이 더 들어가 보였다.
      body: SizedBox.expand(
        key: widget.tutorialTargets?.studyRoomListKey,
        child: provider.isLoading && provider.rooms.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                color: themeProvider.primaryColor,
                child: provider.rooms.isEmpty
                    // 참여 중인 방이 없어도 당겨서 새로고침할 수 있어야 한다.
                    // 빈 상태는 스크롤되지 않아서 그냥 두면 당길 것이 없다.
                    // 화면 높이만큼 스크롤 영역을 만들어 준다.
                    ? LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: StudyRoomEmptyState(
                              themeProvider: themeProvider,
                              onCreateTap: _openCreate,
                              onJoinTap: _openJoin,
                            ),
                          ),
                        ),
                      )
                    : _buildRoomList(provider, themeProvider),
              ),
      ),
    );
  }

  Widget _buildRoomList(
      StudyRoomProvider provider, ThemeHandler themeProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final rooms = provider.rooms;
    // 넓은 화면에서는 책장, 복습 세트처럼 두 열로 놓는다.
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 2 : 1;
      final rowCount = (rooms.length / columns).ceil();
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // 책장과 같은 간격이다. 바깥 20, 두 열 사이 16, 카드 위아래 8.
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: screenHeight * 0.01,
          bottom: screenHeight * 0.12,
        ),
        itemCount: rowCount,
        itemBuilder: (_, index) {
          final first = index * columns;
          if (columns == 1) {
            return _buildRoomCard(rooms[first], provider, themeProvider,
                screenHeight, screenWidth);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = first; i < first + columns; i++) ...[
                if (i > first) const SizedBox(width: 16),
                Expanded(
                  child: i < rooms.length
                      ? _buildRoomCard(rooms[i], provider, themeProvider,
                          screenHeight, screenWidth)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          );
        },
      );
    });
  }

  Widget _buildRoomCard(
    StudyRoomModel room,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
    double screenHeight,
    double screenWidth,
  ) {
    final isHost = provider.isHost(room);
    final titleFontSize = screenWidth < 600 ? 15.0 : 16.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: PressableScale(
        onTap: () => _openDetail(room.roomId),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 70,
                child: Center(
                  child: StudyRoomThumbnail(
                    imagePath: room.thumbnailImagePath,
                    themeProvider: themeProvider,
                    size: 50,
                    roomName: room.name,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: StandardText(
                            text: room.name,
                            fontSize: titleFontSize,
                            color: AppColors.textPrimary,
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
                      text: '멤버 ${room.memberCount}명',
                      fontSize: 12,
                      color: Colors.grey[600]!,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'PretendardLight',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildMemberAvatars(room, themeProvider, screenWidth),
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
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(
    StudyRoomModel room,
    ThemeHandler themeProvider,
    double screenWidth,
  ) {
    final avatarSize = screenWidth < 600 ? 20.0 : 28.0;
    return SizedBox(
      height: avatarSize,
      child: Row(
        children: [
          ...room.members.take(5).map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _buildInitialAvatar(
                    m.profileImageUrl,
                    themeProvider,
                    size: avatarSize,
                    isActive: m.hasPracticedToday,
                  ),
                ),
              ),
          if (room.members.length > 5)
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+${room.members.length - 5}',
                  style: TextStyle(
                    fontSize: avatarSize * 0.4,
                    color: Colors.grey[600],
                    fontFamily: 'PretendardBold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(
    String? profileImageUrl,
    ThemeHandler themeProvider, {
    required double size,
    bool isActive = false,
  }) {
    return ProfileAvatar(
      imageUrl: profileImageUrl,
      size: size,
      borderColor: isActive ? themeProvider.primaryColor : Colors.grey[300]!,
      borderWidth: isActive ? 1.5 : 1,
      backgroundColor: isActive
          ? themeProvider.primaryColor.withValues(alpha: 0.08)
          : Colors.grey[100]!,
    );
  }
}
