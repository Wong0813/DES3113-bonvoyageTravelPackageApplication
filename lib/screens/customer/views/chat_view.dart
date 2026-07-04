import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ChatView extends StatelessWidget {
  final UserModel user;
  final List<AgentProfileModel> agents;
  final Function(AgentProfileModel) onOpenChat;

  const ChatView({
    super.key,
    required this.user,
    required this.agents,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chat with Travel Agents', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  'Chat is available with companies you have an active booking with. You can also start a chat from the travel package details page.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        agents.isEmpty
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
                      'No active bookings found',
                      style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Book a travel package to unlock chat support with the travel agency.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agents.length,
                itemBuilder: (context, idx) {
                  final ag = agents[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00D4FF),
                        child: Text(ag.companyName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(ag.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(ag.location, style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00D4FF)),
                      onTap: () => onOpenChat(ag),
                    ),
                  );
                },
              )
      ],
    );
  }
}
