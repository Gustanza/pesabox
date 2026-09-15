import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RecordLoanScreen extends StatelessWidget {
  const RecordLoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const AuthHeader(
                title: 'Loan Application',
                subtitle: 'John Mfinanga',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SelectField(
                      label: 'Select member',
                      initial: 'John Mfinanga',
                      options: [
                        'John Mfinanga',
                        'Neema Joseph',
                        'Asha Mwangi',
                        'Grace Kileo',
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _Field(
                      label: 'Requested amount',
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount (e.g. 120,000)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SelectField(
                      label: 'Purpose',
                      initial: 'Business',
                      options: ['Business', 'Agriculture', 'Education', 'Emergency'],
                    ),
                    const SizedBox(height: 16),
                    const _SelectField(
                      label: 'Repayment period',
                      initial: '3 months',
                      options: ['3 months', '6 months', '9 months', '12 months'],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: AppRadius.md,
                ),
                child: Column(
                  children: [
                    const _EligRow(
                      label: 'Eligible amount (3x savings)',
                      value: 'TZS 255K',
                    ),
                    const Divider(height: 24, color: Color(0xFFC9E8D6)),
                    const _EligRow(label: 'Interest rate', value: '10%'),
                    const Divider(height: 24, color: Color(0xFFC9E8D6)),
                    _EligRow(
                      label: 'Est monthly repayment',
                      value: 'TZS ${_fmt(110000)}',
                      strong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  child: Text(
                    'Submit application',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double amount) =>
      amount.toInt().toString().replaceAll(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            ',',
          );
}

class _EligRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _EligRow({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.teal900,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: strong ? 16 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.teal900,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  final String label;
  final String initial;
  final List<String> options;

  const _SelectField({
    required this.label,
    required this.initial,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: initial,
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (_) {},
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.teal900,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}