import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/offer.dart';
import '../../repositories/offer_repository.dart';
import '../../widgets/offer_card.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _repository = OfferRepository();
  final Set<String> _updating = {};

  Future<void> _updateStatus(OfferModel offer, String status) async {
    if (_updating.contains(offer.id)) return;
    setState(() => _updating.add(offer.id));
    try {
      await _repository.updateOfferStatus(offerId: offer.id, status: status);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer could not be updated: $error')),
      );
    } finally {
      if (mounted) setState(() => _updating.remove(offer.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to view your offers.'));
    }

    return StreamBuilder<List<OfferModel>>(
      stream: _repository.watchOffers(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load offers. Check your connection and Firestore permissions.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snapshot.data ?? const [];
        if (offers.isEmpty) {
          return const Center(
            child: Text('You do not have any offers yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: offers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return OfferCard(
              offer: offer,
              canRespond: offer.sellerId == uid,
              updating: _updating.contains(offer.id),
              onAccept: () => _updateStatus(offer, 'Accepted'),
              onReject: () => _updateStatus(offer, 'Rejected'),
            );
          },
        );
      },
    );
  }
}
