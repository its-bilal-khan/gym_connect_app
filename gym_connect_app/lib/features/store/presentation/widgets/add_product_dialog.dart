import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final String? tenantId;

  const AddProductDialog({super.key, this.tenantId});

  static Future<bool?> show(BuildContext context, {String? tenantId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddProductDialog(tenantId: tenantId),
    );
  }

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  String _category = 'Supplements';
  bool _isSaving = false;
  XFile? _selectedImage;

  final _categories = ['Supplements', 'Drinks', 'Juice Bar', 'Snacks', 'Gear', 'Apparel'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 1080);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? imageUrl = _imageUrlCtrl.text.trim();
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final uploadedUrl = await ref.read(storeRepositoryProvider).uploadProductImage(
            bytes: bytes,
            fileName: _selectedImage!.name,
          );
      if (uploadedUrl != null) imageUrl = uploadedUrl;
    }

    final success = await ref.read(storeActionNotifierProvider.notifier).addProduct(
          name: _nameCtrl.text.trim(),
          category: _category,
          price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
          stockQuantity: int.tryParse(_stockCtrl.text.trim()) ?? 0,
          description: _descCtrl.text.trim(),
          imageUrl: imageUrl,
          tenantId: widget.tenantId,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add product'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('ADD NEW PRODUCT', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImageSelector(),
              const SizedBox(height: 12),
              _buildTextField(_nameCtrl, 'Product Name *', 'e.g. Whey Gold 2.27kg', isRequired: true),
              const SizedBox(height: 10),
              _buildCategoryDropdown(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceCtrl, 'Price (PKR) *', '15000', isNumber: true, isRequired: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_stockCtrl, 'Stock Qty *', '10', isNumber: true, isRequired: true)),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(_descCtrl, 'Description (Optional)', 'Serving size, flavor, benefits...', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary))),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : Text('SAVE PRODUCT', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Center(
          child: _selectedImage != null
              ? Text('Image: ${_selectedImage!.name}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary), overflow: TextOverflow.ellipsis)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(height: 4),
                    Text('Tap to select photo (gallery)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      dropdownColor: AppColors.surface,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _category = val ?? 'Supplements'),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {bool isNumber = false, bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
      validator: (v) => isRequired && (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
