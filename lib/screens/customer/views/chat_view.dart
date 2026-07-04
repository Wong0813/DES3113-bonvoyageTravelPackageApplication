import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../utils/app_theme.dart';

class ChatView extends StatelessWidget {
  final UserModel user;
  final List<AgentProfileModel> agents;
  final List<BookingModel> bookings;
  final List<TravelPackageModel> allPackages;
  final Function(AgentProfileModel, {int? bookingId, int? packageId}) onOpenChat;

  const ChatView({
    super.key,
    required this.user,
    required this.agents,
    required this.bookings,
    required this.allPackages,
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
        bookings.isEmpty
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
                itemCount: bookings.length,
                itemBuilder: (context, idx) {
                  final b = bookings[idx];
                  // Find travel package to show the package image (图片位置)
                  TravelPackageModel? pkg;
                  try {
                    pkg = allPackages.firstWhere((p) => p.id == b.packageId);
                  } catch (_) {}

                  // Find agent profile corresponding to booking agentId
                  final ag = agents.firstWhere(
                    (a) => a.userId == b.agentId,
                    orElse: () => AgentProfileModel(
                      id: b.agentId,
                      agentId: 'AGT0000',
                      userId: b.agentId,
                      companyName: b.companyName,
                      phone: '',
                      location: '',
                      rating: 0.0,
                      chatResponseRate: 100,
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppTheme.buildPackageImage(
                          pkg?.images ?? const [],
                          size: 48,
                          radius: 12,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.destination,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: b.status == 'completed'
                                  ? Colors.blue.withValues(alpha: 0.15)
                                  : b.status == 'confirmed'
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.status.toUpperCase(),
                              style: TextStyle(
                                color: b.status == 'completed'
                                    ? Colors.blueAccent
                                    : b.status == 'confirmed'
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agency: ${b.companyName}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Travel Date: ${b.travelDate.toIso8601String().split('T').first} • ${b.numPeople} Pax',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00D4FF)),
                      onTap: () {
                        onOpenChat(
                          ag,
                          bookingId: b.id,
                          packageId: b.packageId,
                        );
                      },
                    ),
                  );
                },
              )
      ],
    );
  }
}
