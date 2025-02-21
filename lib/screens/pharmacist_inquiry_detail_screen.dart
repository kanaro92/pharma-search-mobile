import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/medication_inquiry.dart';
import '../models/message.dart';
import '../services/user_service.dart';
import '../utils/date_formatter.dart';
import '../l10n/app_localizations.dart';

class PharmacistInquiryDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final MedicationInquiry inquiry;

  const PharmacistInquiryDetailScreen({
    Key? key,
    required this.apiService,
    required this.inquiry,
  }) : super(key: key);

  @override
  _PharmacistInquiryDetailScreenState createState() => _PharmacistInquiryDetailScreenState();
}

class _PharmacistInquiryDetailScreenState extends State<PharmacistInquiryDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _currentUserEmail;
  bool _isSending = false;
  bool _isRespondingPharmacy = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCurrentUser();
    _checkRespondingStatus();
  }

  Future<void> _checkRespondingStatus() async {
    if (widget.inquiry.respondingPharmacies != null) {
      final currentUser = await UserService().getCurrentUser();
      setState(() {
        _isRespondingPharmacy = widget.inquiry.respondingPharmacies!
            .any((pharmacy) => pharmacy.id == currentUser?['id']);
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final email = await UserService().getCurrentUserEmail();
    setState(() {
      _currentUserEmail = email;
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await widget.apiService.getMedicationInquiryMessages(widget.inquiry.id);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.sendInquiryResponse(widget.inquiry.id, message);
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendResponse() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await widget.apiService.sendInquiryResponse(
        widget.inquiry.id,
        _messageController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.get('inquiryResponseSent')),
          backgroundColor: Colors.green,
        ),
      );

      _messageController.clear();
      await _loadMessages();
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquiryResponseError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _respondToInquiry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.respondToInquiry(widget.inquiry.id);
      setState(() {
        _isRespondingPharmacy = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquiryResponseSuccess')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquiryResponseError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _withdrawFromInquiry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.withdrawFromInquiry(widget.inquiry.id);
      setState(() {
        _isRespondingPharmacy = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquiryWithdrawSuccess')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('inquiryWithdrawError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.get('inquiryDetails'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isRespondingPharmacy && widget.inquiry.status != 'CLOSED')
            IconButton(
              icon: const Icon(Icons.add_task_rounded),
              tooltip: AppLocalizations.get('respondToInquiry'),
              onPressed: _respondToInquiry,
            ),
          if (_isRespondingPharmacy && widget.inquiry.status != 'CLOSED')
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: AppLocalizations.get('withdrawFromInquiry'),
              onPressed: _withdrawFromInquiry,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Inquiry Details Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.inquiry.medicationName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatDate(widget.inquiry.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (widget.inquiry.status == 'PENDING'
                                    ? Colors.orange
                                    : Colors.green)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.inquiry.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: widget.inquiry.status == 'PENDING'
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.inquiry.patientNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.inquiry.patientNote,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.inquiry.respondingPharmacies?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.get('respondingPharmacies'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.inquiry.respondingPharmacies!.map((pharmacy) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  pharmacy.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Messages List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isCurrentUser =
                            _currentUserEmail != null && message.isCurrentUser(_currentUserEmail!);

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                              left: 8,
                              right: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                                bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isCurrentUser
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${message.getSenderName()} • ${DateFormatter.formatDateTime(message.createdAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: (isCurrentUser
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurfaceVariant)
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Message Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.get('responseHint'),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
