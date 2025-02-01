import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final int? medicationRequestId;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.medicationRequestId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<types.Message> _messages = [];
  final ApiService _apiService = ApiService();
  late types.User _user;
  bool _isLoading = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _setupUser();
    _initializeConversation();
  }

  void _setupUser() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user!;
    _user = types.User(
      id: currentUser.id.toString(),
      firstName: currentUser.name,
    );
  }

  Future<void> _initializeConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get or create a conversation between the current user and the other user
      _conversationId = await _apiService.getOrCreateConversation(
        widget.otherUserId,
        widget.medicationRequestId,
      );
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing conversation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;

    try {
      final response = await _apiService.getMessages(
        conversationId: _conversationId!,
        medicationRequestId: widget.medicationRequestId,
      );

      final messages = response.map((msg) {
        final isCurrentUser = msg.senderId.toString() == _user.id;
        return msg.toFlutterChatMessage(isCurrentUser);
      }).toList();

      setState(() {
        _messages.clear();  // Clear existing messages before adding new ones
        _messages.addAll(messages);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading messages: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_conversationId == null) return;

    try {
      final response = await _apiService.sendChatMessage(
        conversationId: _conversationId!,
        receiverId: widget.otherUserId,
        content: message.text,
        medicationRequestId: widget.medicationRequestId,
      );

      final newMessage = response.toFlutterChatMessage(true);
      setState(() {
        _messages.insert(0, newMessage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
              theme: DefaultChatTheme(
                primaryColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
    );
  }
}
