import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

const _conditions = ['New', 'Like New', 'Good', 'Fair', 'Used'];

class EditListingScreen extends StatefulWidget {
  const EditListingScreen({super.key, required this.product});

  final Product product;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _location;
  late String _category;
  late String _condition;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _title = TextEditingController(text: product.title);
    _description = TextEditingController(text: product.description);
    _price = TextEditingController(text: product.price.toStringAsFixed(0));
    _location = TextEditingController(text: product.location);
    _category = product.category;
    _condition = product.condition;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) return;

    setState(() => _saving = true);
    try {
      await ProductRepository().updateProduct(
        productId: widget.product.id,
        title: _title.text,
        description: _description.text,
        price: price,
        category: _category,
        condition: _condition,
        location: _location.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated.')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid listing.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CustomTextField(
              label: 'Title',
              hint: 'What are you selling?',
              controller: _title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title'
                  : null,
            ),
            CustomTextField(
              label: 'Description',
              hint: 'Describe the item',
              controller: _description,
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description'
                  : null,
            ),
            CustomTextField(
              label: 'Price',
              hint: 'Enter price',
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a valid price'
                    : null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: categories.any((item) => item.name == _category)
                  ? _category
                  : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              validator: (value) =>
                  value == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _conditions.contains(_condition) ? _condition : null,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: _conditions
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _condition = value);
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Location',
              hint: 'City / area',
              controller: _location,
            ),
            CustomButton(
              text: _saving ? 'Saving...' : 'Save Changes',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
