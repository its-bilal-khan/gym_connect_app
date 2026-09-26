import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';

class StoreProductGridCard extends StatefulWidget {
  final StoreProduct product;
  final int inCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback? onRemoveFromCart;

  const StoreProductGridCard({
    super.key,
    required this.product,
    required this.inCart,
    required this.onTap,
    required this.onAddToCart,
    this.onRemoveFromCart,
  });

  @override
  State<StoreProductGridCard> createState() => _StoreProductGridCardState();
}

class _StoreProductGridCardState extends State<StoreProductGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isSelected = widget.inCart > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (_isHovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Proportional Product Image that fills upper area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.product.effectiveImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.background,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, error, stackTrace) => Container(
                        color: const Color(0xFF141416),
                        child: const Center(
                          child: Icon(Icons.fitness_center_rounded, color: AppColors.textSecondary, size: 36),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category Badge (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          widget.product.category.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // In-Cart Badge (Top Right)
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Text(
                            '${widget.inCart} IN CART',
                            style: GoogleFonts.oswald(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    // Servings / Pack size (Bottom Right of Image)
                    if (widget.product.servings.isNotEmpty && widget.product.servings != 'Standard Pack')
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.product.servings,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info & Price Bar (Bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.providerBrand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'PKR ${widget.product.price.toInt()}',
                            style: GoogleFonts.oswald(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (isSelected && widget.onRemoveFromCart != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: widget.onRemoveFromCart,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${widget.inCart}',
                                  style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              InkWell(
                                onTap: widget.onAddToCart,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: Colors.black),
                                ),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: widget.onAddToCart,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : accent.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_rounded : Icons.add_rounded,
                                    size: 14,
                                    color: isSelected ? AppColors.primary : accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isSelected ? 'ADDED' : 'ADD',
                                    style: GoogleFonts.oswald(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: isSelected ? AppColors.primary : accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
