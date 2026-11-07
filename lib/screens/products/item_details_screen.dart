import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/offer_repository.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/seller_card.dart';
import '../../widgets/product_image.dart';
import '../messages/chat_screen.dart';
import '../cart/cart_screen.dart';
import 'seller_profile_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Product product;

  const ItemDetailsScreen({super.key, required this.product});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _products = ProductRepository();
  final _cart = CartRepository();
  bool _updatingFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  Future<void> _recordView() async {
    try {
      await _products.recordView(widget.product.id);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Listing view could not be recorded: ${AuthRepository.messageFor(error)}')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _toggleFavorite() async {
    if (_updatingFavorite) return;
    final previous = widget.product.favorite;
    final selected = !previous;
    setState(() {
      _updatingFavorite = true;
      widget.product.favorite = selected;
    });
    try {
      await _products.setFavorite(
        productId: widget.product.id,
        selected: selected,
      );
    } on FirebaseException catch (error) {
      widget.product.favorite = previous;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthRepository.messageFor(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingFavorite = false);
    }
  }

  Future<void> _addToCart() async {
    try {
      await _cart.add(widget.product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to your cart.'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _copyListingDetails() async {
    final product = widget.product;
    try {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${product.title}\n₹${product.price.toStringAsFixed(0)}\n${product.description}',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing details copied to clipboard.')),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not copy listing details: ${error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Add to cart',
            onPressed: _addToCart,
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
          IconButton(
            onPressed: _copyListingDetails,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy listing details',
          ),
          IconButton(
            onPressed: _updatingFavorite ? null : _toggleFavorite,
            icon: Icon(
              product.favorite ? Icons.favorite : Icons.favorite_border,
              color: product.favorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(product: product),
                  const SizedBox(height: 18),
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          product.condition,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerProfileScreen(
                          user: product.seller,
                        ),
                      ),
                    ),
                    child: SellerCard(user: product.seller),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Posted ${product.createdAt}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.views}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seller rating',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  RatingWidget(
                    rating: product.seller.rating,
                    reviews: product.seller.reviewCount,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(product: product),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _OfferSheet(product: product),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Make Offer'),
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
}

class _ProductImage extends StatefulWidget {
  final Product product;

  const _ProductImage({required this.product});

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty
        ? <String?>[null]
        : product.images.cast<String?>();

    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final image = ProductImage(
                source: images[index],
                iconSize: 80,
              );
              return index == 0
                  ? Hero(
                      tag: 'product-image-${product.id}',
                      child: image,
                    )
                  : image;
            },
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final selected = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: selected ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferSheet extends StatefulWidget {
  final Product product;

  const _OfferSheet({required this.product});

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final offer = TextEditingController();
  final message = TextEditingController();
  final _offers = OfferRepository();
  bool _submitting = false;

  @override
  void dispose() {
    offer.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final amount = double.tryParse(offer.text.trim());
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > widget.product.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter an offer greater than zero and no more than ₹${widget.product.price.toStringAsFixed(0)}.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _offers.createOffer(
        product: widget.product,
        amount: amount,
        message: message.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Your offer was sent to the seller.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make an Offer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Listed price: ₹${widget.product.price.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: offer,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Your Offer'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: message,
            maxLines: 2,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Offer'),
            ),
          ),
        ],
      ),
    );
  }
}
