import 'package:flutter/material.dart';
import 'package:betdofe_app_new/constants.dart';

class FooterBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const FooterBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: AppConstants.lightGreenShade1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(context, Icons.home, 0),
          _buildIcon(context, Icons.bar_chart, 1),
          const SizedBox(width: 48),
          _buildIcon(context, Icons.account_balance, 2),
          _buildIcon(context, Icons.track_changes, 3), // Novo ícone de metas
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, int index) {
    final bool isSelected = selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF1B5E20) : Colors.grey,
        size: 28,
      ),
      onPressed: () => onTap(index),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
