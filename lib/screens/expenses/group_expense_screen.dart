import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class GroupExpenseScreen extends StatefulWidget {
  const GroupExpenseScreen({super.key});

  @override
  State<GroupExpenseScreen> createState() => _GroupExpenseScreenState();
}

class _GroupExpenseScreenState extends State<GroupExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _method = 'Cash';
  String? _meetingId;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _meetingId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (description.isEmpty) {
      _showError(tr('Enter a description'));
      return;
    }
    if (amount <= 0) {
      _showError(tr('Enter a valid amount'));
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppState.I.recordExpense(
        amount: amount,
        description: description,
        method: _method,
        meetingId: _meetingId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(message)), behavior: SnackBarBehavior.floating),
    );
  }

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
              AuthHeader(title: tr('Log Group Expense')),
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
                    _Field(
                      label: tr('Description'),
                      child: TextField(
                        controller: _descriptionController,
                        decoration:
                            InputDecoration(hintText: tr('e.g. Printing cards')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: tr('Amount (TZS)'),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(hintText: tr('Enter amount')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: tr('Payment method'),
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                            .map((m) => DropdownMenuItem(value: m, child: Text(tr(m))))
                            .toList(),
                        onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              HxButton(
                text: tr('Save expense'),
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
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
        Text(tr(label), style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
