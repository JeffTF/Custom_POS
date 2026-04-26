import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/image_service.dart';

class ProductEditorDialog extends StatefulWidget {
  const ProductEditorDialog({
    super.key,
    this.product,
    required this.categories,
    required this.imageService,
  });

  final Product? product;
  final List<Category> categories;
  final ImageService imageService;

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _thresholdController;
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '0',
    );
    _skuController = TextEditingController(text: product?.sku ?? '');
    _thresholdController = TextEditingController(
      text: product?.lowStockThreshold.toString() ?? '5',
    );
    _selectedCategoryId =
        product?.categoryId ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
    _imagePath = product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock quantity',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: widget.categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Low stock threshold',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _imagePath == null
                            ? 'No product image selected'
                            : _imagePath!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _pickGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      tooltip: 'Pick from gallery',
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _pickCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      tooltip: 'Capture photo',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _pickGallery() async {
    final path = await widget.imageService.pickAndSaveFromGallery();
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      _imagePath = path;
    });
  }

  Future<void> _pickCamera() async {
    final path = await widget.imageService.pickAndSaveFromCamera();
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      _imagePath = path;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stockQuantity: int.parse(_stockController.text.trim()),
        categoryId: _selectedCategoryId,
        imagePath: _imagePath,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        lowStockThreshold: int.parse(_thresholdController.text.trim()),
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt,
      ),
    );
  }
}
