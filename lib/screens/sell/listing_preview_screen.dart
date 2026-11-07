import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class ListingPreviewScreen extends StatefulWidget {
  const ListingPreviewScreen({
    super.key,
    required this.title,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.location,
    this.images = const [],
  });

  final String title;
  final double price;
  final String category;
  final String condition;
  final String description;
  final String location;
  final List<XFile> images;

  @override
  State<ListingPreviewScreen> createState() => _ListingPreviewScreenState();
}

class _ListingPreviewScreenState extends State<ListingPreviewScreen> {
  bool _publishing = false;
  double _uploadProgress = 0;

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await ProductRepository().createProduct(
        title: widget.title,
        price: widget.price,
        category: widget.category,
        condition: widget.condition,
        description: widget.description,
        location: widget.location,
        images: widget.images,
        onUploadProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing published.')),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message?.toString() ?? 'Invalid listing.')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Listing Preview')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (widget.images.isEmpty)
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 70,
                  color: AppColors.primaryDark,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 210,
                      child: FutureBuilder<Uint8List>(
                        future: widget.images[index].readAsBytes(),
                        builder: (context, snapshot) => snapshot.hasData
                            ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              '₹${widget.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(widget.category)),
                Chip(label: Text(widget.condition)),
                if (widget.location.isNotEmpty)
                  Chip(label: Text(widget.location)),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 25),
            if (_publishing && widget.images.isNotEmpty) ...[
              Text(
                _uploadProgress >= 1 ? 'Saving listing...' : 'Uploading photos...',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 16),
            ],
            CustomButton(
              text: _publishing ? 'Publishing...' : 'Publish Listing',
              loading: _publishing,
              onPressed: _publishing ? null : _publish,
            ),
          ],
        ),
      );
}
