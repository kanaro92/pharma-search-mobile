import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/medication_inquiry.dart';
import '../models/message.dart';
import '../services/user_service.dart';
import '../utils/date_formatter.dart';
import '../l10n/app_localizations.dart';

class ConversationDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final MedicationInquiry inquiry;
  final int pharmacyId;
  final String pharmacyName;

  const ConversationDetailScreen({
    Key? key,
    required this.apiService,
    required this.inquiry,
    required this.pharmacyId,
    required this.pharmacyName,
  }) : super(key: key);

  @override
  _ConversationDetailScreenState createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final email = await UserService().getCurrentUserEmail();
    setState(() {
      _currentUserEmail = email;
    });
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await widget.apiService.getInquiryMessages(
        widget.inquiry.id,
        widget.pharmacyId,
      );
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await widget.apiService.sendPharmacyMessage(
        widget.inquiry.id,
        widget.pharmacyId,
        _messageController.text.trim(),
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pharmacyName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.inquiry.medicationName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser = message.isCurrentUser(_currentUserEmail ?? '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isCurrentUser
                                      ? null
                                      : Border.all(
                                          color: theme.colorScheme.surfaceVariant
                                              .withOpacity(0.3),
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isCurrentUser
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormatter.formatDateTime(message.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: (isCurrentUser
                                                ? Colors.white
                                                : theme.colorScheme.onSurface)
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isCurrentUser)
                              Container(
                                margin: const EdgeInsets.only(left: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.get('typeMessage'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
