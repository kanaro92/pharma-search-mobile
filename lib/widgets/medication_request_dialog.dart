import 'package:flutter/material.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class MedicationRequestDialog extends StatefulWidget {
  final Pharmacy pharmacy;
  final ApiService apiService;

  const MedicationRequestDialog({
    Key? key,
    required this.pharmacy,
    required this.apiService,
  }) : super(key: key);

  @override
  _MedicationRequestDialogState createState() => _MedicationRequestDialogState();
}

class _MedicationRequestDialogState extends State<MedicationRequestDialog> {
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _medicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_medicationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.get('enterMedicationName')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.apiService.sendMedicationInquiry(
        _medicationController.text,
        _notesController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('inquirySentSuccess')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to send inquiry');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquirySentError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pharmacy.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.pharmacy.address,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _medicationController,
              decoration: InputDecoration(
                hintText: AppLocalizations.get('searchMedicationsHint'),
                prefixIcon: Icon(
                  Icons.medication_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.get('additionalNotesHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(AppLocalizations.get('sendInquiryButton')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
