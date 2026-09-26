import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../app_theme_presets.dart';

class ThemeColorCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const ThemeColorCard({
    super.key,
    required this.preset,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? preset.color
        : (isLocked ? preset.color.withValues(alpha: 0.5) : AppColors.border);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? preset.color.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: preset.color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: preset.color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(preset.icon, size: 16, color: Colors.black),
                  ),
                ),
                const Spacer(),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: preset.color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 10, color: preset.color),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: preset.color,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: preset.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preset.name,
              style: GoogleFonts.oswald(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  preset.hex,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? preset.color : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    preset.description,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
