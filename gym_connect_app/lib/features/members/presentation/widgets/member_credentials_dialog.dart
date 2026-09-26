import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/gym_member.dart';

class MemberCredentialsDialog extends StatefulWidget {
  final GymMember member;
  final Function(String newPassword) onSavePassword;

  const MemberCredentialsDialog({
    super.key,
    required this.member,
    required this.onSavePassword,
  });

  static Future<void> show(
    BuildContext context, {
    required GymMember member,
    required Function(String newPassword) onSavePassword,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MemberCredentialsDialog(
        member: member,
        onSavePassword: onSavePassword,
      ),
    );
  }

  @override
  State<MemberCredentialsDialog> createState() => _MemberCredentialsDialogState();
}

class _MemberCredentialsDialogState extends State<MemberCredentialsDialog> {
  late TextEditingController _passwordController;
  bool _obscure = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.member.tempPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#';
    final random = Random.secure();
    final pass = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = 'GC@$pass';
    });
  }

  void _copyCredentials() {
    final text = '''
GymConnect Member Access Credentials:
Member: ${widget.member.fullName} (${widget.member.memberCode})
Login Email: ${widget.member.email}
Phone: ${widget.member.phone}
Password: ${_passwordController.text}
Portal: https://app.gymconnect.pk
''';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login credentials copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _sendWhatsApp() async {
    final phone = widget.member.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Salam ${widget.member.fullName}!\nWelcome to Titan Fitness Club. Here are your GymConnect App Login Credentials:\n• Member Code: ${widget.member.memberCode}\n• Email: ${widget.member.email}\n• Password: ${_passwordController.text}\nDownload & login to access your workout plan and digital turnstile gate pass.',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _copyCredentials();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.key_rounded, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGIN & CREDENTIALS',
                            style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${widget.member.fullName} (${widget.member.memberCode})',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Username / Login Identifier Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildFieldRow('Member Code', widget.member.memberCode),
                    const Divider(color: AppColors.border, height: 14),
                    _buildFieldRow('Login Email', widget.member.email),
                    const Divider(color: AppColors.border, height: 14),
                    _buildFieldRow('Registered Phone', widget.member.phone),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Text('ACTIVE PASSWORD / PIN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textSecondary, size: 18),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: accent.withValues(alpha: 0.4))),
                    ),
                    icon: const Icon(Icons.autorenew_rounded, size: 16),
                    label: Text('Generate', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _generateRandomPassword,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons (Copy, WhatsApp, Save)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _copied ? Colors.greenAccent : Colors.white,
                        side: BorderSide(color: _copied ? Colors.greenAccent : AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 16),
                      label: Text(_copied ? 'Copied!' : 'Copy Info', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: _copyCredentials,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 16, color: Colors.greenAccent),
                      label: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: _sendWhatsApp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Save Pass', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        widget.onSavePassword(_passwordController.text.trim());
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
