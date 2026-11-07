import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _answers = <String, String>{
    'How do I sell an item?':
        'Open Sell, add a title, description, price, category and condition, choose up to five photos, preview the listing, then publish it.',
    'How can I make an offer?':
        'Open an active listing and choose Make Offer. The seller can accept or reject your offer from Messages → Offers.',
    'How do I contact a seller?':
        'Open an active listing and choose Chat. Messages are only visible to the two conversation participants.',
    'How do cart orders work?':
        'Add active listings to your cart and submit an order request. The seller must confirm it. The app does not take online payment; coordinate payment and pickup or delivery directly.',
    'How do I edit or remove my listing?':
        'Open Profile → My Listings. You can edit, change the listing status, or delete listings you own.',
    'How do saved items work?':
        'Tap the heart on a listing to save it. Your saved items are private to your account and appear under Profile → Saved Items.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in _answers.entries)
            Card(
              child: ExpansionTile(
                title: Text(entry.key),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(entry.value),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A support contact and published legal policies have not been configured by the project owner. Add verified contact details and approved policy text before distributing the app.',
                      style: TextStyle(height: 1.4),
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
