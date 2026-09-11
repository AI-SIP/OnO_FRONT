import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Design/AppToast.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossBottomSheet.dart';
import '../../../Module/Motion/TossDialog.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Module/User/ProfileAvatar.dart';
import '../../../Provider/CosmeticProvider.dart';
import '../../../Provider/UserProvider.dart';
import '../../../Service/Api/FileUpload/FileUploadService.dart';

/// 마이페이지 맨 위의 프로필 카드다.
///
/// 사진과 이름을 여기서 바로 바꾼다. 예전에는 설정 화면 안쪽에 있었는데,
/// 내 사진과 내 이름은 **마이페이지에 있을 때 가장 찾기 쉬운 것**이라 본문으로
/// 꺼냈다. 설정에는 알림처럼 자주 건드리지 않는 것만 남는다.
///
/// 사진을 안 올렸으면 [ProfileAvatar] 가 **지금 꾸민 개구리 얼굴**을 세운다.
/// 앱 어디를 가도 같은 개구리가 따라다녀야 꾸미는 보람이 있다.
class ProfileEditCard extends StatefulWidget {
  final ThemeHandler themeProvider;

  /// 좌우 여백을 화면 폭의 몇 배로 둘지. 태블릿 가로에서 카드를 나란히 놓을
  /// 때 0 으로 두고 바깥에서 여백을 준다.
  final double horizontalMarginFactor;

  const ProfileEditCard({
    super.key,
    required this.themeProvider,
    this.horizontalMarginFactor = 0.04,
  });

  @override
  State<ProfileEditCard> createState() => _ProfileEditCardState();
}

class _ProfileEditCardState extends State<ProfileEditCard> {
  final ImagePicker _imagePicker = ImagePicker();
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingProfileImage = false;

  Future<void> _showProfileImageOptions() async {
    if (_isUploadingProfileImage) return;
    final color = widget.themeProvider.primaryColor;

    // 손잡이와 모서리, 올라오는 속도는 showTossSheet 이 맞춘다.
    await showTossSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StandardText(
              text: '프로필 사진 변경',
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 16),
            _buildSheetOption(
              icon: Icons.photo_library_outlined,
              label: '갤러리에서 선택',
              color: color,
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
            _buildSheetOption(
              icon: Icons.person_outline,
              label: '개구리로 되돌리기',
              color: Colors.grey[600]!,
              onTap: () {
                Navigator.pop(context);
                _resetToDefaultImage();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            StandardText(
                text: label, fontSize: 15, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) return;
    if (!_isSupportedProfileImage(pickedFile.path)) {
      _showProfileSnackBar('JPG, PNG, WEBP 이미지만 사용할 수 있어요.');
      return;
    }

    setState(() => _isUploadingProfileImage = true);
    try {
      final imageUrl = await _fileUploadService.uploadImageFile(pickedFile);
      await userProvider.updateUserProfileImageUrl(imageUrl);
      FirebaseAnalytics.instance.logEvent(name: 'profile_image_updated');
    } catch (_) {
      if (!mounted) return;
      _showProfileSnackBar('프로필 이미지 변경에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  Future<void> _resetToDefaultImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isUploadingProfileImage = true);
    try {
      await userProvider.deleteUserProfileImage();
      FirebaseAnalytics.instance.logEvent(name: 'profile_image_reset');
    } catch (_) {
      if (!mounted) return;
      _showProfileSnackBar('기본 이미지 변경에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  bool _isSupportedProfileImage(String path) {
    final extension = path.split('.').last.toLowerCase();
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';
  }

  Future<void> _showNameChangeDialog(String currentName) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await showTossDialog<void>(
      context: context,
      builder: (dialogContext) => _NameChangeDialog(
        currentName: currentName,
        themeProvider: widget.themeProvider,
        onSave: (newName) async {
          await userProvider.updateUser(name: newName);
          FirebaseAnalytics.instance.logEvent(name: 'username_updated');
        },
        onError: _showProfileSnackBar,
      ),
    );
  }

  void _showProfileSnackBar(String message) {
    // 업로드 중 화면을 벗어나면 dispose 된 State 의 context 에 접근해 죽는다 (FLUTTER-15K)
    if (!mounted) return;
    AppToast.error(message);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = mediaQuery.size.shortestSide >= 600;

    final userProvider = Provider.of<UserProvider>(context);
    final userInfo = userProvider.userInfoModel;
    final currentName = userInfo?.name ?? '이름 없음';
    final color = widget.themeProvider.primaryColor;

    final avatarSize = isTablet ? 76.0 : 62.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * widget.horizontalMarginFactor,
        vertical: screenHeight * 0.005,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          _buildAvatar(userInfo?.profileImageUrl, avatarSize, color),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StandardText(
                  text: currentName,
                  fontSize: isTablet ? 18 : 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                const StandardText(
                  text: '사진과 이름을 바꿀 수 있어요',
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildNameButton(currentName, color),
        ],
      ),
    );
  }

  /// 프로필 사진과 그 위에 붙는 카메라 배지.
  Widget _buildAvatar(String? imageUrl, double size, Color color) {
    // 사진을 안 올렸으면 지금 꾸민 개구리가 선다. 이 자리에서만 넘긴다.
    // 스터디룸에서 보는 남의 프로필은 그대로 둔다.
    final frogLayers = context.watch<CosmeticProvider>().layers;

    return PressableScale(
      onTap: _isUploadingProfileImage ? null : _showProfileImageOptions,
      scale: 0.94,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProfileAvatar(
            imageUrl: imageUrl,
            size: size,
            borderColor: color.withValues(alpha: 0.25),
            borderWidth: 1.2,
            backgroundColor: color.withValues(alpha: 0.06),
            frogLayers: frogLayers,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploadingProfileImage
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameButton(String currentName, Color color) {
    return PressableScale(
      onTap: () => _showNameChangeDialog(currentName),
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: StandardText(
          text: '이름 변경',
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _NameChangeDialog extends StatefulWidget {
  final String currentName;
  final ThemeHandler themeProvider;
  final Future<void> Function(String newName) onSave;
  final ValueChanged<String> onError;

  const _NameChangeDialog({
    required this.currentName,
    required this.themeProvider,
    required this.onSave,
    required this.onError,
  });

  @override
  State<_NameChangeDialog> createState() => _NameChangeDialogState();
}

class _NameChangeDialogState extends State<_NameChangeDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSaving) return;

    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      widget.onError('이름을 입력해주세요.');
      return;
    }
    if (newName.length > 20) {
      widget.onError('이름은 20자 이하로 입력해주세요.');
      return;
    }
    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(newName);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      widget.onError('이름 변경에 실패했습니다. 다시 시도해주세요.');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 380),
      title: const StandardText(
        text: '이름 변경',
        fontSize: 18,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          enabled: !_isSaving,
          autofocus: true,
          maxLength: 20,
          style: const StandardText(text: '').getTextStyle().copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '이름을 입력하세요',
            hintStyle: const StandardText(text: '')
                .getTextStyle()
                .copyWith(color: Colors.grey[400], fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(
                color: widget.themeProvider.primaryColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          onSubmitted: (_) => _saveName(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: StandardText(
            text: '취소',
            fontSize: 13,
            color: Colors.grey[700]!,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveName,
          style: TextButton.styleFrom(
            backgroundColor: widget.themeProvider.primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const StandardText(
                  text: '저장',
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
        ),
      ],
    );
  }
}
