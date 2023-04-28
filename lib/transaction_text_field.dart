import 'package:flutter/material.dart';

class TransactionTextField extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final TextInputAction action;
  final bool enabled;

  const TransactionTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.action,
    required this.enabled,
  });

  @override
  State<TransactionTextField> createState() => _TransactionTextFieldState();
}

class _TransactionTextFieldState extends State<TransactionTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        final controller = widget.controller;
        if (controller != null) {
          controller.selection = TextSelection(
              baseOffset: 0, extentOffset: controller.text.length);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return TextField(
      controller: controller,
      onTap: () {
        if (controller != null) {
          controller.selection = TextSelection(
              baseOffset: 0, extentOffset: controller.text.length);
        }
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.all(10.0)),
      autocorrect: false,
      textInputAction: widget.action,
      enabled: widget.enabled,
      focusNode: _focusNode,
    );
  }
}
