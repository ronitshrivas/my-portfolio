import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/ecommerce/model/check_out_summary_model.dart';
import 'package:innovator/ecommerce/provider/payment_provider.dart';
import 'package:innovator/ecommerce/provider/product_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

//Dotted divider

class DottedLine extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DottedLine({
    Key? key,
    required this.height,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(
        height: height,
        color: color,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DottedLinePainter({
    required this.height,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = height
          ..style = PaintingStyle.stroke;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//Khalti in-app WebView screen

class KhaltiWebViewScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final String orderId;

  const KhaltiWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
  }) : super(key: key);

  @override
  ConsumerState<KhaltiWebViewScreen> createState() =>
      _KhaltiWebViewScreenState();
}

class _KhaltiWebViewScreenState extends ConsumerState<KhaltiWebViewScreen> {
  static const _orange = Color.fromRGBO(244, 135, 6, 1);
  static const _khaltiPurple = Color(0xFF5C2D91);

  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => _isLoading = true),
              onPageFinished: (_) => setState(() => _isLoading = false),
              onNavigationRequest: (request) {
                final url = request.url;
                if (_isKhaltiCallback(url) && !_paymentHandled) {
                  _paymentHandled = true;
                  final success =
                      url.contains('success') ||
                      url.contains('completed') ||
                      url.contains('pidx');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _handlePaymentResult(success: success);
                  });
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isKhaltiCallback(String url) {
    return url.contains('payment/success') ||
        url.contains('payment/failure') ||
        url.contains('payment/cancel') ||
        url.contains('khalti/callback') ||
        (!url.contains('test-pay.khalti.com') &&
            !url.contains('pay.khalti.com') &&
            !url.startsWith('https://khalti.com'));
  }

  void _handlePaymentResult({required bool success}) {
    if (!mounted) return;
    _refreshAll();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (success ? Colors.green : Colors.red).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle : Icons.cancel,
                    size: 56,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  success ? 'Payment Successful!' : 'Payment Failed',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  success
                      ? 'Your order has been confirmed.\nOrder ID: ${widget.orderId}'
                      : 'Something went wrong. Please try again or choose Cash on Delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _refreshAll() {
    ref.refresh(productListProvider);
    ref.refresh(cartListProvider);
    ref.refresh(cartCountProvider);
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Cancel Payment?'),
            content: const Text(
              'Are you sure you want to leave? Your payment will not be completed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Leave',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _khaltiPurple,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Image.asset(
                'assets/icon/khalti_logo.png',
                height: 22,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 22,
                    ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pay with Khalti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  final exit = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Cancel Payment?'),
                          content: const Text(
                            'Are you sure you want to leave? Your payment will not be completed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Stay'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                'Leave',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (exit == true && context.mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(60)),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading)
              Container(
                color: Colors.white.withAlpha(220),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _khaltiPurple),
                      SizedBox(height: 14),
                      Text(
                        'Loading Khalti...',
                        style: TextStyle(color: _khaltiPurple),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//Checkout screen

class CheckoutScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final int itemCount;
  final List<dynamic> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.totalAmount,
    required this.itemCount,
    required this.cartItems,
  }) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPaymentType = 'cod';
  bool _isProcessing = false;

  static const _orange = Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = Colors.green;
  final Color _backgroundColor = Colors.grey.shade50;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.blueGrey.shade800;

  static const double _shippingCharge = 0.0;

  double get _grandTotal => widget.totalAmount + _shippingCharge;
  bool get _isCOD => _selectedPaymentType == 'cod';
  static const int _totalSteps = 2;

  String get _buttonText {
    if (_currentStep < _totalSteps - 1) return 'NEXT';
    return _isCOD ? 'PLACE ORDER' : 'PROCEED TO PAY';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) {
        _showSnackBar('Please fill all required fields', Colors.red);
        return;
      }
      _goToPage(1);
      return;
    }
    await _placeOrder();
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    _goToPage(_currentStep - 1);
  }

  void _goToPage(int page) {
    setState(() => _currentStep = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(paymentServiceProvider);
      final response = await service.checkout(
        fullName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        paymentType: _selectedPaymentType,
      );
      setState(() => _isProcessing = false);

      if (_isCOD) {
        _showOrderSuccessDialog(response);
      } else if (response.requiresKhaltiPayment == true) {
        await _initiateKhaltiPayment(response.orderId);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _initiateKhaltiPayment(String orderId) async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(paymentServiceProvider);
      final khaltiResponse = await service.initiateKhaltiPayment(
        orderId: orderId,
      );
      setState(() => _isProcessing = false);
      if (!mounted) return;

      // Push in-app WebView — no external browser
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => KhaltiWebViewScreen(
                paymentUrl: khaltiResponse.paymentUrl,
                orderId: orderId,
              ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _refreshAll() {
    ref.refresh(productListProvider);
    ref.refresh(cartListProvider);
    ref.refresh(cartCountProvider);
  }

  void _showOrderSuccessDialog(CheckoutSummaryResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _accentColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(response.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Order ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        response.orderId,
                        style: const TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Grand Total: NPR ${response.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _refreshAll();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        // foregroundColor: Colors.white,
        // title: const Text(
        //   'Checkout',
        //   style: TextStyle(fontWeight: FontWeight.bold),
        // ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildOrderSummary(),
            const SizedBox(height: 16),
            _buildStepper(),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [_buildCustomerInfoTab(), _buildPaymentMethodTab()],
              ),
            ),
            const SizedBox(height: 10),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    const labels = ['Customer Info', 'Payment Method'];
    return Row(
      children:
          labels.asMap().entries.map((e) {
            final i = e.key;
            final label = e.value;
            final active = i == _currentStep;
            final done = i < _currentStep;
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              active
                                  ? _orange
                                  : (done
                                      ? _accentColor
                                      : Colors.grey.shade300),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          done
                              ? Icons.check
                              : (i == 0 ? Icons.person : Icons.payment),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.w500,
                          color: active ? _orange : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: done ? _accentColor : Colors.grey.shade300,
                        margin: const EdgeInsets.only(
                          bottom: 22,
                          left: 4,
                          right: 4,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      children: [
        _buildSummaryRow('Total Items', '${widget.itemCount}'),
        _buildSummaryRow(
          'Sub-Total',
          'NPR ${widget.totalAmount.toStringAsFixed(2)}',
        ),
        _buildSummaryRow(
          'Shipping',
          _shippingCharge == 0
              ? 'FREE'
              : 'NPR ${_shippingCharge.toStringAsFixed(2)}',
        ),
        const SizedBox(
          width: double.infinity,
          height: 10,
          child: DottedLine(
            height: 2,
            color: Colors.grey,
            dashWidth: 6,
            dashSpace: 10,
          ),
        ),
        _buildSummaryRow(
          'Grand Total',
          'NPR ${_grandTotal.toStringAsFixed(2)}',
          isTotal: true,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Payment Method',
          _isCOD ? 'Cash on Delivery' : 'Khalti',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isTotal ? _textColor : Colors.grey.shade600,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? _orange : _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _orange,
                    side: const BorderSide(color: _orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          _buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  'Full Name',
                  _nameController,
                  'Full Name *',
                  Icons.person,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Phone Number',
                  _phoneController,
                  'Phone Number *',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.length < 10 ? 'Invalid phone' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Delivery Address',
                  _addressController,
                  'Delivery Address *',
                  Icons.location_on,
                  maxLines: 3,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Notes (Optional)',
                  _notesController,
                  'Order Notes (Optional)',
                  Icons.note,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _orange),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // COD
          _PaymentOptionCard(
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            icon: Icons.local_shipping_outlined,
            iconColor: _orange,
            isSelected: _isCOD,
            onTap: () => setState(() => _selectedPaymentType = 'cod'),
          ),

          const SizedBox(height: 12),

          // Khalti — logo card
          _KhaltiPaymentCard(
            isSelected: !_isCOD,
            onTap: () => setState(() => _selectedPaymentType = 'khalti'),
          ),

          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isCOD ? _buildCodInfo() : _buildKhaltiInfo(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCodInfo() {
    return Container(
      key: const ValueKey('cod'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No advance payment needed. Pay in cash when the order arrives at your doorstep.',
              style: TextStyle(fontSize: 13, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhaltiInfo() {
    return Container(
      key: const ValueKey('khalti'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF5C2D91).withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5C2D91).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF5C2D91), size: 16),
              SizedBox(width: 8),
              Text(
                'How Khalti payment works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C2D91),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1. Tap "Proceed to Pay"\n'
            '2. Khalti opens inside the app\n'
            '3. Complete payment of NPR ${_grandTotal.toStringAsFixed(2)}\n'
            '4. Your order is confirmed automatically',
            style: const TextStyle(
              fontSize: 13,
              height: 1.7,
              color: Color(0xFF5C2D91),
            ),
          ),
        ],
      ),
    );
  }
}

//COD payment option card

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withAlpha(8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isSelected ? 15 : 8),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? iconColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            RadioDot(isSelected: isSelected, color: iconColor),
          ],
        ),
      ),
    );
  }
}

//Khalti card — logo image + "Pay with"

class _KhaltiPaymentCard extends StatelessWidget {
  static const _khaltiPurple = Color(0xFF5C2D91);
  final bool isSelected;
  final VoidCallback onTap;

  const _KhaltiPaymentCard({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _khaltiPurple.withAlpha(8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _khaltiPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isSelected ? 15 : 8),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Small Khalti logo in rounded container
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _khaltiPurple.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icon/khalti_logo.png',
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _khaltiPurple,
                      size: 22,
                    ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Pay with [logo]" row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Pay with ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? _khaltiPurple : Colors.black87,
                        ),
                      ),
                      // Inline small logo
                      Image.asset(
                        'assets/icon/khalti_logo.png',
                        height: 16,
                        errorBuilder:
                            (_, __, ___) => const Text(
                              'Khalti',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _khaltiPurple,
                              ),
                            ),
                      ),
                      const SizedBox(width: 6),
                      // FAST badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _khaltiPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FAST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Secure digital wallet payment',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            RadioDot(isSelected: isSelected, color: _khaltiPurple),
          ],
        ),
      ),
    );
  }
}

//Reusable animated radio dot

class RadioDot extends StatelessWidget {
  final bool isSelected;
  final Color color;

  const RadioDot({required this.isSelected, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? color : Colors.transparent,
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child:
          isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
    );
  }
}
