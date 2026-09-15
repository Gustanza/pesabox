import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key, this.transactionId = 'tx1'});

  final String transactionId;

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
              const AuthHeader(title: 'Transaction Details'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green100,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: AppColors.green600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TZS 10,000',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mandatory Savings',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  children: [
                    _KVRow(label: 'Transaction ID', value: 'TX-0042'),
                    Divider(height: 24),
                    _KVRow(label: 'Member', value: 'Neema Joseph'),
                    Divider(height: 24),
                    _KVRow(label: 'Meeting', value: 'Meeting #012'),
                    Divider(height: 24),
                    _KVRow(label: 'Fund', value: 'Savings'),
                    Divider(height: 24),
                    _KVRow(label: 'Payment method', value: 'Cash'),
                    Divider(height: 24),
                    _KVRow(label: 'Recorded by', value: 'Admin User'),
                    Divider(height: 24),
                    _KVRow(label: 'Date/Time', value: '14 Sep 2026 · 10:12 AM'),
                    Divider(height: 24),
                    _StatusRow(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: 'Correct / reverse transaction',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.correctionReversalPath(transactionId),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;

  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Status',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.green100,
            borderRadius: AppRadius.sm,
          ),
          child: Text(
            'Completed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.teal800,
            ),
          ),
        ),
      ],
    );
  }
}