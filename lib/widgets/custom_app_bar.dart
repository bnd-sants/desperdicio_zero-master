import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.textColor,
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: elevation,
      iconTheme: IconThemeData(
        color: textColor ?? Theme.of(context).iconTheme.color,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
