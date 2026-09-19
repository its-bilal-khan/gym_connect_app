import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/metric_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const _cards = [
    MetricCard(
      title: 'Total Members',
      value: '1,248',
      icon: Icons.people_alt_rounded,
      subtitle: '+12% new members this month',
    ),
    MetricCard(
      title: "Today's Revenue",
      value: '\$3,450',
      icon: Icons.payments_rounded,
      subtitle: '+8.4% vs yesterday',
    ),
    MetricCard(
      title: 'Active Subscriptions',
      value: '1,180',
      icon: Icons.card_membership_rounded,
      subtitle: '94.5% retention rate',
    ),
  ];

  Future<void> _handleSignOut() async {
    await Supabase.instance.client.auth.signOut();
    await ref.read(secureStorageProvider).clearAll();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final contentArea = Column(
          children: [
            DashboardHeader(
              gymName: 'TITAN FITNESS CLUB',
              onSignOut: !isDesktop ? _handleSignOut : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < _cards.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: _cards[i])],
                        ],
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _cards.length; i++) ...[if (i > 0) const SizedBox(height: 16), _cards[i]],
                        ],
                      ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    backgroundColor: AppColors.surface,
                    selectedItemColor: AppColors.primaryAccent,
                    unselectedItemColor: AppColors.textSecondary,
                    selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard_rounded),
                        label: 'Dashboard',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.people_rounded),
                        label: 'Members',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.point_of_sale_rounded),
                        label: 'POS',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings_rounded),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
          body: SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      DashboardSidebar(
                        selectedIndex: _selectedIndex,
                        onItemSelected: (index) => setState(() => _selectedIndex = index),
                        onSignOut: _handleSignOut,
                      ),
                      Expanded(child: contentArea),
                    ],
                  )
                : contentArea,
          ),
        );
      },
    );
  }
}
