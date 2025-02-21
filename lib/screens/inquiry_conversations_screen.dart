import 'package:flutter/material.dart';
import '../models/pharmacy_conversation.dart';
import '../models/medication_inquiry.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/date_formatter.dart';
import './conversation_detail_screen.dart';

class InquiryConversationsScreen extends StatefulWidget {
  final ApiService apiService;
  final MedicationInquiry inquiry;

  const InquiryConversationsScreen({
    Key? key,
    required this.apiService,
    required this.inquiry,
  }) : super(key: key);

  @override
  _InquiryConversationsScreenState createState() => _InquiryConversationsScreenState();
}

class _InquiryConversationsScreenState extends State<InquiryConversationsScreen> {
  bool _isLoading = false;
  List<PharmacyConversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await widget.apiService.getInquiryConversations(widget.inquiry.id);
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading conversations: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
              widget.inquiry.medicationName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_conversations.length} ${AppLocalizations.get('pharmaciesResponded')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.get('noConversationsYet'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.get('waitingForPharmacies'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConversationDetailScreen(
                                  apiService: widget.apiService,
                                  inquiry: widget.inquiry,
                                  pharmacyId: conversation.pharmacyId,
                                  pharmacyName: conversation.pharmacyName,
                                ),
                              ),
                            ).then((_) => _loadConversations());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_pharmacy_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conversation.pharmacyName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (conversation.lastMessage != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          conversation.lastMessage!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (conversation.lastMessageTime != null)
                                  Text(
                                    DateFormatter.formatTimeAgo(conversation.lastMessageTime!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
