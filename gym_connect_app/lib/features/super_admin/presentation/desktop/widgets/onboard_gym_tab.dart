import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/tenant_model.dart';
import '../../providers/tenant_providers.dart';

class OnboardGymTab extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const OnboardGymTab({super.key, required this.onSuccess});

  @override
  ConsumerState<OnboardGymTab> createState() => _OnboardGymTabState();
}

class _OnboardGymTabState extends ConsumerState<OnboardGymTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _city = 'Lahore';
  String _tier = 'pro';
  int _maxMembers = 500;
  bool _aiEnabled = true;
  bool _posEnabled = true;
  bool _esp32Enabled = true;
  bool _storeEnabled = true;
  Color _selectedColor = const Color(0xFFCCFF00);
  bool _isDeploying = false;

  final List<String> _cities = [
    'Lahore',
    'Islamabad',
    'Karachi',
    'Rawalpindi',
    'Peshawar',
    'Faisalabad',
    'Multan',
    'Quetta'
  ];

  final List<Color> _brandColors = [
    const Color(0xFFCCFF00), // Neon Volt
    const Color(0xFF00F0FF), // Cyber Cyan
    const Color(0xFFA855F7), // Neon Purple
    const Color(0xFFF59E0B), // Warm Amber
    const Color(0xFF10B981), // Emerald Green
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_slugCtrl.text.isEmpty || _slugCtrl.text == _generateSlug(_nameCtrl.text.substring(0, _nameCtrl.text.length - 1))) {
      _slugCtrl.text = _generateSlug(val);
    }
  }

  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _deployTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isDeploying = true);
    final notifier = ref.read(superAdminTenantsNotifierProvider.notifier);

    final newTenant = TenantModel(
      id: 'tenant-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _city,
      country: 'Pakistan',
      subscriptionStatus: 'active',
      subscriptionTier: _tier,
      maxMembers: _maxMembers,
      aiTrainerEnabled: _aiEnabled,
      posEnabled: _posEnabled,
      esp32GateEnabled: _esp32Enabled,
      storeEnabled: _storeEnabled,
      isActive: true,
      primaryColor: _selectedColor,
      createdAt: DateTime.now(),
      activeMembersCount: 0,
    );

    final res = await notifier.createTenant(newTenant);
    if (!mounted) return;
    setState(() => _isDeploying = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Gym Tenant "${newTenant.name}" onboarded successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to onboard tenant. Please verify inputs.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 880),
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _selectedColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.add_business_rounded, color: _selectedColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ONBOARD NEW GYM TENANT',
                            style: GoogleFonts.oswald(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Deploy a dedicated multi-tenant gym workstation with real PostgreSQL isolation',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                _buildSectionTitle('1. BASIC GYM CREDENTIALS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _nameCtrl,
                        label: 'Gym Name',
                        hint: 'e.g. Peak Alpha Fitness',
                        icon: Icons.fitness_center_rounded,
                        onChanged: _onNameChanged,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _slugCtrl,
                        label: 'URL Subdomain Slug',
                        hint: 'e.g. peak-alpha',
                        icon: Icons.link_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCityDropdown(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneCtrl,
                        label: 'Contact Phone',
                        hint: '+92 300 0000000',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _emailCtrl,
                        label: 'Admin Email',
                        hint: 'owner@gym.pk',
                        icon: Icons.email_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressCtrl,
                  label: 'Physical Address',
                  hint: 'Plot/Floor, Sector, City',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('2. SAAS SUBSCRIPTION TIER & SIZING'),
                const SizedBox(height: 12),
                _buildTierSelector(),
                const SizedBox(height: 20),
                _buildMemberSlider(),
                const SizedBox(height: 28),
                _buildSectionTitle('3. HARDWARE & FEATURE PERMISSIONS'),
                const SizedBox(height: 12),
                _buildFeatureCheckboxes(),
                const SizedBox(height: 28),
                _buildSectionTitle('4. BRANDING PRIMARY COLOR'),
                const SizedBox(height: 12),
                _buildColorPicker(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isDeploying ? null : _deployTenant,
                    icon: _isDeploying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 20),
                    label: Text(
                      _isDeploying ? 'DEPLOYING TO POSTGRESQL...' : 'DEPLOY & REGISTER GYM TENANT',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.oswald(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _city,
      dropdownColor: AppColors.surface,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'City',
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
      items: _cities
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => _city = val ?? 'Lahore'),
    );
  }

  Widget _buildTierSelector() {
    final tiers = [
      (key: 'starter', name: 'Starter Tier', price: 'PKR 15,000/mo', desc: 'Up to 300 members, basic POS'),
      (key: 'pro', name: 'Pro Professional', price: 'PKR 35,000/mo', desc: 'Up to 700 members, full IoT & AI'),
      (key: 'enterprise', name: 'Enterprise VIP', price: 'PKR 75,000/mo', desc: 'Unlimited, turnstile & cameras'),
    ];

    return Row(
      children: tiers.map((t) {
        final isSelected = _tier == t.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _tier = t.key),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _selectedColor.withValues(alpha: 0.12) : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _selectedColor : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(t.price, style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? _selectedColor : Colors.white70)),
                    const SizedBox(height: 4),
                    Text(t.desc, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max Member Capacity Allowance:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            Text('$_maxMembers Members', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedColor)),
          ],
        ),
        Slider(
          value: _maxMembers.toDouble(),
          min: 100,
          max: 2000,
          divisions: 19,
          activeColor: _selectedColor,
          inactiveColor: AppColors.background,
          onChanged: (val) => setState(() => _maxMembers = val.toInt()),
        ),
      ],
    );
  }

  Widget _buildFeatureCheckboxes() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildCheckbox('AI Trainer & Routine Builder', _aiEnabled, (v) => setState(() => _aiEnabled = v)),
        _buildCheckbox('Desktop POS Register Desk', _posEnabled, (v) => setState(() => _posEnabled = v)),
        _buildCheckbox('ESP32 IoT Turnstile Gate Relay', _esp32Enabled, (v) => setState(() => _esp32Enabled = v)),
        _buildCheckbox('In-Gym Supplement Store & Khata', _storeEnabled, (v) => setState(() => _storeEnabled = v)),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool val, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!val),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: val ? _selectedColor.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: val ? _selectedColor : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(val ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: val ? _selectedColor : AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: val ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: _brandColors.map((color) {
        final isSelected = _selectedColor == color;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedColor = color),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5),
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : null,
              ),
              child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
