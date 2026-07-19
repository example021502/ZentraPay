import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class NavigationBarMain extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationBarMain({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.main.withAlpha(230),
            borderRadius: BorderRadius.circular(200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, "Home", Icons.home),
              _buildNavItem(1, "ZRemit", Icons.compare_arrows),
              _buildNavItem(2, "ZGrow", Icons.trending_up),
              _buildNavItem(3, "ZBank", Icons.account_balance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    return NavButton(
      label: label,
      icon: icon,
      isActive: selectedIndex == index,
      onTap: () => onItemSelected(index),
    );
  }
}

class NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? AppColors.main : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isActive
                ? AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isActive ? 1.2 : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(200)),
                        color: isActive
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  )
                : Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: AppColors.primary),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
            // const SizedBox(height: 4),
            // const SizedBox(height: 6),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 200),
            //   height: 3,
            //   width: isActive ? 16 : 0,
            //   decoration: BoxDecoration(
            //     color: AppColors.main,
            //     borderRadius: BorderRadius.circular(2),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
