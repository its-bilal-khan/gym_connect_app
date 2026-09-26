import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../app_theme_presets.dart';
import '../app_theme_provider.dart';
import 'theme_color_card.dart';
import 'theme_change_request_dialog.dart';
import '../../../features/auth/domain/models/user_profile.dart';
import '../../../features/auth/domain/models/user_role.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../features/auth/presentation/providers/auth_state.dart';

class ThemeColorSwitcherDialog extends ConsumerStatefulWidget {
  const ThemeColorSwitcherDialog({super.key});

  /// Opens the theme color switcher as an adaptive dialog or bottom sheet
  /// seamlessly supporting both desktop and mobile form factors.
  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => const ThemeColorSwitcherDialog(),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ThemeColorSwitcherDialog(),
      );
    }
  }

  @override
  ConsumerState<ThemeColorSwitcherDialog> createState() => _ThemeColorSwitcherDialogState();
}

class _ThemeColorSwitcherDialogState extends ConsumerState<ThemeColorSwitcherDialog> {
  AppThemePreset? _stagedPreset;

  void _onPresetTapped(AppThemePreset preset, AppThemeState themeState, bool isOwner) {
    if (themeState.isPermanentLocked && isOwner) {
      // If locked, inform owner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Theme is permanently locked to ${themeState.lockedPreset?.name ?? 'gym brand'}. Submit a request to change.',
            style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _stagedPreset = preset);
    ref.read(appThemeNotifierProvider.notifier).previewTheme(preset);
  }

  Future<void> _confirmLockPermanently(
    AppThemePreset preset,
    UserProfile profile,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: preset.color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lock Theme Permanently?',
                style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently set ${preset.name} (${preset.hex}) as the official brand theme for ${profile.tenantName}?',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: preset.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: preset.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Once permanently locked, this color scheme will run everywhere across mobile & desktop. To switch colors later, you must generate an admin change request.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: preset.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('YES, LOCK PERMANENTLY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(appThemeNotifierProvider.notifier).lockThemePermanently(
            tenantId: profile.tenantId ?? '',
            preset: preset,
            profile: profile,
          );

      if (mounted && success) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              '✓ Official brand theme permanently locked to ${preset.name}!',
              style: GoogleFonts.inter(color: preset.color, fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    UserProfile? profile;
    UserRole activeRole = UserRole.member;
    if (authState is AuthAuthenticated) {
      profile = authState.profile;
      activeRole = authState.activeRole;
    }

    final isOwner = activeRole == UserRole.owner || (profile?.tenantId != null && activeRole != UserRole.member && activeRole != UserRole.publicUser);
    final activePreset = _stagedPreset ?? themeState.currentPreset;

    Widget content = Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, activePreset),
          const SizedBox(height: 14),
          _buildStatusBanner(themeState, isOwner, profile),
          const SizedBox(height: 16),
          _buildGrid(themeState, isOwner, activePreset),
          const SizedBox(height: 18),
          _buildFooterActions(context, themeState, isOwner, profile, activePreset),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: content,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: content,
    );
  }

  Widget _buildHeader(BuildContext context, AppThemePreset activePreset) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: activePreset.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: activePreset.color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Icon(Icons.palette_rounded, color: activePreset.color, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BRAND COLOR & THEME PALETTE',
                style: GoogleFonts.oswald(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Select high-contrast dark theme primary accent',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(AppThemeState themeState, bool isOwner, UserProfile? profile) {
    if (themeState.isPermanentLocked && isOwner) {
      final locked = themeState.lockedPreset ?? themeState.currentPreset;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: locked.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, size: 16, color: locked.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THEME PERMANENTLY LOCKED TO ${locked.shortName.toUpperCase()}',
                    style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: locked.color),
                  ),
                  Text(
                    themeState.hasPendingRequest
                        ? 'Change request pending review: ${themeState.pendingRequestedPreset?.name ?? ''}'
                        : 'To switch to a different color, submit a change request.',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select a color to preview or lock permanently for ${profile?.tenantName ?? 'your gym'}.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGrid(AppThemeState themeState, bool isOwner, AppThemePreset activePreset) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 420 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppThemePreset.values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 115,
          ),
          itemBuilder: (context, index) {
            final preset = AppThemePreset.values[index];
            final isSel = activePreset == preset;
            final isLocked = themeState.isPermanentLocked && themeState.lockedPreset == preset;

            return ThemeColorCard(
              preset: preset,
              isSelected: isSel,
              isLocked: isLocked,
              onTap: () => _onPresetTapped(preset, themeState, isOwner),
            );
          },
        );
      },
    );
  }

  Widget _buildFooterActions(
    BuildContext context,
    AppThemeState themeState,
    bool isOwner,
    UserProfile? profile,
    AppThemePreset activePreset,
  ) {
    if (isOwner && themeState.isPermanentLocked) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            themeState.hasPendingRequest ? 'Request Pending' : 'Theme Locked',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          ElevatedButton.icon(
            onPressed: themeState.hasPendingRequest
                ? null
                : () {
                    ThemeChangeRequestDialog.show(
                      context,
                      profile: profile!,
                      currentLockedPreset: themeState.lockedPreset ?? activePreset,
                    );
                  },
            icon: Icon(
              themeState.hasPendingRequest ? Icons.hourglass_top_rounded : Icons.edit_note_rounded,
              size: 16,
            ),
            label: Text(
              themeState.hasPendingRequest ? 'CHANGE PENDING' : 'REQUEST NEW COLOR',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    if (isOwner && !themeState.isPermanentLocked && profile != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'KEEP PREVIEW',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _confirmLockPermanently(activePreset, profile),
            icon: const Icon(Icons.lock_outline_rounded, size: 16),
            label: Text(
              'LOCK PERMANENTLY',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: activePreset.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: activePreset.color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('DONE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
