class TenantPaymentSettings {
  final String tenantId;
  final bool isPayfastEnabled;
  final bool isManualPaymentEnabled;
  final String? manualEasypaisaNumber;
  final String? manualBankDetails;

  const TenantPaymentSettings({
    required this.tenantId,
    this.isPayfastEnabled = false,
    this.isManualPaymentEnabled = false,
    this.manualEasypaisaNumber,
    this.manualBankDetails,
  });

  bool get hasAnyPaymentMethod => isPayfastEnabled || isManualPaymentEnabled;

  factory TenantPaymentSettings.fromJson(Map<String, dynamic> json) {
    return TenantPaymentSettings(
      tenantId: json['id'] as String? ?? json['tenant_id'] as String? ?? '',
      isPayfastEnabled: json['is_payfast_enabled'] as bool? ?? false,
      isManualPaymentEnabled: json['is_manual_payment_enabled'] as bool? ?? false,
      manualEasypaisaNumber: json['manual_easypaisa_number'] as String?,
      manualBankDetails: json['manual_bank_details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_payfast_enabled': isPayfastEnabled,
      'is_manual_payment_enabled': isManualPaymentEnabled,
      'manual_easypaisa_number': manualEasypaisaNumber,
      'manual_bank_details': manualBankDetails,
    };
  }

  TenantPaymentSettings copyWith({
    String? tenantId,
    bool? isPayfastEnabled,
    bool? isManualPaymentEnabled,
    String? manualEasypaisaNumber,
    String? manualBankDetails,
  }) {
    return TenantPaymentSettings(
      tenantId: tenantId ?? this.tenantId,
      isPayfastEnabled: isPayfastEnabled ?? this.isPayfastEnabled,
      isManualPaymentEnabled: isManualPaymentEnabled ?? this.isManualPaymentEnabled,
      manualEasypaisaNumber: manualEasypaisaNumber ?? this.manualEasypaisaNumber,
      manualBankDetails: manualBankDetails ?? this.manualBankDetails,
    );
  }
}
