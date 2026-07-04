import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/chat_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/travel_package_service.dart';
import '../../../services/review_service.dart';
import '../../../utils/app_theme.dart';
import '../widgets/package_detail_sheet.dart';

class ChatPage extends StatefulWidget {
  final UserModel user;
  final int agentUserId;
  final String agentName;
  final int? bookingId;
  final int? packageId;
  final List<BookingModel> bookings;
  final List<int> wishlistIds;

  const ChatPage({
    super.key,
    required this.user,
    required this.agentUserId,
    required this.agentName,
    this.bookingId,
    this.packageId,
    required this.bookings,
    required this.wishlistIds,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  List<ChatMessageModel> _messages = [];
  Timer? _timer;

  BookingModel? _activeBooking;
  TravelPackageModel? _activePackage;
  bool _loadingContext = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadBookingContext();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService.instance.getConversation(
        widget.user.id,
        widget.agentUserId,
        bookingId: widget.bookingId,
      );
      if (mounted) {
        setState(() {
          _messages = msgs;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadBookingContext() async {
    setState(() => _loadingContext = true);
    BookingModel? foundBooking;

    // 1. Try resolving using widget.bookingId
    if (widget.bookingId != null) {
      try {
        foundBooking = await BookingService.instance.getBookingById(widget.bookingId!);
      } catch (_) {}
    }

    // 2. Try fallback to latest active booking with this agent
    if (foundBooking == null) {
      final list = widget.bookings.where((b) => b.agentId == widget.agentUserId).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      if (list.isNotEmpty) {
        foundBooking = list.first;
      }
    }

    // 3. Load associated travel package
    if (foundBooking != null) {
      try {
        final pkg = await TravelPackageService.instance.getPackageById(foundBooking.packageId);
        if (mounted) {
          setState(() {
            _activeBooking = foundBooking;
            _activePackage = pkg;
            _loadingContext = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingContext = false);
      }
    } else if (widget.packageId != null) {
      try {
        final pkg = await TravelPackageService.instance.getPackageById(widget.packageId!);
        if (mounted) {
          setState(() {
            _activePackage = pkg;
            _loadingContext = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingContext = false);
      }
    } else {
      if (mounted) setState(() => _loadingContext = false);
    }
  }

  Future<void> _viewPackageDetails() async {
    if (_activePackage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
    );

    try {
      final reviews = await ReviewService.instance.getReviews(packageId: _activePackage!.id);
      final avg = await ReviewService.instance.getAverageRating(_activePackage!.id);
      if (mounted) Navigator.pop(context); // pop loading

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PackageDetailSheet(
            currentUser: widget.user,
            pkg: _activePackage!,
            fromBooking: widget.bookings.any((b) => b.packageId == _activePackage!.id),
            reviews: reviews,
            avgRating: avg,
            wishlistIds: widget.wishlistIds,
            bookings: widget.bookings,
            onBack: () => Navigator.pop(context),
            onWishlistChanged: (_) {},
            onBookPackage: (_) {},
            onPayBooking: (b) => _payBooking(b),
            onAddReview: (_) {},
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  Future<void> _payBooking(BookingModel b) async {
    bool isProcessing = false;
    bool isSuccess = false;
    String statusText = "Connecting to secure gateway...";
    String selectedPaymentMethod = 'credit_card';

    final cardNumController = TextEditingController(text: "4111 2222 3333 4321");
    final nameController = TextEditingController(text: widget.user.fullName.isEmpty ? widget.user.username : widget.user.fullName);
    final expiryController = TextEditingController(text: "12/28");
    final cvvController = TextEditingController(text: "123");

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isSuccess) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0A0A1F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 60),
                    const SizedBox(height: 16),
                    const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('TXN-${DateTime.now().millisecondsSinceEpoch}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 16),
                    Text('Amount Paid: RM ${b.totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _loadBookingContext();
                        },
                        child: const Text('Back to Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (isProcessing) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F0F24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Color(0xFF00D4FF)),
                    const SizedBox(height: 24),
                    Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }

            final List<Map<String, dynamic>> paymentMethods = [
              {'key': 'credit_card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF6C63FF)},
              {'key': 'fpx', 'label': 'FPX Online Banking', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF00D4FF)},
              {'key': 'grabpay', 'label': 'GrabPay', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF00B14F)},
              {'key': 'tng', 'label': "Touch 'n Go eWallet", 'icon': Icons.contactless_rounded, 'color': const Color(0xFF0099FF)},
            ];

            return AlertDialog(
              backgroundColor: const Color(0xFF0F0F24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Secure Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking ID: #${b.id} | ${b.destination}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      const Text('Payment Method', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ...paymentMethods.map((pm) {
                        final isSelected = selectedPaymentMethod == pm['key'];
                        final pmColor = pm['color'] as Color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedPaymentMethod = pm['key'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? pmColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? pmColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(pm['icon'] as IconData, color: isSelected ? pmColor : Colors.white54, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  pm['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: pmColor, size: 18),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      if (selectedPaymentMethod == 'credit_card') ...[
                        Container(
                          width: double.infinity,
                          height: 160,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B83FF), Color(0xFF6C63FF), Color(0xFF3F37C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('💵 Credit Card', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('VISA', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              const Text('🪙', style: TextStyle(fontSize: 22)),
                              Text(
                                cardNumController.text.isNotEmpty ? cardNumController.text : '**** **** **** ****',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(nameController.text.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                  Text(expiryController.text.isNotEmpty ? expiryController.text : 'MM/YY', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cardNumController,
                          style: const TextStyle(color: Colors.white),
                          decoration: AppTheme.input('Card Number', icon: Icons.credit_card),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: AppTheme.input('Cardholder Name', icon: Icons.person_outline),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: expiryController,
                                style: const TextStyle(color: Colors.white),
                                decoration: AppTheme.input('Expiry Date'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: cvvController,
                                style: const TextStyle(color: Colors.white),
                                obscureText: true,
                                decoration: AppTheme.input('CVV'),
                                validator: (v) => v == null || v.length != 3 ? 'Invalid' : null,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                selectedPaymentMethod == 'fpx' ? Icons.account_balance_rounded
                                    : selectedPaymentMethod == 'grabpay' ? Icons.phone_android_rounded
                                    : Icons.contactless_rounded,
                                color: selectedPaymentMethod == 'fpx' ? const Color(0xFF00D4FF)
                                    : selectedPaymentMethod == 'grabpay' ? const Color(0xFF00B14F)
                                    : const Color(0xFF0099FF),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                selectedPaymentMethod == 'fpx' ? 'FPX Online Banking'
                                    : selectedPaymentMethod == 'grabpay' ? 'GrabPay'
                                    : "Touch 'n Go eWallet",
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedPaymentMethod == 'fpx'
                                    ? 'You will be redirected to your bank\'s secure online banking portal to complete payment.'
                                    : selectedPaymentMethod == 'grabpay'
                                    ? 'You will be redirected to the Grab app to authorise payment from your GrabPay wallet.'
                                    : 'You will be redirected to Touch \'n Go eWallet to complete payment securely.',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 14),
                                    SizedBox(width: 6),
                                    Text('256-bit SSL Encrypted', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              'RM ${b.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            if (selectedPaymentMethod == 'credit_card' && !formKey.currentState!.validate()) return;
                            setState(() {
                              isProcessing = true;
                              statusText = selectedPaymentMethod == 'credit_card'
                                  ? 'Connecting to secure gateway...'
                                  : selectedPaymentMethod == 'fpx'
                                  ? 'Connecting to bank portal...'
                                  : selectedPaymentMethod == 'grabpay'
                                  ? 'Launching GrabPay...'
                                  : 'Launching Touch\'n Go...';
                            });

                            await Future.delayed(const Duration(milliseconds: 600));
                            setState(() => statusText = 'Authorizing transaction...');

                            await Future.delayed(const Duration(milliseconds: 600));
                            setState(() => statusText = 'Processing payment...');

                            await Future.delayed(const Duration(milliseconds: 600));

                            try {
                              await BookingService.instance.confirmPayment(
                                b.id,
                                widget.user.id,
                                paymentMethod: selectedPaymentMethod,
                              );
                              setState(() {
                                isProcessing = false;
                                isSuccess = true;
                              });
                            } catch (e) {
                              setState(() {
                                isProcessing = false;
                              });
                              showAppSnackBar(context, '$e', isError: true);
                            }
                          },
                          child: Text(
                            'Pay RM ${b.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    try {
      await ChatService.instance.sendMessage(
        senderId: widget.user.id,
        receiverId: widget.agentUserId,
        message: _msgCtrl.text.trim(),
        bookingId: widget.bookingId,
      );
      _msgCtrl.clear();
      _loadMessages();
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text(widget.agentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Contextual Booking / Package Banner
          if (!_loadingContext && (_activeBooking != null || _activePackage != null)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF161630),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  // Package thumbnail
                  AppTheme.buildPackageImage(
                    _activePackage?.images ?? const [],
                    size: 42,
                    radius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activePackage?.destination ?? _activeBooking?.destination ?? 'Trip Context',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (_activeBooking != null)
                          Text(
                            'Booking ID: #${_activeBooking!.id} • ${_activeBooking!.numPeople} Traveler${_activeBooking!.numPeople > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          )
                        else if (_activePackage != null)
                          Text(
                            'Package Price: RM ${_activePackage!.pricePerPerson.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Link actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_activeBooking != null && _activeBooking!.paymentStatus == 'pending') ...[
                        ElevatedButton(
                          onPressed: () => _payBooking(_activeBooking!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4FF),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Pay Now', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _viewPackageDetails,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Row(
                              children: [
                                Text('View Trip', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold)),
                                SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF00D4FF), size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_activeBooking != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _activeBooking!.status == 'completed'
                                ? Colors.blue.withValues(alpha: 0.15)
                                : _activeBooking!.status == 'confirmed'
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _activeBooking!.status.toUpperCase(),
                            style: TextStyle(
                              color: _activeBooking!.status == 'completed'
                                  ? Colors.blueAccent
                                  : _activeBooking!.status == 'confirmed'
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isMe = m.senderId == widget.user.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00D4FF) : const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.message, style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 13.5)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E38),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF00D4FF)), onPressed: _send),
              ],
            ),
          )
        ],
      ),
    );
  }
}
