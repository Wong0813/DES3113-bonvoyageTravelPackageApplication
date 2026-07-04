import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import '../../../services/promotion_service.dart';
import '../../../services/voucher_service.dart';

class CustomerPromotionsView extends StatefulWidget {
  final UserModel user;

  const CustomerPromotionsView({super.key, required this.user});

  @override
  State<CustomerPromotionsView> createState() => _CustomerPromotionsViewState();
}

class _CustomerPromotionsViewState extends State<CustomerPromotionsView> {
  bool _loading = true;
  List<VoucherModel> _vouchers = [];
  List<PromotionModel> _promotions = [];
  String? _copiedCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Fetch active vouchers and active promotions
      final vouchers = await VoucherService.instance.getAll();
      final promotions = await PromotionService.instance.getActive();
      setState(() {
        // Only show active vouchers that are not expired and within date range
        final now = DateTime.now();
        _vouchers = vouchers.where((v) {
          if (v.status != 'active') return false;
          if (v.validFrom != null && now.isBefore(v.validFrom!)) return false;
          if (v.validUntil != null && now.isAfter(v.validUntil!)) return false;
          if (v.maxUses > 0 && v.usedCount >= v.maxUses) return false;
          return true;
        }).toList();
        _promotions = promotions;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCode = code);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copiedCode = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promotions & Vouchers 🎉',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Copy a voucher code and use it when booking!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Text('🏷️', style: TextStyle(fontSize: 40)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Voucher Codes Section
        const Text(
          'Available Voucher Codes',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a code to copy it, then paste it at checkout',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
        const SizedBox(height: 14),

        if (_vouchers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Center(
              child: Text('No active vouchers available right now', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          )
        else
          ...List.generate(_vouchers.length, (i) {
            final v = _vouchers[i];
            final isCopied = _copiedCode == v.code;
            final discountText = v.discountType == 'percent'
                ? '${v.discountValue.toStringAsFixed(0)}% OFF'
                : 'RM ${v.discountValue.toStringAsFixed(2)} OFF';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCopied
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : const Color(0xFF00D4FF).withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        discountText,
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Voucher code - the key element
                          GestureDetector(
                            onTap: () => _copyCode(v.code),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCopied
                                    ? Colors.greenAccent.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCopied
                                      ? Colors.greenAccent.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    v.code,
                                    style: TextStyle(
                                      color: isCopied ? Colors.greenAccent : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    color: isCopied ? Colors.greenAccent : Colors.white38,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (v.minPurchase > 0)
                            Text(
                              'Min. purchase: RM ${v.minPurchase.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          if (v.validUntil != null)
                            Text(
                              'Valid until: ${v.validUntil!.toIso8601String().split('T').first}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    // Copy button
                    GestureDetector(
                      onTap: () => _copyCode(v.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCopied
                              ? Colors.greenAccent.withValues(alpha: 0.15)
                              : const Color(0xFF00D4FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCopied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            color: isCopied ? Colors.greenAccent : const Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 28),

        // Global Promotions Section
        if (_promotions.isNotEmpty) ...[
          const Text(
            'Current Promotions',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'These discounts are automatically applied to eligible packages',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...List.generate(_promotions.length, (i) {
            final p = _promotions[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.percent_rounded, color: Color(0xFF6C63FF), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(p.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        if (p.packageDestination != null) ...[
                          const SizedBox(height: 4),
                          Text('Applies to: ${p.packageDestination}', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                        if (p.validUntil != null) ...[
                          const SizedBox(height: 4),
                          Text('Valid until: ${p.validUntil!.toIso8601String().split('T').first}', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  if (p.discountPercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${p.discountPercent!.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4FF), size: 16),
            label: const Text('Refresh', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
