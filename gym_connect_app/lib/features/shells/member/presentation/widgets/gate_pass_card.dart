import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../../../core/theme/app_colors.dart';
import 'gate_pass_qr_preview.dart';

class GatePassCard extends StatefulWidget {
  const GatePassCard({super.key});

  @override
  State<GatePassCard> createState() => _GatePassCardState();
}

class _GatePassCardState extends State<GatePassCard> {
  Timer? _timer;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  int _secondsRemaining = 10;
  late String _currentToken;
  bool _shakeEnabled = true;
  bool _isUnlocking = false;
  DateTime _lastShakeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentToken = _generateToken();
    _startTimer();
    _listenShake();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }

  void _listenShake() {
    _accelSub?.cancel();
    if (!_shakeEnabled) return;

    try {
      _accelSub = userAccelerometerEventStream().listen((event) {
        if (!_shakeEnabled || _isUnlocking) return;
        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (magnitude > 14.0) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime).inMilliseconds > 2000) {
            _lastShakeTime = now;
            _simulateGateUnlock(isShakeTrigger: true);
          }
        }
      }, onError: (err) {
        debugPrint('Shake detection error: $err');
      });
    } catch (e) {
      debugPrint('Shake sensor unavailable: $e');
    }
  }

  String _generateToken() {
    final rand = Random();
    return 'GC-${1000 + rand.nextInt(9000)}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 10;
          _currentToken = _generateToken();
        }
      });
    });
  }

  Future<void> _simulateGateUnlock({bool isShakeTrigger = false}) async {
    HapticFeedback.heavyImpact();
    setState(() => _isUnlocking = true);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _isUnlocking = false;
      // Anti-Passback & Security Protection: Auto-disconnect shake after successful entry
      if (isShakeTrigger) {
        _shakeEnabled = false;
        _accelSub?.cancel();
      }
    });
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primaryAccent)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isShakeTrigger
                    ? '⚡ Gate Unlocked (5s) • Shake Auto-Disabled (Anti-Passback)'
                    : 'ESP32 Gate Signal Sent: Magnetic Lock Released (5s)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(accent),
          const SizedBox(height: 18),
          GatePassQrPreview(currentToken: _currentToken, isUnlocking: _isUnlocking, accent: accent),
          const SizedBox(height: 10),
          Text('Refreshes dynamically every 10s • Single Device Protected', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _shakeEnabled ? accent : AppColors.textSecondary,
                    side: BorderSide(color: _shakeEnabled ? accent.withValues(alpha: 0.5) : AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _shakeEnabled = !_shakeEnabled;
                      _listenShake();
                    });
                  },
                  icon: Icon(_shakeEnabled ? Icons.vibration_rounded : Icons.phone_android_rounded, size: 16),
                  label: Text(_shakeEnabled ? 'Shake: ON' : 'Shake: OFF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _isUnlocking ? null : () => _simulateGateUnlock(),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text('TEST UNLOCK', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
              Text('DEVICE ID LOCKED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(value: _secondsRemaining / 10.0, strokeWidth: 2.5, color: accent, backgroundColor: Colors.white10),
            ),
            const SizedBox(width: 8),
            Text('${_secondsRemaining}s', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
          ],
        ),
      ],
    );
  }
}
