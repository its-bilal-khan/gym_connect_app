class PaymentSubmission {
  final String id;
  final String tenantId;
  final String userId;
  final double amount;
  final String? receiptImageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String paymentMethod;
  final DateTime createdAt;
  final String userFullName;
  final String userEmail;
  final String? userPhone;

  const PaymentSubmission({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.amount,
    this.receiptImageUrl,
    required this.status,
    this.paymentMethod = 'manual_transfer',
    required this.createdAt,
    this.userFullName = 'Member',
    this.userEmail = '',
    this.userPhone,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory PaymentSubmission.fromJson(Map<String, dynamic> json) {
    String name = 'Member';
    String email = '';
    String? phone;

    final profile = json['profiles'];
    if (profile is Map<String, dynamic>) {
      name = profile['full_name'] as String? ?? name;
      email = profile['email'] as String? ?? email;
      phone = profile['phone'] as String?;
    }

    return PaymentSubmission(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['member_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      receiptImageUrl: json['receipt_image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String? ?? 'manual_transfer',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userFullName: name,
      userEmail: email,
      userPhone: phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'user_id': userId,
      'amount': amount,
      'receipt_image_url': receiptImageUrl,
      'status': status,
      'payment_method': paymentMethod,
    };
  }
}
