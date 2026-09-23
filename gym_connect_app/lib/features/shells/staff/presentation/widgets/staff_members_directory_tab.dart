import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/shared/widgets/action_card.dart';
import 'package:gym_connect_app/features/staff/data/staff_reception_repository.dart';

class StaffMembersDirectoryTab extends ConsumerStatefulWidget {
  const StaffMembersDirectoryTab({super.key});

  @override
  ConsumerState<StaffMembersDirectoryTab> createState() => _StaffMembersDirectoryTabState();
}

class _StaffMembersDirectoryTabState extends ConsumerState<StaffMembersDirectoryTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final membersAsync = ref.watch(staffMembersProvider(_searchQuery));

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEMBER DIRECTORY & LOOKUP',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_search_rounded, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 10),
                        Text(
                          'No members found',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search by name or enroll new members at reception.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = members[i];
                    return ActionCard(
                      icon: Icons.account_circle_rounded,
                      title: m.fullName,
                      subtitle: '${m.planName ?? "Standard"} • ${m.phone ?? "No phone"} • ${m.status}',
                      actionLabel: 'DETAILS',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${m.fullName} - Status: ${m.status}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primaryAccent),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Error loading directory: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
            SizedBox(height: 110 + bottomInset),
          ],
        ),
      ),
    );
  }
}
