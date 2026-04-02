// lib/shared_widgets/responsive_form_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'responsive_wrapper.dart';

class ResponsiveTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final bool isPassword;
  final bool? obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final String? semanticLabel;

  const ResponsiveTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.isPassword = false,
    this.obscureText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.semanticLabel,
  });

  @override
  State<ResponsiveTextFormField> createState() =>
      _ResponsiveTextFormFieldState();
}

class _ResponsiveTextFormFieldState extends State<ResponsiveTextFormField> {
  bool _obscureText = false;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText ?? widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    Widget? suffixIcon = widget.suffixIcon;

    // Add password visibility toggle if it's a password field
    if (widget.isPassword && widget.suffixIcon == null) {
      suffixIcon = Semantics(
        button: true,
        label: _obscureText ? 'Show password' : 'Hide password',
        child: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _isFocused
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    final fontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final borderRadius = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);
    final contentPadding = EdgeInsets.all(
      isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
    );

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: colorScheme.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: colorScheme.outline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          filled: true,
          fillColor: _isFocused
              ? colorScheme.primaryContainer.withAlpha(25)
              : colorScheme.surface,
          contentPadding: contentPadding,
          counterText: '', // Hide character counter
          labelStyle: TextStyle(fontSize: fontSize),
          hintStyle: TextStyle(fontSize: fontSize),
          helperStyle: TextStyle(fontSize: fontSize - 2),
        ),
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        textCapitalization: widget.textCapitalization,
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final Widget? icon;
  final bool isLoading;
  final String? semanticLabel;
  final double? width;
  final double? height;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.elevated,
    this.icon,
    this.isLoading = false,
    this.semanticLabel,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    final fontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final borderRadius = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);
    final padding = EdgeInsets.symmetric(
      vertical: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
      horizontal: isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0),
    );

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: type == ButtonType.elevated
                  ? Colors.white
                  : theme.primaryColor,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Widget button;
    switch (type) {
      case ButtonType.elevated:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        );
        break;
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: SizedBox(width: width, height: height, child: button),
    );
  }
}

enum ButtonType { elevated, outlined, text }
