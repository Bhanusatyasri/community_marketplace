import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../theme/app_colors.dart';
import 'product_image.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool canRespond;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool updating;

  const OfferCard({
    super.key,
    required this.offer,
    this.canRespond = false,
    this.onAccept,
    this.onReject,
    this.updating = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (offer.status) {
      'Rejected' => AppColors.danger,
      'Accepted' => AppColors.primaryDark,
      _ => AppColors.textSecondary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ProductImage(source: offer.productImage),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.productTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Listed: ₹${offer.listedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Offer: ₹${offer.offeredPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  offer.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (offer.message.isNotEmpty)
              Text(offer.message, style: const TextStyle(fontSize: 12)),
            if (canRespond && offer.status == 'Pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: updating ? null : onReject,
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: updating ? null : onAccept,
                    child: updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
