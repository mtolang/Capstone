import 'package:flutter/material.dart';
import 'package:kindora/theme/app_theme.dart';

/// Polished Card Widget with consistent styling
class PolishedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool elevated;
  final VoidCallback? onTap;
  
  const PolishedCard({
    Key? key,
    required this.child,
    this.padding,
    this.elevated = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: elevated 
          ? AppTheme.elevatedCardDecoration 
          : AppTheme.cardDecoration,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
      child: child,
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardRadius,
        child: card,
      );
    }
    
    return card;
  }
}

/// Polished Button with gradient support
class PolishedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gradient;
  final bool outlined;
  final bool loading;
  final Color? color;
  final double? width;
  
  const PolishedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient = false,
    this.outlined = false,
    this.loading = false,
    this.color,
    this.width,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: width,
        height: 50,
        decoration: BoxDecoration(
          color: color ?? AppTheme.primaryTeal,
          borderRadius: AppTheme.buttonRadius,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    
    if (outlined) {
      return SizedBox(
        width: width,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: AppTheme.outlinedButtonStyle.copyWith(
            side: MaterialStateProperty.all(
              BorderSide(color: color ?? AppTheme.primaryTeal, width: 2),
            ),
          ),
          icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
          label: Text(text),
        ),
      );
    }
    
    if (gradient) {
      return Container(
        width: width,
        height: 50,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.buttonRadius,
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppTheme.buttonRadius,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTheme.buttonText.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: AppTheme.elevatedButtonStyle.copyWith(
          backgroundColor: MaterialStateProperty.all(color ?? AppTheme.primaryTeal),
        ),
        icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
        label: Text(text),
      ),
    );
  }
}

/// Polished Text Field
class PolishedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  
  const PolishedTextField({
    Key? key,
    this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: AppTheme.bodyLarge,
      decoration: AppTheme.inputDecoration(
        hint: hint,
        label: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textGrey) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Polished App Bar
class PolishedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool gradient;
  
  const PolishedAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.gradient = false,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: gradient ? Colors.transparent : AppTheme.primaryTeal,
      elevation: gradient ? 0 : 2,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
    
    if (gradient) {
      return Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: appBar,
      );
    }
    
    return appBar;
  }
}

/// Polished Status Chip
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  
  const StatusChip({
    Key? key,
    required this.label,
    required this.color,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.primaryTealLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppTheme.primaryTealLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              PolishedButton(
                text: actionLabel!,
                onPressed: onAction,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading Overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  
  const LoadingOverlay({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: PolishedCard(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          elevated: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTheme.loadingIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  message!,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  
  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.trailing,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryTeal, size: 24),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTheme.headingSmall,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Info Row (Label: Value)
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  
  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Text(
            '$label: ',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
