import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/creme_pills.dart';
import '../services/hangout_repository.dart';

class CreateShareSheet extends StatefulWidget {
  const CreateShareSheet({super.key});

  @override
  State<CreateShareSheet> createState() => _CreateShareSheetState();
}

class _CreateShareSheetState extends State<CreateShareSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give your share a name');
      return;
    }

    setState(() => _busy = true);
    final hangout = HangoutRepository.instance.createShare(
      title: title,
      location: _locationController.text.trim(),
    );
    setState(() => _busy = false);

    if (!mounted) return;
    Navigator.pop(context, hangout.id);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, topInset > 40 ? 24 : 36, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New share',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.04,
                  letterSpacing: -1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Everyone who scans your pass drops photos here.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              _LabeledField(
                label: 'Event name',
                controller: _titleController,
                hint: 'Neon rooftop hangout',
              ),
              _LabeledField(
                label: 'Where (optional)',
                controller: _locationController,
                hint: 'Skyline Terrace, Brooklyn',
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerRight,
                child: _busy
                    ? const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : RoundActionButton(
                        icon: Icons.arrow_forward,
                        onTap: _create,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDisabled,
                letterSpacing: -0.2,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
