import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/chat_service.dart';

class ChatView extends StatefulWidget {
  final UserModel user;
  final List<AgentProfileModel> agents;
  final List<BookingModel> bookings;
  final List<TravelPackageModel> allPackages;
  final Function(AgentProfileModel, {int? bookingId, int? packageId, String? autoSendMessage}) onOpenChat;

  const ChatView({
    super.key,
    required this.user,
    required this.agents,
    required this.bookings,
    required this.allPackages,
    required this.onOpenChat,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final c = await ChatService.instance.getContactsForUser(widget.user.id);
      if (mounted) {
        setState(() {
          _contacts = c;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Gather all unique agent user IDs the user is allowed to chat with
    final allowedAgentUserIds = <int>{};
    
    // Add agents where user has active bookings
    allowedAgentUserIds.addAll(widget.bookings.map((b) => b.agentId));
    
    // Add agents from existing chat conversations
    for (final c in _contacts) {
      if (c['userId'] != null) {
        allowedAgentUserIds.add(c['userId'] as int);
      }
    }

    // 2. Filter agent profiles
    final filteredAgents = widget.agents
        .where((a) => allowedAgentUserIds.contains(a.userId))
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF16162A),
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chat with Travel Agents', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4FF)),
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF00D4FF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All package questions and bookings with the same travel company are unified into one single chat thread here.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
                )
              : filteredAgents.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white.withValues(alpha: 0.2), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No active chats found',
                            style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Go to any travel package detail sheet and click "Chat" to ask questions directly to their agency support team.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAgents.length,
                      itemBuilder: (context, idx) {
                        final ag = filteredAgents[idx];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                              child: Text(
                                ag.companyName.isNotEmpty ? ag.companyName[0].toUpperCase() : 'A',
                                style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            title: Text(
                              ag.companyName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                ag.location.isNotEmpty ? ag.location : 'Travel Agency Support',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                            ),
                            trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00D4FF)),
                            onTap: () {
                              widget.onOpenChat(ag);
                            },
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
