import 'package:flutter/material.dart';

import '../../models/category.dart';

class CategoryEditorDialog extends StatefulWidget {
  const CategoryEditorDialog({super.key, this.category});

  final Category? category;

  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
  static const _palette = <String>[
    '#0F766E',
    '#C2410C',
    '#1D4ED8',
    '#B45309',
    '#475569',
    '#BE185D',
    '#7C3AED',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _sortController;
  late String _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _sortController = TextEditingController(
      text: widget.category?.sortOrder.toString() ?? '0',
    );
    _selectedColor = widget.category?.color ?? _palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortController,
                decoration: const InputDecoration(labelText: 'Sort order'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((color) {
                  final selected = _selectedColor == color;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Category(name: '', color: color).chipColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
        createdAt: widget.category?.createdAt,
      ),
    );
  }
}
