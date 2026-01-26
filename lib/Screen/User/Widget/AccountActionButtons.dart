import 'package:flutter/material.dart';
import '../../../Module/Text/StandardText.dart';

class AccountActionButtons extends StatelessWidget {
  final VoidCallback onLogoutTap;
  final VoidCallback onDeleteAccountTap;

  const AccountActionButtons({
    super.key,
    required this.onLogoutTap,
    required this.onDeleteAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTextButton(
            text: '로그아웃',
            onTap: onLogoutTap,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 12,
            color: Colors.grey[400],
          ),
          _buildTextButton(
            text: '회원 탈퇴',
            onTap: onDeleteAccountTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: StandardText(
          text: text,
          fontSize: 12,
          color: Colors.grey[500]!,
        ),
      ),
    );
  }
}