import 'package:flutter/material.dart';

class AdminPinDialog extends StatefulWidget {
  const AdminPinDialog({super.key});

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin PIN'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Enter admin PIN',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Unlock')),
      ],
    );
  }

  void _submit() {
    if (_controller.text.trim() == '1234') {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _error = 'Incorrect PIN';
    });
  }
}
