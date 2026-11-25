import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../services/firebase_service.dart';

class SupplierChatScreen extends StatefulWidget {
  final OrderModel order;
  const SupplierChatScreen({super.key, required this.order});
  @override
  State<SupplierChatScreen> createState() => _SupplierChatScreenState();
}

class _SupplierChatScreenState extends State<SupplierChatScreen> {
  final _controller = TextEditingController();
  final _localMessages = <Map<String, dynamic>>[
    {
      'text': 'Xin chào, FreshFarm đã nhận được đơn hàng của bạn. Bạn cần hỗ trợ gì không?',
      'sender': 'supplier',
    },
    {
      'text': 'Nông sản sẽ được đóng gói trong thùng giữ nhiệt trước khi giao.',
      'sender': 'supplier',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F4),
    appBar: AppBar(
      title: const Text('Chat với nhà cung cấp'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                'FreshFarm',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhà cung cấp FreshFarm',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Đơn ${widget.order.id} • Phản hồi thường trong vài phút',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildMessages()),
        _buildComposer(),
      ],
    ),
  );

  Widget _buildMessages() {
    if (!FirebaseService.isInitialized) return _messageList(_localMessages);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.order.id)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        final messages =
            snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];
        return _messageList(messages.isEmpty ? _localMessages : messages);
      },
    );
  }

  Widget _messageList(List<Map<String, dynamic>> messages) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      final mine = message['sender'] == 'customer';
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 8),
            ],
          ),
          child: Text(
            '${message['text'] ?? ''}',
            style: TextStyle(
              color: mine ? Colors.white : AppColors.textPrimary,
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ),
      );
    },
  );

  Widget _buildComposer() => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                filled: true,
                fillColor: const Color(0xFFF3F5F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _send,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 19),
          ),
        ],
      ),
    ),
  );

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    if (!FirebaseService.isInitialized) {
      setState(() => _localMessages.add({'text': text, 'sender': 'customer'}));
      return;
    }
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.order.id)
        .collection('messages')
        .add({
          'text': text,
          'sender': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
