import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../payments/data/payments_repository.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../payments/presentation/widgets/manual_bank_details_card.dart';
import '../../../payments/presentation/widgets/receipt_upload_picker.dart';
import '../../data/store_repository.dart';
import '../providers/store_providers.dart';
import '../widgets/store_fulfillment_card.dart';
import 'order_tracking_screen.dart';

class StoreCheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, int> cart;
  final List<StoreProduct> allProducts;
  final double totalAmount;
  final VoidCallback onOrderPlaced;

  const StoreCheckoutScreen({
    super.key,
    required this.cart,
    required this.allProducts,
    required this.totalAmount,
    required this.onOrderPlaced,
  });

  static Future<void> open(
    BuildContext context, {
    required Map<String, int> cart,
    required List<StoreProduct> allProducts,
    required double totalAmount,
    required VoidCallback onOrderPlaced,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreCheckoutScreen(
          cart: cart,
          allProducts: allProducts,
          totalAmount: totalAmount,
          onOrderPlaced: onOrderPlaced,
        ),
      ),
    );
  }

  @override
  ConsumerState<StoreCheckoutScreen> createState() => _StoreCheckoutScreenState();
}

class _StoreCheckoutScreenState extends ConsumerState<StoreCheckoutScreen> {
  bool _isDelivery = false;
  String _paymentMethod = 'manual_proof';
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  XFile? _selectedFile;
  Uint8List? _imageBytes;
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider);
    if (auth is AuthAuthenticated) {
      _nameController.text = auth.profile.fullName;
      _phoneController.text = auth.profile.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_isDelivery && (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill delivery address and phone number')));
      return;
    }

    setState(() => _isPlacing = true);
    String? receiptUrl;

    try {
      if (_paymentMethod == 'manual_proof') {
        if (_imageBytes == null || _selectedFile == null) {
          setState(() => _isPlacing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please attach your EasyPaisa / Bank transfer screenshot proof', style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: Colors.amber.shade900,
            ),
          );
          return;
        }
        final paymentRepo = ref.read(paymentsRepositoryProvider);
        receiptUrl = await paymentRepo.uploadReceiptImage(bytes: _imageBytes!, fileName: _selectedFile!.name);
        if (receiptUrl == null) {
          throw Exception('Failed to upload receipt screenshot. Please check connection and try again.');
        }
      }

      final pickupCode = 'PK-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
      final tenantId = widget.allProducts.isNotEmpty ? widget.allProducts.first.tenantId : null;
      final orderId = await ref.read(storeRepositoryProvider).createStoreOrder(
            pickupCode: pickupCode,
            totalAmount: widget.totalAmount,
            cartItems: widget.cart,
            allProducts: widget.allProducts,
            fulfillmentType: _isDelivery ? 'delivery' : 'pickup',
            deliveryAddress: _isDelivery ? _addressController.text.trim() : null,
            deliveryPhone: _phoneController.text.trim(),
            customerName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Customer',
            paymentMethod: _paymentMethod,
            paymentReceiptUrl: receiptUrl,
            tenantId: tenantId,
          );

      if (orderId == null) throw Exception('Could not place order');

      widget.onOrderPlaced();
      ref.invalidate(customerOrdersProvider);
      if (tenantId != null && tenantId.isNotEmpty) {
        ref.invalidate(tenantStoreOrdersProvider(tenantId));
      }
      ref.invalidate(tenantStoreOrdersProvider(''));

      if (!mounted) return;
      setState(() => _isPlacing = false);

      Navigator.pop(context); // pop checkout screen
      OrderTrackingScreen.open(context, initialOrderId: orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order submission failed: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = widget.allProducts.isNotEmpty ? widget.allProducts.first.tenantId : '';
    final settingsAsync = tenantId.isNotEmpty
        ? ref.watch(tenantPaymentSettingsProvider(tenantId))
        : ref.watch(currentGymPaymentSettingsProvider);
    final settings = settingsAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('CHECKOUT & FULFILLMENT', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreFulfillmentCard(
              isDelivery: _isDelivery,
              onToggleFulfillment: (val) => setState(() => _isDelivery = val),
              nameController: _nameController,
              addressController: _addressController,
              phoneController: _phoneController,
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodSection(settings),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isPlacing ? null : _submitOrder,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isPlacing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('CONFIRM ORDER • PKR ${widget.totalAmount.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(dynamic settings) {
    final bool isPayfastEnabled = settings?.isPayfastEnabled ?? false;

    final List<Map<String, dynamic>> availableMethods = [
      {
        'id': 'manual_proof',
        'title': 'Manual Transfer (Proof of Payment)',
        'sub': 'Transfer via EasyPaisa / Bank & attach screenshot',
        'icon': Icons.upload_file_rounded,
      },
    ];

    if (isPayfastEnabled) {
      availableMethods.add({
        'id': 'payfast',
        'title': 'PayFast Digital Gateway',
        'sub': 'Instant Debit/Credit card or JazzCash',
        'icon': Icons.flash_on_rounded,
      });
    }

    availableMethods.add({
      'id': 'counter',
      'title': _isDelivery ? 'Cash on Delivery (COD)' : 'Pay Cash at Reception Counter',
      'sub': 'Pay when receiving your items',
      'icon': Icons.point_of_sale_rounded,
    });

    // Auto-select valid available method if selection is invalid
    if (availableMethods.isNotEmpty && !availableMethods.any((m) => m['id'] == _paymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _paymentMethod = availableMethods.first['id'] as String);
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELECT PAYMENT METHOD', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          ...availableMethods.map((m) => _paymentOption(
                m['id'] as String,
                m['title'] as String,
                m['sub'] as String,
                m['icon'] as IconData,
              )),
          if (_paymentMethod == 'manual_proof') ...[
            const SizedBox(height: 12),
            ManualBankDetailsCard(easypaisaNumber: settings?.manualEasypaisaNumber, bankDetails: settings?.manualBankDetails, amount: widget.totalAmount),
            const SizedBox(height: 12),
            ReceiptUploadPicker(
              selectedFile: _selectedFile,
              imageBytes: _imageBytes,
              isUploading: _isPlacing,
              onImageSelected: (f) => setState(() => _selectedFile = f),
              onBytesLoaded: (b) => setState(() => _imageBytes = b),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentOption(String id, String title, String sub, IconData icon) {
    final isSelected = _paymentMethod == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(sub, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
