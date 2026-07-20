import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:exim_graphics_lms/core/services/stripe_service.dart';
import 'credit_card_input_formatter.dart';

class StripePaymentSheet extends StatefulWidget {
  final CourseModel course;
  final VoidCallback onSuccess;

  const StripePaymentSheet({
    super.key,
    required this.course,
    required this.onSuccess,
  });

  @override
  State<StripePaymentSheet> createState() => _StripePaymentSheetState();
}

class _StripePaymentSheetState extends State<StripePaymentSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderController = TextEditingController();

  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expiryFocus = FocusNode();
  final FocusNode _cvcFocus = FocusNode();
  final FocusNode _cardholderFocus = FocusNode();

  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';



  // Selected payment method
  String _selectedPaymentMethod = 'card'; // 'card', 'google_pay', 'apple_pay', 'paypal'

  late AnimationController _successController;
  late Animation<double> _checkScaleAnimation;

  @override
  void initState() {
    super.initState();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );



    // Rebuild on focus change to update input border/label colors
    _cardNumberFocus.addListener(() => setState(() {}));
    _expiryFocus.addListener(() => setState(() {}));
    _cvcFocus.addListener(() => setState(() {}));
    _cardholderFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardholderController.dispose();

    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvcFocus.dispose();
    _cardholderFocus.dispose();

    _successController.dispose();
    super.dispose();
  }



  Future<void> _pay() async {
    if (_selectedPaymentMethod == 'card') {
      if (!_formKey.currentState!.validate()) return;

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Extract Expiry Month & Year
      final expiryParts = _expiryController.text.split('/');
      if (expiryParts.length != 2) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid expiration date format.';
        });
        return;
      }

      final expMonth = expiryParts[0];
      final expYear = expiryParts[1];

      final auth = context.read<AuthProvider>();
      final db = context.read<DatabaseProvider>();

      final stripeResult = await StripeService.processPayment(
        cardNumber: _cardNumberController.text,
        expMonth: expMonth,
        expYear: expYear,
        cvc: _cvcController.text,
        amount: widget.course.price,
      );

      if (stripeResult.success) {
        try {
          await db.enrollUserImmediately(
            courseId: widget.course.id,
            courseTitle: widget.course.title,
            studentName: auth.user?.displayName ?? 'Anonymous student',
            studentEmail: auth.user?.email ?? 'No email',
            paymentIntentId: stripeResult.paymentIntentId ?? 'direct_stripe_bypass',
          );

          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          _successController.forward();

          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              Navigator.pop(context);
              widget.onSuccess();
            }
          });
        } catch (firestoreError) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Payment succeeded but enrollment failed: $firestoreError. Please contact support.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = stripeResult.errorMessage ?? 'Payment failed. Please check your credentials and try again.';
        });
      }
    } else {
      // Simulate non-card payment (Google Pay, Apple Pay, PayPal)
      final auth = context.read<AuthProvider>();
      final db = context.read<DatabaseProvider>();

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Show processing state to simulate real checkout experience
      await Future.delayed(const Duration(milliseconds: 1500));

      try {
        await db.enrollUserImmediately(
          courseId: widget.course.id,
          courseTitle: widget.course.title,
          studentName: auth.user?.displayName ?? 'Anonymous student',
          studentEmail: auth.user?.email ?? 'No email',
          paymentIntentId: '${_selectedPaymentMethod}_sim_${DateTime.now().millisecondsSinceEpoch}',
        );

        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        _successController.forward();

        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            Navigator.pop(context);
            widget.onSuccess();
          }
        });
      } catch (firestoreError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Simulation succeeded but enrollment failed: $firestoreError.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row 1: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Secure Checkout',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Header Row 2: Course Title & Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '\$${widget.course.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSuccess
                    ? _buildSuccessWidget()
                    : _isLoading
                        ? _buildLoadingWidget()
                        : Column(
                            key: const ValueKey('payment_content'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Payment Options Selector Row
                              _buildPaymentOptionsSelector(),
                              const SizedBox(height: 16),

                              if (_errorMessage.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: DesignConstants.notificationRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: DesignConstants.notificationRed.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: DesignConstants.notificationRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Card Specific Layout
                              if (_selectedPaymentMethod == 'card') ...[
                                // Stripe secure info tag
                                _buildSecureBadge(),
                                const SizedBox(height: 16),

                                // Card Details Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Cardholder Name
                                      _buildTextField(
                                        controller: _cardholderController,
                                        focusNode: _cardholderFocus,
                                        nextFocusNode: _cardNumberFocus,
                                        labelText: 'Cardholder Name',
                                        hintText: 'John Doe',
                                        icon: Icons.person_outline,
                                        textCapitalization: TextCapitalization.words,
                                        validator: (val) => (val == null || val.trim().isEmpty)
                                            ? 'Cardholder name is required'
                                            : null,
                                      ),
                                      const SizedBox(height: 10),

                                      // Card Number
                                      _buildTextField(
                                        controller: _cardNumberController,
                                        focusNode: _cardNumberFocus,
                                        nextFocusNode: _expiryFocus,
                                        labelText: 'Card Number',
                                        hintText: '0000 0000 0000 0000',
                                        icon: Icons.credit_card,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          CardNumberInputFormatter(),
                                        ],
                                        validator: (val) {
                                          if (val == null || val.replaceAll(' ', '').length < 16) {
                                            return 'Please enter a valid 16-digit card number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),

                                      // Expiry & CVC side-by-side
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _expiryController,
                                              focusNode: _expiryFocus,
                                              nextFocusNode: _cvcFocus,
                                              labelText: 'Expiration Date',
                                              hintText: 'MM/YY',
                                              icon: Icons.calendar_today_outlined,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                CardExpiryInputFormatter(),
                                              ],
                                              validator: (val) {
                                                if (val == null || val.length < 5) {
                                                  return 'Invalid expiry';
                                                }
                                                final mStr = val.substring(0, 2);
                                                final m = int.tryParse(mStr) ?? 0;
                                                if (m < 1 || m > 12) {
                                                  return 'Invalid month';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _cvcController,
                                              focusNode: _cvcFocus,
                                              labelText: 'CVC / CVV',
                                              hintText: '123',
                                              icon: Icons.lock_outline,
                                              keyboardType: TextInputType.number,
                                              obscureText: true,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                                LengthLimitingTextInputFormatter(3),
                                              ],
                                              validator: (val) => (val == null || val.length < 3)
                                                  ? 'Invalid CVC'
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Pay Button
                                ElevatedButton(
                                  onPressed: _pay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
                                  ),
                                  child: Text(
                                    'Pay \$${widget.course.price.toStringAsFixed(2)} Now',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Option-specific non-card payment UI
                                _buildOptionSpecificContent(),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Payment Option Selector Widget
  Widget _buildPaymentOptionsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOptionButton(
                id: 'card',
                label: 'Card',
                iconWidget: const Icon(Icons.credit_card_rounded, size: 16),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentOptionButton(
                id: 'google_pay',
                label: 'GPay',
                iconWidget: Image.asset(
                  'assets/images/google.png',
                  height: 16,
                  width: 16,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'G',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentOptionButton(
                id: 'apple_pay',
                label: 'Apple',
                iconWidget: const Icon(Icons.apple, size: 16, color: Colors.black),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentOptionButton(
                id: 'paypal',
                label: 'PayPal',
                iconWidget: Text(
                  'PP',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOptionButton({
    required String id,
    required String label,
    required Widget iconWidget,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
          _errorMessage = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSecureBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 12),
        const SizedBox(width: 4),
        const Text(
          'Stripe Secure 256-Bit SSL Encryption',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          const Text(
            'Processing Secure Payment...',
            style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Communicating with secure servers. Please do not close.',
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _checkScaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Your enrollment is now complete and active. Redirecting you...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSpecificContent() {
    switch (_selectedPaymentMethod) {
      case 'google_pay':
        return _buildGooglePayView();
      case 'apple_pay':
        return _buildApplePayView();
      case 'paypal':
        return _buildPayPalView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGooglePayView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_rounded, color: Colors.blue[600], size: 18),
              const SizedBox(width: 6),
              const Text(
                'Google Pay Active',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Use cards stored in your Google account to pay instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Google Pay Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pay with ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'G',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'o',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'o',
                    style: TextStyle(
                      color: Colors.yellow[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'g',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'l',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'e',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    ' Pay',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplePayView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apple_rounded, color: Colors.black, size: 20),
              SizedBox(width: 6),
              Text(
                'Apple Pay Enabled',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your purchase using Face ID or Touch ID.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Apple Pay Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _pay,
              icon: const Icon(Icons.apple, color: Colors.white, size: 20),
              label: const Text(
                'Pay with Apple Pay',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayPalView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_rounded, color: Colors.blue[800], size: 18),
              const SizedBox(width: 6),
              Text(
                'PayPal Checkout',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pay securely via balance, card, or pay later options.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // PayPal Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC439), // PayPal Gold
                foregroundColor: const Color(0xFF003087), // PayPal dark blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Pay with ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Pay',
                    style: TextStyle(
                      color: Color(0xFF003087),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Pal',
                    style: TextStyle(
                      color: Color(0xFF0079C1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        labelStyle: TextStyle(
          color: focusNode.hasFocus ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          fontSize: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignConstants.notificationRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignConstants.notificationRed, width: 1.5),
        ),
      ),
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          focusNode.unfocus();
        }
      },
    );
  }
}
