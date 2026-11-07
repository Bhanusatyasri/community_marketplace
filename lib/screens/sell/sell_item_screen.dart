import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'listing_preview_screen.dart';

class SellItemScreen extends StatefulWidget {
  const SellItemScreen({super.key});

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final form = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final selectedImages = <XFile>[];
  final title = TextEditingController();
  final price = TextEditingController();
  final desc = TextEditingController();
  final location = TextEditingController();
  String? category;
  String condition = 'Good';
  bool selectingImages = false;

  Future<void> pickImages() async {
    if (selectingImages || selectedImages.length == 5) return;

    setState(() => selectingImages = true);
    try {
      final images = await imagePicker.pickMultiImage(
        limit: 5 - selectedImages.length,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      final accepted = <XFile>[];
      for (final image in images) {
        final bytes = await image.length();
        final extension = image.name.split('.').last.toLowerCase();
        if (bytes > 600 * 1024) {
          showMessage('Each photo must be no larger than 600 KB.');
          continue;
        }
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
          showMessage('Choose JPEG, PNG, or WebP images.');
          continue;
        }
        accepted.add(image);
      }
      if (mounted && accepted.isNotEmpty) {
        setState(() {
          selectedImages.addAll(accepted.take(5 - selectedImages.length));
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        showMessage(error.message ?? 'Could not open the photo picker.');
      }
    } finally {
      if (mounted) setState(() => selectingImages = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    title.dispose();
    price.dispose();
    desc.dispose();
    location.dispose();
    super.dispose();
  }

  void next() {
    if (!form.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingPreviewScreen(
          title: title.text.trim(),
          price: double.parse(price.text.trim()),
          category: category!,
          condition: condition,
          description: desc.text.trim(),
          location: location.text.trim(),
          images: List<XFile>.unmodifiable(selectedImages),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sell an Item',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add Photos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (selectedImages.length < 5)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: selectingImages ? null : pickImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: selectingImages
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.primaryDark,
                                  ),
                          ),
                        ),
                      ),
                    ...selectedImages.asMap().entries.map(
                          (entry) => _SelectedImage(
                            image: entry.value,
                            onRemove: () => setState(
                                () => selectedImages.removeAt(entry.key)),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              CustomTextField(
                label: 'Title',
                hint: 'What are you selling?',
                controller: title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter product title'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => category = value),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Price',
                hint: 'Enter price',
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ['New', 'Like New', 'Good', 'Fair', 'Used']
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => condition = value);
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Description',
                hint: 'Describe your item',
                controller: desc,
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please describe your item'
                    : null,
              ),
              CustomTextField(
                label: 'Location',
                hint: 'City / area',
                controller: location,
              ),
              const SizedBox(height: 8),
              CustomButton(text: 'Next', onPressed: next),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedImage extends StatelessWidget {
  const _SelectedImage({required this.image, required this.onRemove});

  final XFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List>(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            },
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .9),
                foregroundColor: AppColors.danger,
              ),
              tooltip: 'Remove image',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
