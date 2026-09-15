import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RecordContributionScreen extends StatelessWidget {
  const RecordContributionScreen({super.key, this.meetingId = '12'});

  final String meetingId;

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
              AuthHeader(
                title: 'Record Contribution',
                subtitle: 'Meeting #012',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              const _StepIndicator(activeStep: 1),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Select member',
                children: [
                  _SelectField(
                    label: 'Member',
                    initial: 'Neema Joseph',
                    options: groupMembers.map((m) => m.fullName).toList(),
                  ),
                  const SizedBox(height: 16),
                  _SelectField(
                    label: 'Contribution type',
                    initial: 'Mandatory Savings',
                    options: const [
                      'Mandatory Savings',
                      'Voluntary Savings',
                      'Special Contribution',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Amount',
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.ink400,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.line, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.teal900, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SelectField(
                    label: 'Payment method',
                    initial: 'Cash',
                    options: ['Cash', 'Mobile Money', 'Bank Transfer'],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.meetingActivityPath(meetingId),
                    );
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
                    'Next',
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
}

class _StepIndicator extends StatelessWidget {
  final int activeStep;

  const _StepIndicator({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Member', 'Details', 'Review'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _Step(
              number: i + 1,
              label: steps[i],
              active: (i + 1) == activeStep,
            ),
          ),
          if (i < steps.length - 1)
            Container(
              height: 1,
              width: 20,
              color: AppColors.line,
            ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool active;

  const _Step({
    required this.number,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.green600 : AppColors.white,
            border: Border.all(
              color: active ? AppColors.green600 : AppColors.line,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.white : AppColors.ink600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.teal900 : AppColors.ink400,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.teal900, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}