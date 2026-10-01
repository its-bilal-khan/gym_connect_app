import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class MemberDataTable extends StatefulWidget {
  final List<GymMember> members;
  final bool showDeepInsights;
  final Function(GymMember) onEdit;
  final Function(GymMember) onDelete;
  final Function(GymMember) onManageCredentials;
  final Function(GymMember) onToggleFreeze;
  final Function(GymMember) onSendReminder;

  const MemberDataTable({
    super.key,
    required this.members,
    required this.showDeepInsights,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCredentials,
    required this.onToggleFreeze,
    required this.onSendReminder,
  });

  @override
  State<MemberDataTable> createState() => _MemberDataTableState();
}

class _MemberDataTableState extends State<MemberDataTable> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
  }

  @override
  void didUpdateWidget(MemberDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showDeepInsights != widget.showDeepInsights ||
        oldWidget.members.length != widget.members.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canLeft = currentScroll > 6;
    final canRight = currentScroll < (maxScroll - 6);
    final overflowing = maxScroll > 0;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight || overflowing != _isOverflowing) {
      if (mounted) {
        setState(() {
          _canScrollLeft = canLeft;
          _canScrollRight = canRight;
          _isOverflowing = overflowing;
        });
      }
    }
  }

  void _scrollToStart() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollBy(double offset) {
    if (_scrollController.hasClients) {
      final target = (_scrollController.offset + offset)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live SaaS Status Bar & Horizontal Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1B1B1E),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  final isNarrow = barConstraints.maxWidth < 780;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Live Status & Column Counter
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'LIVE DATABASE ROSTER • ${widget.members.length} MEMBERS LOADED',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_isOverflowing && !isNarrow) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 12, color: accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.showDeepInsights ? 11 : 8} Columns',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Right: Navigation Controls or Direct Actions Label
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isOverflowing) ...[
                            // Scroll Left Button
                            Tooltip(
                              message: 'Scroll left',
                              child: InkWell(
                                onTap: _canScrollLeft ? () => _scrollBy(-260) : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _canScrollLeft ? AppColors.background : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _canScrollLeft ? AppColors.border : Colors.transparent),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: 18,
                                    color: _canScrollLeft ? Colors.white : Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Scroll Right Button
                            Tooltip(
                              message: 'Scroll right',
                              child: InkWell(
                                onTap: _canScrollRight ? () => _scrollBy(260) : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _canScrollRight ? AppColors.background : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _canScrollRight ? AppColors.border : Colors.transparent),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: _canScrollRight ? Colors.white : Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick Jump Button (Jump to Actions or Back to Start)
                            InkWell(
                              onTap: _canScrollRight ? _scrollToEnd : _scrollToStart,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _canScrollRight ? accent.withValues(alpha: 0.15) : AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _canScrollRight ? accent.withValues(alpha: 0.5) : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _canScrollRight ? Icons.bolt_rounded : Icons.first_page_rounded,
                                      size: 13,
                                      color: _canScrollRight ? accent : Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _canScrollRight ? 'Jump to Actions ➔' : 'Back to Start ◀',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _canScrollRight ? accent : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Direct Actions: WhatsApp Alert • Credentials • Freeze • Edit • Delete',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // 2. Responsive Horizontal Scroll Table Container
            Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: _isOverflowing,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      thumbColor: accent.withValues(alpha: 0.6),
                      trackColor: const Color(0xFF131316),
                      trackBorderColor: Colors.transparent,
                      interactive: true,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent && _scrollController.hasClients) {
                              final delta = pointerSignal.scrollDelta.dx != 0
                                  ? pointerSignal.scrollDelta.dx
                                  : (HardwareKeyboard.instance.isShiftPressed ? pointerSignal.scrollDelta.dy : 0.0);
                              if (delta != 0) {
                                final newOffset = (_scrollController.offset + delta)
                                    .clamp(0.0, _scrollController.position.maxScrollExtent);
                                _scrollController.jumpTo(newOffset);
                              }
                            }
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFF222226)),
                                headingRowHeight: 46,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 68,
                                columnSpacing: 18,
                                horizontalMargin: 16,
                                dividerThickness: 0.8,
                                headingTextStyle: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.9,
                                ),
                                dataTextStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                columns: [
                                  _buildColumnHeader(Icons.badge_outlined, 'MEMBER CODE'),
                                  _buildColumnHeader(Icons.person_outline_rounded, 'MEMBER DETAILS'),
                                  _buildColumnHeader(Icons.phone_outlined, 'CONTACT'),
                                  _buildColumnHeader(Icons.workspace_premium_outlined, 'MEMBERSHIP PLAN'),
                                  _buildColumnHeader(Icons.verified_outlined, 'STATUS'),
                                  _buildColumnHeader(Icons.calendar_today_outlined, 'EXPIRY DATE'),
                                  _buildColumnHeader(Icons.payments_outlined, 'DUES'),
                                  if (widget.showDeepInsights) ...[
                                    _buildColumnHeader(Icons.fitness_center_rounded, 'WORKOUT PROTOCOL'),
                                    _buildColumnHeader(Icons.local_fire_department_rounded, 'CONSISTENCY'),
                                    _buildColumnHeader(Icons.door_sliding_outlined, 'LAST GATE SCAN'),
                                  ],
                                  _buildColumnHeader(Icons.bolt_rounded, 'ACTIONS'),
                                ],
                                rows: widget.members.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final m = entry.value;
                                  final isEven = index % 2 == 0;
                                  final isExp = m.isExpired;

                                  final statusColor = m.isFrozen
                                      ? Colors.cyanAccent
                                      : isExp
                                          ? Colors.redAccent
                                          : Colors.greenAccent;

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.hovered)) {
                                        return accent.withValues(alpha: 0.08);
                                      }
                                      return isEven ? AppColors.surface : const Color(0xFF131316);
                                    }),
                                    cells: [
                                      // 1. Member Code Pill
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: accent.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            m.memberCode,
                                            style: GoogleFonts.oswald(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 2. Member Name with Avatar + Quick 3-Dots Action Menu
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 17,
                                              backgroundColor: accent.withValues(alpha: 0.15),
                                              child: Text(
                                                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                                                style: GoogleFonts.oswald(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: accent,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ConstrainedBox(
                                                      constraints: const BoxConstraints(maxWidth: 140),
                                                      child: Text(
                                                        m.fullName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    if (m.isExpiringSoon) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                                                        ),
                                                        child: Text(
                                                          '⚠️ ${m.daysUntilExpiry}d',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.orangeAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 140),
                                                  child: Text(
                                                    m.email.isNotEmpty ? m.email : 'No email registered',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Instant Quick Action Trigger (accessible directly without horizontal scrolling)
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white38),
                                              tooltip: 'Quick Actions',
                                              color: AppColors.surface,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: const BorderSide(color: AppColors.border),
                                              ),
                                              onSelected: (val) {
                                                switch (val) {
                                                  case 'edit':
                                                    widget.onEdit(m);
                                                    break;
                                                  case 'credentials':
                                                    widget.onManageCredentials(m);
                                                    break;
                                                  case 'freeze':
                                                    widget.onToggleFreeze(m);
                                                    break;
                                                  case 'whatsapp':
                                                    widget.onSendReminder(m);
                                                    break;
                                                  case 'delete':
                                                    widget.onDelete(m);
                                                    break;
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.edit_rounded, size: 15, color: Colors.white70),
                                                      const SizedBox(width: 8),
                                                      Text('Edit Member', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'credentials',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.key_rounded, size: 15, color: accent),
                                                      const SizedBox(width: 8),
                                                      Text('Manage Credentials', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'freeze',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        m.isFrozen ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                                                        size: 15,
                                                        color: m.isFrozen ? Colors.greenAccent : Colors.cyanAccent,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        m.isFrozen ? 'Unfreeze Membership' : 'Freeze Membership',
                                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (m.isExpiringSoon)
                                                  PopupMenuItem(
                                                    value: 'whatsapp',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.send_rounded, size: 15, color: Colors.greenAccent),
                                                        const SizedBox(width: 8),
                                                        Text('WhatsApp Renewal Alert', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                                                      ],
                                                    ),
                                                  ),
                                                const PopupMenuDivider(height: 1),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                                                      const SizedBox(width: 8),
                                                      Text('Remove Member', style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 3. Contact Phone
                                      DataCell(
                                        Text(
                                          m.phone.trim().isNotEmpty ? m.phone : '—',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: m.phone.trim().isNotEmpty ? Colors.white70 : AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      // 4. Membership Plan Badge
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            m.planName.isNotEmpty ? m.planName : 'Standard Plan',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ),
                                      ),

                                      // 5. Status Pill with Glowing Dot
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                m.statusDisplay,
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 6. Expiry Date with Calendar Icon
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 12, color: isExp ? Colors.redAccent : AppColors.textSecondary),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${m.expiryDate.year}-${m.expiryDate.month.toString().padLeft(2, '0')}-${m.expiryDate.day.toString().padLeft(2, '0')}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isExp ? Colors.redAccent : Colors.white70,
                                                fontWeight: isExp ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 7. Dues Tag
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: m.duesAmount > 0 ? Colors.redAccent.withValues(alpha: 0.15) : Colors.greenAccent.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: m.duesAmount > 0 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.greenAccent.withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Text(
                                            m.duesAmount > 0 ? 'PKR ${m.duesAmount.toStringAsFixed(0)} DUE' : 'PAID',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: m.duesAmount > 0 ? Colors.redAccent : Colors.greenAccent,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 8. Deep Telemetry: Workout Protocol
                                      if (widget.showDeepInsights) ...[
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.fitness_center_rounded, size: 13, color: accent),
                                              const SizedBox(width: 6),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 150),
                                                child: Text(
                                                  m.assignedProtocol.isNotEmpty
                                                      ? '${m.assignedProtocol} (Day ${m.currentRoutineDay})'
                                                      : 'General Split (Day ${m.currentRoutineDay})',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orangeAccent.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              '🔥 ${m.currentStreakDays}D • ${m.totalCheckIns} visits',
                                              style: GoogleFonts.oswald(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 140),
                                            child: Text(
                                              m.lastScanGate.isNotEmpty ? m.lastScanGate : 'No scans recorded',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ],

                                      // 9. Actions Toolbar Capsule
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (m.isExpiringSoon)
                                                IconButton(
                                                  icon: const Icon(Icons.send_rounded, size: 14),
                                                  color: Colors.greenAccent,
                                                  tooltip: 'Send WhatsApp Renewal Alert',
                                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () => widget.onSendReminder(m),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.key_rounded, size: 14),
                                                color: accent,
                                                tooltip: 'Manage Credentials / Password',
                                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => widget.onManageCredentials(m),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  m.isFrozen ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                                                  size: 14,
                                                  color: m.isFrozen ? Colors.greenAccent : Colors.cyanAccent,
                                                ),
                                                tooltip: m.isFrozen ? 'Unfreeze Membership' : 'Freeze Membership (Leave)',
                                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => widget.onToggleFreeze(m),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                                                tooltip: 'Edit Member',
                                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => widget.onEdit(m),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                                tooltip: 'Remove Member',
                                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => widget.onDelete(m),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Left Edge Fade Hint (Visual Indicator that columns exist to the left)
                if (_canScrollLeft)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.surface.withValues(alpha: 0.95),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Right Edge Fade Hint (Visual Indicator that columns exist to the right)
                if (_canScrollRight)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.95),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _buildColumnHeader(IconData icon, String title) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
