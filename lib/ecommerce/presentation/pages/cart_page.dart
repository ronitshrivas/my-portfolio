import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:innovator/theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'package:innovator/core/payment/khalti_webview_page.dart';
import 'package:innovator/ecommerce/data/models/shop_models.dart';
import 'package:innovator/ecommerce/data/sources/ecommerce_api.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/services/auth_session.dart';
import 'package:innovator/widgets/liquid_button.dart';
import 'package:innovator/widgets/liquid_pressable.dart';
import 'package:innovator/widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _khalti = Color(0xFF5C2D91);

/// Cart section rendered inside the dashboard shell (nav bar stays).
///
/// A frosted table lists every item — S.N, name with artwork, liquid
/// +/- quantity controls, unit price and line total — followed by a
/// summary with 13% VAT and the flat Rs 200 all-Nepal delivery charge,
/// and a Khalti checkout that floods with purple liquid.
class CartSection extends StatefulWidget {
  const CartSection({
    super.key,
    required this.onShop,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Back to the shop (continue shopping / empty state).
  final VoidCallback onShop;

  /// Vertical clearances from the shell (kept clear of the docked bar).
  final EdgeInsets contentPadding;

  @override
  State<CartSection> createState() => _CartSectionState();
}

class _CartSectionState extends State<CartSection>
    with TickerProviderStateMixin {
  final _api = EcommerceApi();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Continuous phase shared by every liquid surface in the cart.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .12).clamp(0.0, .6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  bool _paying = false;

  Future<void> _checkout() async {
    if (_paying) return;
    HapticFeedback.mediumImpact();
    setState(() => _paying = true);

    bool paid = false;
    try {
      final session = AuthSession.instance;

      // The backend checkout reads the SERVER cart, but the app keeps a local
      // cart — push it up first so the order isn't "empty".
      final localItems = <String, int>{};
      for (final item in Cart.instance.items) {
        final id = item.product.id.trim();
        if (id.isEmpty) continue;
        localItems[id] = (localItems[id] ?? 0) + item.quantity;
      }
      if (localItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your cart is empty.')),
          );
        }
        return;
      }
      await _api.syncCart(localItems);
      if (!mounted) return;

      // Create the order (Khalti), then open Khalti's hosted page directly —
      // same one-tap flow as e-learning; no intermediate sheet.
      final order = await _api.checkout(
        fullName: session.username ?? 'Innovator',
        address: 'N/A',
        phoneNumber: '9800000000',
        paymentType: 'khalti',
      );
      final init = await _api.initiateKhalti(order.orderId);
      if (!mounted) return;

      if (!init.needsWebView) {
        paid = true; // zero-total / already settled
      } else {
        final result = await KhaltiWebViewPage.open(
          context,
          paymentUrl: init.paymentUrl,
        );
        // TODO: verify with POST /api/payments/verify {init.pidx} when available.
        paid = result == KhaltiResult.success;
        if (!paid && mounted && result != KhaltiResult.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment did not complete')),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start payment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }

    if (paid && mounted) {
      Cart.instance.clear();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
          content: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [_khalti, Color(0xFF3E1D63)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
                boxShadow: [
                  BoxShadow(
                    color: _khalti.withValues(alpha: .35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF6EE7B7),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Payment successful — order confirmed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return ListenableBuilder(
      listenable: Cart.instance,
      builder: (context, _) {
        final cart = Cart.instance;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            padding.top + 6,
            20,
            padding.bottom + 6,
          ),
          children: [
            _stagger(index: 0, child: _FloatingTitle('Your cart', wave: _wave)),
            const SizedBox(height: 16),
            if (cart.isEmpty)
              _stagger(
                index: 1,
                child: _EmptyCart(wave: _wave, onShop: widget.onShop),
              )
            else ...[
              _stagger(
                index: 1,
                child: _CartTable(cart: cart, wave: _wave),
              ),
              const SizedBox(height: 16),
              _stagger(index: 2, child: _SummaryCard(cart: cart)),
              const SizedBox(height: 18),
              _stagger(
                index: 3,
                child: _KhaltiCheckoutButton(
                  amount: cart.grandTotal,
                  wave: _wave,
                  onTap: _checkout,
                ),
              ),
              const SizedBox(height: 12),
              _stagger(
                index: 3,
                child: Center(
                  child: LiquidPressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onShop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    rippleColor: _ink,
                    intensity: .5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 15,
                            color: _ink.withValues(alpha: .65),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Continue shopping',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ink.withValues(alpha: .65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ title

class _FloatingTitle extends StatelessWidget {
  const _FloatingTitle(this.title, {required this.wave});

  final String title;
  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wave,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(wave.value * 2 * pi) * 2.6),
        child: child,
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -.2,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ empty state

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.wave, required this.onShop});

  final AnimationController wave;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .60),
                Colors.white.withValues(alpha: .32),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .85)),
          ),
          child: Column(
            children: [
              // A glass droplet with liquid resting inside it.
              AnimatedBuilder(
                animation: wave,
                builder: (context, _) => Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: .12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: WaveFillPainter(
                            phase: wave.value * 2 * pi,
                            fill: .3,
                            color: _ink.withValues(alpha: .12),
                            amplitude: 3,
                            frequency: 1.5,
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 30,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add something you love from the shop.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: LiquidButton(
                  label: 'Browse products',
                  leading: const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  onTap: onShop,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ table

class _CartTable extends StatelessWidget {
  const _CartTable({required this.cart, required this.wave});

  final Cart cart;
  final AnimationController wave;

  static const _headerStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: _muted,
    letterSpacing: .3,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .62),
                Colors.white.withValues(alpha: .32),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .85)),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(28), // S.N
                1: FlexColumnWidth(), // item
                2: FixedColumnWidth(78), // qty
                3: FixedColumnWidth(48), // price
                4: FixedColumnWidth(52), // total
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: _ink.withValues(alpha: .06),
                ),
              ),
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('S.N', style: _headerStyle),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Item', style: _headerStyle),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: _headerStyle,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Price',
                        textAlign: TextAlign.right,
                        style: _headerStyle,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: _headerStyle,
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < cart.items.length; i++)
                  _row(context, i, cart.items[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _row(BuildContext context, int index, CartItem item) {
    final product = item.product;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  product.imageAsset,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34,
                    height: 34,
                    color: product.tint.withValues(alpha: .15),
                    child: Icon(product.icon, size: 17, color: product.tint),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QtyButton(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                Cart.instance.decrement(item);
              },
            ),
            SizedBox(
              width: 22,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '${item.quantity}',
                    key: ValueKey(item.quantity),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ),
            _QtyButton(
              icon: Icons.add_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                Cart.instance.increment(item);
              },
            ),
          ],
        ),
        Text(
          groupNum(product.price),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        Text(
          groupNum(item.total),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    );
  }
}

/// Tiny liquid +/- control: squashes like a droplet on every press.
class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      rippleColor: Colors.white,
      intensity: 1.2,
      child: Container(
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrandColors.secondarySurface.withValues(alpha: .95),
              BrandColors.secondarySurface.withValues(alpha: .9),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------- summary

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .62),
                Colors.white.withValues(alpha: .32),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .85)),
          ),
          child: Column(
            children: [
              _line('Subtotal', formatRs(cart.subtotal)),
              const SizedBox(height: 10),
              _line('VAT (13%)', formatRs(cart.vat)),
              const SizedBox(height: 10),
              _line(
                'Delivery (Nepal)',
                formatRs(cart.delivery),
                note: 'Flat rate · everywhere in Nepal',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Container(height: 1, color: _ink.withValues(alpha: .08)),
              ),
              Row(
                children: [
                  const Text(
                    'Grand total',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  // Pops like a droplet every time the amount changes.
                  TweenAnimationBuilder<double>(
                    key: ValueKey(cart.grandTotal),
                    tween: Tween(begin: .7, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.elasticOut,
                    builder: (context, t, child) =>
                        Transform.scale(scale: t, child: child),
                    child: Text(
                      formatRs(cart.grandTotal),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {String? note}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 10,
                    color: _muted.withValues(alpha: .8),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- checkout

/// Checkout button flooded with Khalti-purple liquid, waves always moving.
class _KhaltiCheckoutButton extends StatelessWidget {
  const _KhaltiCheckoutButton({
    required this.amount,
    required this.wave,
    required this.onTap,
  });

  final double amount;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      rippleColor: Colors.white,
      child: AnimatedBuilder(
        animation: wave,
        builder: (context, _) {
          final phase = wave.value * 2 * pi;
          return Container(
            height: 57,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: Colors.white.withValues(alpha: .4),
              border: Border.all(
                color: Colors.white.withValues(alpha: .9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _khalti.withValues(alpha: .35),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: phase + 2.1,
                      fill: 1.0,
                      color: _khalti.withValues(alpha: .45),
                      amplitude: 5,
                      frequency: 1.3,
                    ),
                  ),
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: phase,
                      fill: .94,
                      color: _khalti.withValues(alpha: .95),
                      amplitude: 4,
                      frequency: 1.5,
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Checkout with Khalti',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: .18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .35),
                            ),
                          ),
                          child: Text(
                            formatRs(amount),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

