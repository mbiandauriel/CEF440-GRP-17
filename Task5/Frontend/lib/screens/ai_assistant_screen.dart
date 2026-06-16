import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dtc_record.dart';
import '../services/openrouter_service.dart';
import '../services/vehicle_profile_service.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isTyping = false,
  });

  final String text;
  final bool isUser;
  final String time;
  final bool isTyping;
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({
    super.key,
    this.initialFaultCode,
    this.initialFaultDescription,
    this.faultRecord,
  });

  final String? initialFaultCode;
  final String? initialFaultDescription;
  final DtcRecord? faultRecord;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late List<ChatMessage> _messages;

  static const _suggestedQuestions = [
    'What does P0300 mean?',
    'Is it safe to keep driving?',
    'How much will repairs cost?',
    'What should I check first?',
  ];

  @override
  void initState() {
    super.initState();
    _messages = _buildInitialMessages();
  }

  List<ChatMessage> _buildInitialMessages() {
    if (widget.initialFaultCode != null) {
      return [
        ChatMessage(
          text:
              'Hi! I see a fault was detected on your vehicle. I\'m your CAFAD technician assistant — ask me anything about ${widget.initialFaultCode}${widget.initialFaultDescription != null ? " (${widget.initialFaultDescription})" : ""}.',
          isUser: false,
          time: 'Now',
        ),
      ];
    }
    return [
      const ChatMessage(
        text:
            'Hello! I\'m your CAFAD AI technician. I can explain OBD2 fault codes, dashboard warnings, and guide you through next steps — just like a real mechanic would.',
        isUser: false,
        time: 'Now',
      ),
      const ChatMessage(
        text:
            'Scan your vehicle or share a fault code, and I\'ll break it down in plain language.',
        isUser: false,
        time: 'Now',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _sendMessage([String? text]) async {
    final message = (text ?? _messageController.text).trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true, time: 'Now'));
      _messages.add(
        const ChatMessage(
          text: '',
          isUser: false,
          time: 'Now',
          isTyping: true,
        ),
      );
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !m.isTyping)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      // Keep last 10 messages for context
      final recent = history.length > 10
          ? history.sublist(history.length - 10)
          : history;

      final reply = await OpenRouterService.instance.chat(
        messages: recent,
        faultRecord: widget.faultRecord,
        vehicleDisplayName:
            VehicleProfileService.instance.profile.displayName,
      );

      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(text: reply, isUser: false, time: 'Now'),
        );
      });
    } on OpenRouterException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(text: e.message, isUser: false, time: 'Now'),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: 'Sorry, I could not reach the AI service. Please try again.',
            isUser: false,
            time: 'Now',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final hasFault = widget.initialFaultCode != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'AI Technician',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Online • Ready to help',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasFault) _buildFaultBanner(),
          Expanded(child: _buildMessageList()),
          if (_messages.length <= 2) _buildSuggestedQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildFaultBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Fault: ${widget.initialFaultCode}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                if (widget.initialFaultDescription != null)
                  Text(
                    widget.initialFaultDescription!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _ChatBubble(message: msg);
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              _suggestedQuestions[index],
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            onPressed: () => _sendMessage(_suggestedQuestions[index]),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Ask about your fault...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: message.isTyping
                  ? _TypingIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.time,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person_rounded, size: 18, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = i * 0.2;
              final value = (_controller.value - delay).clamp(0.0, 1.0);
              final opacity = (value * 3.14159).clamp(0.3, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
