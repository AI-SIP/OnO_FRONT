import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/StudyRoom/ChallengeModel.dart';
import '../../Model/StudyRoom/StudyRoomModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/User/ProfileAvatar.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Util/AppSnackBar.dart';
import 'ChallengeCreateSheet.dart';
import 'StudyRoomEditScreen.dart';
import 'Widget/ActivityFeedTab.dart';
import 'Widget/ChallengeCard.dart';
import 'Widget/InviteCodeSheet.dart';
import 'Widget/MemberRankCard.dart';
import 'Widget/StudyRoomThumbnail.dart';
import 'Widget/SharedProblemTab.dart';
import 'Widget/WeeklyReportSheet.dart';

class StudyRoomDetailScreen extends StatefulWidget {
  final int roomId;

  const StudyRoomDetailScreen({super.key, required this.roomId});

  @override
  State<StudyRoomDetailScreen> createState() => _StudyRoomDetailScreenState();
}

class _StudyRoomDetailScreenState extends State<StudyRoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSharedTabChrome = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    FirebaseAnalytics.instance.logEvent(name: 'study_room_detail_view');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoom();
    });
  }

  Future<void> _loadRoom() async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).userInfoModel?.userId;
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    provider.updateCurrentUserId(userId);
    try {
      await provider.fetchRoomDetail(widget.roomId);
      if (mounted) _showUnreadReport();
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.index != 2 && !_showSharedTabChrome) {
      setState(() => _showSharedTabChrome = true);
    }
  }

  void _setSharedTabChromeVisible(bool visible) {
    if (_showSharedTabChrome == visible) return;
    setState(() => _showSharedTabChrome = visible);
  }

  void _showUnreadReport() {
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final report = provider.weeklyReport;
    if (report == null || report.isRead) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
      WeeklyReportSheet.show(context, report, themeProvider, onClose: () {
        provider.markReportRead();
      });
    });
  }

  Future<void> _refresh() async {
    try {
      await Provider.of<StudyRoomProvider>(context, listen: false)
          .fetchRoomDetail(widget.roomId);
    } catch (_) {}
  }

  Future<void> _showInviteCode(
    BuildContext context,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
  ) async {
    try {
      final code = await provider.generateInviteCode(widget.roomId);
      if (!context.mounted) return;
      InviteCodeSheet.show(
        context,
        inviteCode: code,
        themeProvider: themeProvider,
      );
    } catch (_) {
      AppSnackBar.showError('초대 코드를 불러올 수 없습니다');
    }
  }

  Future<void> _openEditScreen(
    BuildContext context,
    StudyRoomProvider provider,
    StudyRoomModel room,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudyRoomEditScreen(room: room),
      ),
    );
    if (updated == true && context.mounted) {
      await provider.fetchRoomDetail(room.roomId);
    }
  }

  Future<void> _confirmLeave(
    BuildContext context,
    StudyRoomProvider provider, {
    bool isHost = false,
  }) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final room = provider.selectedRoom;
    final hasOtherMembers = room != null && room.members.length > 1;
    final content = isHost
        ? hasOtherMembers
            ? '탈퇴하면 다른 멤버에게 방장이 자동으로 넘어갑니다.\n정말 탈퇴하시겠어요?'
            : '마지막 멤버이므로 탈퇴 시 방이 삭제됩니다.\n정말 탈퇴하시겠어요?'
        : '정말 탈퇴하시겠어요?';
    final confirmed = await _showConfirmDialog(
      context: context,
      themeProvider: themeProvider,
      icon: Icons.exit_to_app,
      iconColor: Colors.orange,
      title: '스터디룸 탈퇴',
      content: content,
      confirmLabel: '탈퇴',
      confirmColor: Colors.red,
    );
    if (confirmed == true && context.mounted) {
      await provider.leaveRoom(widget.roomId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StudyRoomProvider provider,
  ) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final confirmed = await _showConfirmDialog(
      context: context,
      themeProvider: themeProvider,
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      title: '방 삭제',
      content: '방을 삭제하면 모든 멤버가 퇴장됩니다.\n정말 삭제하시겠어요?',
      confirmLabel: '삭제',
      confirmColor: Colors.red,
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteRoom(widget.roomId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required ThemeHandler themeProvider,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: title,
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StandardText(
                  text: content,
                  fontSize: 14,
                  color: Colors.grey[700]!,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: confirmColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: StandardText(
                          text: confirmLabel,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudyRoomProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final room = provider.selectedRoom;
    final isHost = room != null && provider.isHost(room);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: room?.name ?? '스터디룸',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          if (room != null)
            IconButton(
              icon:
                  Icon(Icons.share_outlined, color: themeProvider.primaryColor),
              onPressed: () =>
                  _showInviteCode(context, provider, themeProvider),
              tooltip: '초대 코드',
            ),
          IconButton(
            icon: Icon(Icons.more_vert, color: themeProvider.primaryColor),
            onPressed: () =>
                _showMoreMenu(context, provider, isHost, themeProvider, room),
          ),
        ],
        bottom: _showSharedTabChrome
            ? TabBar(
                controller: _tabController,
                indicatorColor: themeProvider.primaryColor,
                labelColor: themeProvider.primaryColor,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: StandardText(
                  text: '',
                  fontSize: 13.5,
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w700,
                ).getTextStyle(),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontFamily: 'PretendardBold',
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: '랭킹'),
                  Tab(text: '챌린지'),
                  Tab(text: '공유'),
                  Tab(text: '활동'),
                ],
              )
            : const PreferredSize(
                preferredSize: Size.fromHeight(0),
                child: SizedBox.shrink(),
              ),
      ),
      body: provider.isLoading && (room == null || room.roomId != widget.roomId)
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.primaryColor,
              ),
            )
          : room == null
              ? Center(
                  child: StandardText(
                    text: '방을 찾을 수 없습니다',
                    fontSize: 15,
                    color: Colors.grey[500]!,
                  ),
                )
              : _buildTabBody(context, room, provider, themeProvider, isHost),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    StudyRoomModel room,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
    bool isHost,
  ) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRankingTab(context, room, provider, themeProvider, isHost),
        _buildChallengeTab(context, provider, themeProvider, isHost),
        SharedProblemTab(
          roomId: widget.roomId,
          onRefresh: _refresh,
          onChromeVisibilityChanged: _setSharedTabChromeVisible,
        ),
        ActivityFeedTab(roomId: widget.roomId, onRefresh: _refresh),
      ],
    );
  }

  // ── 랭킹 탭 ──

  Widget _buildRankingTab(
    BuildContext context,
    StudyRoomModel room,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
    bool isHost,
  ) {
    final sorted = [...room.members]
      ..sort((a, b) => b.weeklyProblemCount.compareTo(a.weeklyProblemCount));

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTabletLandscape =
        mediaQuery.size.shortestSide >= 600 && screenWidth > screenHeight;

    return Column(
      children: [
        _buildRankingHeader(
            themeProvider, room, screenWidth, screenHeight, provider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: themeProvider.primaryColor,
            child: isTabletLandscape
                ? _buildGrid(sorted, room, provider, isHost)
                : _buildList(sorted, room, provider, isHost),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingHeader(
    ThemeHandler themeProvider,
    StudyRoomModel room,
    double screenWidth,
    double screenHeight,
    StudyRoomProvider provider,
  ) {
    final isCompact = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.fromLTRB(
        screenHeight * 0.018,
        screenHeight * 0.018,
        screenHeight * 0.018,
        screenHeight * 0.016,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudyRoomThumbnail(
                imagePath: room.thumbnailImagePath,
                themeProvider: themeProvider,
                size: isCompact ? 48 : 54,
                roomName: room.name,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoomSummary(room, themeProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSummary(
    StudyRoomModel room,
    ThemeHandler themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: StandardText(
                text: room.name,
                fontSize: 17,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.workspace_premium_outlined,
              size: 14,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 3),
        StandardText(
          text: '멤버 ${room.memberCount}명',
          fontSize: 12,
          color: Colors.grey[600]!,
          fontWeight: FontWeight.normal,
          fontFamily: 'PretendardLight',
        ),
      ],
    );
  }

  Widget _buildList(
    List sorted,
    StudyRoomModel room,
    StudyRoomProvider provider,
    bool isHost,
  ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final member = sorted[i];
        return MemberRankCard(
          rank: i + 1,
          member: member,
          isMe: member.userId == provider.currentUserId,
          isHost: member.userId == room.hostUserId,
          canKick: false,
          onKick: null,
        );
      },
    );
  }

  Widget _buildGrid(
    List sorted,
    StudyRoomModel room,
    StudyRoomProvider provider,
    bool isHost,
  ) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 100,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final member = sorted[i];
        return MemberRankCard(
          rank: i + 1,
          member: member,
          isMe: member.userId == provider.currentUserId,
          isHost: member.userId == room.hostUserId,
          canKick: false,
          onKick: null,
        );
      },
    );
  }

  // ── 챌린지 탭 ──

  Widget _buildChallengeTab(
    BuildContext context,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
    bool isHost,
  ) {
    final inProgress = provider.challenges
        .where((challenge) => challenge.isInProgress)
        .toList();
    final ended = provider.challenges
        .where((challenge) => !challenge.isInProgress)
        .toList();
    final mediaQuery = MediaQuery.of(context);
    final isTabletLandscape = mediaQuery.size.shortestSide >= 600 &&
        mediaQuery.size.width > mediaQuery.size.height;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: _refresh,
                color: themeProvider.primaryColor,
                child: provider.challenges.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: themeProvider.primaryColor
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.flag_outlined,
                                      color: themeProvider.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const StandardText(
                                    text: '아직 챌린지가 없어요',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(height: 6),
                                  StandardText(
                                    text: '새 챌린지를 만들어 멤버들과 함께 도전해보세요',
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
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        children: [
                          if (inProgress.isNotEmpty) ...[
                            _buildChallengeSectionHeader(
                              '진행 중',
                              themeProvider,
                              count: inProgress.length,
                              isHighlighted: true,
                            ),
                            _buildChallengeCards(
                              inProgress,
                              isHost,
                              isTabletLandscape,
                              constraints.maxWidth,
                            ),
                          ],
                          if (ended.isNotEmpty) ...[
                            _buildChallengeSectionHeader(
                              '종료된 챌린지',
                              themeProvider,
                            ),
                            _buildChallengeCards(
                              ended,
                              isHost,
                              isTabletLandscape,
                              constraints.maxWidth,
                            ),
                          ],
                        ],
                      ),
              );
            },
          ),
        ),
        _buildChallengeCreateButton(context, themeProvider),
      ],
    );
  }

  Widget _buildChallengeCards(
    List<ChallengeModel> challenges,
    bool isHost,
    bool isTabletLandscape,
    double maxWidth,
  ) {
    if (!isTabletLandscape) {
      return Column(
        children: challenges
            .map(
              (challenge) => ChallengeCard(
                challenge: challenge,
                canDelete: isHost,
              ),
            )
            .toList(),
      );
    }

    const horizontalPadding = 16.0;
    const spacing = 12.0;
    final cardWidth = (maxWidth - horizontalPadding * 2 - spacing) / 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        8,
      ),
      child: Wrap(
        spacing: spacing,
        runSpacing: 12,
        children: challenges
            .map(
              (challenge) => SizedBox(
                width: cardWidth,
                child: ChallengeCard(
                  challenge: challenge,
                  canDelete: isHost,
                  margin: EdgeInsets.zero,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildChallengeSectionHeader(
    String title,
    ThemeHandler themeProvider, {
    int? count,
    bool isHighlighted = false,
  }) {
    final color =
        isHighlighted ? themeProvider.primaryColor : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          StandardText(
            text: title,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w700,
          ),
          if (count != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: StandardText(
                text: '$count개',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeCreateButton(
    BuildContext context,
    ThemeHandler themeProvider,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton(
            onPressed: () => ChallengeCreateSheet.show(context),
            style: TextButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: Colors.white),
                SizedBox(width: 6),
                StandardText(
                  text: '새 챌린지 만들기',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 더보기 메뉴 ──

  void _showMoreMenu(
    BuildContext context,
    StudyRoomProvider provider,
    bool isHost,
    ThemeHandler themeProvider,
    StudyRoomModel? room,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '더보기 닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      useRootNavigator: true,
      pageBuilder: (sheetContext, _, __) => _StudyRoomBottomSheetFrame(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
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
                  if (provider.weeklyReport != null)
                    _buildSheetItem(
                      icon: Icons.summarize_outlined,
                      iconColor: themeProvider.primaryColor,
                      label: '주간 리포트 보기',
                      labelColor: Colors.black87,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        WeeklyReportSheet.show(
                          context,
                          provider.weeklyReport!,
                          themeProvider,
                          onClose: () {
                            provider.markReportRead();
                          },
                        );
                      },
                    ),
                  if (provider.weeklyReport != null) const SizedBox(height: 8),
                  if (room != null && isHost)
                    _buildSheetItem(
                      icon: Icons.edit_outlined,
                      iconColor: themeProvider.primaryColor,
                      label: '스터디룸 정보 수정',
                      labelColor: Colors.black87,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openEditScreen(context, provider, room);
                      },
                    ),
                  if (room != null && isHost) const SizedBox(height: 8),
                  if (room != null && isHost)
                    _buildSheetItem(
                      icon: Icons.manage_accounts_outlined,
                      iconColor: themeProvider.primaryColor,
                      label: '멤버 관리',
                      labelColor: Colors.black87,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showMemberManageSheet(
                          context,
                          provider,
                          room,
                          themeProvider,
                        );
                      },
                    ),
                  if (room != null && isHost) const SizedBox(height: 8),
                  if (isHost) ...[
                    _buildSheetItem(
                      icon: Icons.exit_to_app,
                      iconColor: Colors.orange,
                      label: '스터디룸 탈퇴',
                      labelColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _confirmLeave(context, provider, isHost: true);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSheetItem(
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      label: '방 삭제하기',
                      labelColor: Colors.red,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _confirmDelete(context, provider);
                      },
                    ),
                  ] else
                    _buildSheetItem(
                      icon: Icons.exit_to_app,
                      iconColor: Colors.red,
                      label: '스터디룸 탈퇴',
                      labelColor: Colors.red,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _confirmLeave(context, provider);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  void _showMemberManageSheet(
    BuildContext context,
    StudyRoomProvider provider,
    StudyRoomModel room,
    ThemeHandler themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
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
                        color:
                            themeProvider.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.manage_accounts_outlined,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: StandardText(
                        text: '멤버 관리',
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: room.members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final member = room.members[index];
                      final isMe = member.userId == provider.currentUserId;
                      final isRoomHost = member.userId == room.hostUserId;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              imageUrl: member.profileImageUrl,
                              size: 34,
                              borderColor: isMe
                                  ? themeProvider.primaryColor
                                  : themeProvider.primaryColor
                                      .withValues(alpha: 0.18),
                              borderWidth: isMe ? 1.4 : 1,
                              backgroundColor: themeProvider.primaryColor
                                  .withValues(alpha: 0.08),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: StandardText(
                                          text: member.name,
                                          fontSize: 14,
                                          color: Colors.black87,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 5),
                                        StandardText(
                                          text: '나',
                                          fontSize: 11,
                                          color: themeProvider.primaryColor,
                                        ),
                                      ],
                                      if (isRoomHost) ...[
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.workspace_premium_outlined,
                                          size: 13,
                                          color: themeProvider.primaryColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  StandardText(
                                    text: '이번 주 ${member.weeklyProblemCount}문제',
                                    fontSize: 11,
                                    color: Colors.grey[500]!,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'PretendardLight',
                                  ),
                                ],
                              ),
                            ),
                            if (!isMe && !isRoomHost)
                              TextButton(
                                onPressed: () async {
                                  final confirmed = await _showConfirmDialog(
                                    context: context,
                                    themeProvider: themeProvider,
                                    icon: Icons.person_remove_outlined,
                                    iconColor: Colors.red,
                                    title: '멤버 내보내기',
                                    content: '${member.name} 님을 스터디룸에서 내보낼까요?',
                                    confirmLabel: '내보내기',
                                    confirmColor: Colors.red,
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      await provider.kickMember(
                                        room.roomId,
                                        member.userId,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        AppSnackBar.showError('멤버 내보내기에 실패했어요');
                                      }
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      Colors.red.withValues(alpha: 0.08),
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const StandardText(
                                  text: '내보내기',
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
    required Color labelColor,
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            StandardText(text: label, fontSize: 15, color: labelColor),
          ],
        ),
      ),
    );
  }
}

class _StudyRoomBottomSheetFrame extends StatefulWidget {
  final Widget child;

  const _StudyRoomBottomSheetFrame({required this.child});

  @override
  State<_StudyRoomBottomSheetFrame> createState() =>
      _StudyRoomBottomSheetFrameState();
}

class _StudyRoomBottomSheetFrameState
    extends State<_StudyRoomBottomSheetFrame> {
  bool _canDismissByOutsideTap = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _canDismissByOutsideTap = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sheetWidth = screenWidth < 600 ? screenWidth : 560.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _canDismissByOutsideTap
                  ? () => Navigator.maybePop(context)
                  : null,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: SizedBox(
                width: sheetWidth,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
