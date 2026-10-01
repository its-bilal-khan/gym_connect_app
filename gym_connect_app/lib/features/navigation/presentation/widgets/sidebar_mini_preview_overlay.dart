import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/scaled_live_preview.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../calculators/presentation/screens/calculators_hub_screen.dart';
import 'sidebar_owner_overview_mini_preview.dart';
import '../../../shells/owner/presentation/widgets/owner_operations_tab.dart';
import '../../../shells/owner/presentation/widgets/owner_settings_tab.dart';
import '../../../shells/owner/presentation/widgets/owner_staff_audit_tab.dart';
import '../../../staff/presentation/desktop/desktop_staff_pos_workstation_view.dart';
import '../../../super_admin/presentation/desktop/desktop_super_admin_workstation_view.dart';

/// Resolves which mini preview widget to show for a given sidebar nav item ID.
/// Returns a [ScaledLivePreview] containing the EXACT module UI rendered by
/// that screen, ensuring 100% fidelity and automatic real-time state reflection.
Widget? resolveMiniPreviewForNavId({
  required String navId,
  required UserRole role,
  UserProfile? profile,
  String? tenantId,
}) {
  final effectiveProfile = profile ??
      UserProfile(
        id: '',
        email: '',
        fullName: 'Gym User',
        role: role,
        tenantId: tenantId,
      );

  // ── Owner role sidebar items ──────────────────────────────
  if (role == UserRole.owner) {
    switch (navId) {
      case 'overview':
        return SidebarOwnerOverviewMiniPreview(
          tenantId: effectiveProfile.tenantId ?? '',
        );
      case 'pos_staff':
        // Exactly matches Screenshot 4: Staff Oversight & Audit Watchdog
        return ScaledLivePreview(
          virtualWidth: 900,
          virtualHeight: 460,
          child: OwnerStaffAuditTab(profile: effectiveProfile),
        );
      case 'live_ops':
        // Exactly matches Screenshot 3: Hardware & IoT Gate Status
        return ScaledLivePreview(
          virtualWidth: 900,
          virtualHeight: 460,
          child: OwnerOperationsTab(profile: effectiveProfile),
        );
      case 'tools':
        // Exactly matches Screenshot 2: Fitness Calculators
        return const ScaledLivePreview(
          virtualWidth: 1050,
          virtualHeight: 550,
          child: CalculatorsHubScreen(),
        );
      case 'settings':
        // Exactly matches Screenshot 1: Gym Settings & Multi-Tenant Branding
        return ScaledLivePreview(
          virtualWidth: 950,
          virtualHeight: 500,
          child: OwnerSettingsTab(profile: effectiveProfile),
        );
    }
  }

  // ── Super Admin role sidebar items ────────────────────────
  if (role == UserRole.superAdmin) {
    switch (navId) {
      case 'tenants':
        return ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopSuperAdminWorkstationView(
            profile: effectiveProfile,
            initialTabIndex: 0,
          ),
        );
      case 'onboard':
        return ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopSuperAdminWorkstationView(
            profile: effectiveProfile,
            initialTabIndex: 1,
          ),
        );
      case 'exercises':
        return ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopSuperAdminWorkstationView(
            profile: effectiveProfile,
            initialTabIndex: 2,
          ),
        );
      case 'analytics':
        return ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopSuperAdminWorkstationView(
            profile: effectiveProfile,
            initialTabIndex: 3,
          ),
        );
      case 'system':
        return ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopSuperAdminWorkstationView(
            profile: effectiveProfile,
            initialTabIndex: 4,
          ),
        );
      case 'tools':
        return const ScaledLivePreview(
          virtualWidth: 1050,
          virtualHeight: 550,
          child: CalculatorsHubScreen(),
        );
    }
  }

  // ── Staff role sidebar items ──────────────────────────────
  if (role == UserRole.staff) {
    switch (navId) {
      case 'pos_register':
        return const ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopStaffPosWorkstationView(initialTabIndex: 0),
        );
      case 'reception':
        return const ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopStaffPosWorkstationView(initialTabIndex: 1),
        );
      case 'members':
        return const ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopStaffPosWorkstationView(initialTabIndex: 2),
        );
      case 'shift':
        return const ScaledLivePreview(
          virtualWidth: 1100,
          virtualHeight: 580,
          child: DesktopStaffPosWorkstationView(initialTabIndex: 3),
        );
      case 'tools':
        return const ScaledLivePreview(
          virtualWidth: 1050,
          virtualHeight: 550,
          child: CalculatorsHubScreen(),
        );
    }
  }

  return null;
}



/// A hover-triggered overlay that displays a mini preview tooltip on the right
/// side of a sidebar navigation item—exactly like a tooltip but with a live
/// module preview inside.
class SidebarMiniPreviewOverlay extends StatefulWidget {
  final Widget child;
  final Widget? previewWidget;
  final Widget? Function()? previewBuilder;
  final String label;
  final Duration hoverWaitDuration;

  const SidebarMiniPreviewOverlay({
    super.key,
    required this.child,
    this.previewWidget,
    this.previewBuilder,
    required this.label,
    this.hoverWaitDuration = const Duration(milliseconds: 600),
  });

  @override
  State<SidebarMiniPreviewOverlay> createState() =>
      _SidebarMiniPreviewOverlayState();
}

class _SidebarMiniPreviewOverlayState
    extends State<SidebarMiniPreviewOverlay> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final preview = widget.previewBuilder != null
        ? widget.previewBuilder!()
        : widget.previewWidget;
    if (preview == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final accent = Theme.of(context).colorScheme.primary;
        return Positioned(
          width: 380,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(248, -40),
            child: Material(
              color: Colors.transparent,
              child: MouseRegion(
                onEnter: (_) => _cancelHide(),
                onExit: (_) => _startHide(),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0C0F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(4, 4),
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      children: [
                        // Mini titlebar
                        Container(
                          height: 22,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161B),
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF5F56),
                                ),
                              ),
                              const SizedBox(width: 3.5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFBD2E),
                                ),
                              ),
                              const SizedBox(width: 3.5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF27C93F),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'PREVIEW // ${widget.label.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.8),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live preview viewport
                        Expanded(
                          child: IgnorePointer(
                            child: preview,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Timer? _showDebounceTimer;
  int _hideTimer = 0;

  void _onTargetEnter() {
    _cancelHide();
    _showDebounceTimer?.cancel();
    // 600ms intentional hover debounce: avoids accidental triggers when cursor brushes past
    _showDebounceTimer = Timer(widget.hoverWaitDuration, () {
      if (_isHovered && mounted) {
        _showOverlay();
      }
    });
  }

  void _onTargetExit() {
    _showDebounceTimer?.cancel();
    _startHide();
  }

  void _startHide() {
    _isHovered = false;
    final currentTimer = ++_hideTimer;
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!_isHovered && currentTimer == _hideTimer && mounted) {
        _hideOverlay();
      }
    });
  }

  void _cancelHide() {
    _isHovered = true;
    _hideTimer++;
  }

  @override
  void dispose() {
    _showDebounceTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onTargetEnter(),
        onExit: (_) => _onTargetExit(),
        child: widget.child,
      ),
    );
  }
}
