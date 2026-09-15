import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import 'auth_widgets.dart';

const int _codeLength = 4;

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 45;
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _phone ??= ModalRoute.of(context)?.settings.arguments as String?;
    if (_phone == null || _phone!.isEmpty) {
      // Got here without a phone number to verify — bounce back to login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (r) => false,
          );
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _format(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _phone == null) return;
    setState(() => _resending = true);
    try {
      await AuthService.requestOtp(_phone!);
      _startTimer();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend the code.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_phone == null) return;
    if (_code.length < _codeLength) {
      setState(() => _error = 'Enter the $_codeLength-digit code');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await AuthService.verifyOtp(_phone!, _code);
      final hasGroup = await AppState.I.checkGroupAssignment();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        hasGroup ? AppRouter.dashboard : AppRouter.awaitingAssignment,
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Invalid or expired code');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(),
              const SizedBox(height: 24),
              Text(
                'Verify your phone number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: "We've texted a $_codeLength-digit code to\n",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.ink600,
                  ),
                  children: [
                    TextSpan(
                      text: _phone ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (var i = 0; i < _codeLength; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink900,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty &&
                                  i < _controllers.length - 1) {
                                FocusScope.of(context)
                                    .requestFocus(_focusNodes[i + 1]);
                              } else if (value.isEmpty && i > 0) {
                                FocusScope.of(context)
                                    .requestFocus(_focusNodes[i - 1]);
                              }
                              if (_error != null) setState(() => _error = null);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'Resend code (${_format(_secondsRemaining)})',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.ink400,
                        ),
                      )
                    : GestureDetector(
                        onTap: _resending ? null : _resend,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _resending ? 'Resending…' : 'Resend code',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green600,
                            ),
                          ),
                        ),
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                text: _verifying ? 'Verifying…' : 'Verify',
                onPressed: _verifying ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
