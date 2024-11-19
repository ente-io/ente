import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:photos/theme/ente_theme.dart";

class DatePickerField extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final void Function(DateTime?)? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired; // New parameter for optional/required state

  const DatePickerField({
    super.key,
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.isRequired = true, // Default to required for backward compatibility
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDate;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _tryParseDate(widget.initialValue!);
    }
  }

  void _tryParseDate(String value) {
    // If the field is empty and not required, reset error state and clear date
    if (value.isEmpty && !widget.isRequired) {
      setState(() {
        _selectedDate = null;
        _hasError = false;
      });
      widget.onChanged?.call(null);
      return;
    }

    // Skip validation for empty optional fields
    if (value.isEmpty) {
      return;
    }

    try {
      // Try parsing different date formats
      DateTime? parsed;
      final List<String> formats = ['MM/dd/yyyy', 'MM-dd-yyyy', 'yyyy-MM-dd'];

      for (String format in formats) {
        try {
          parsed = DateFormat(format).parseStrict(value);
          break;
        } catch (_) {
          continue;
        }
      }

      if (parsed != null) {
        // Validate date range if specified
        bool isValid = true;
        if (widget.firstDate != null && parsed.isBefore(widget.firstDate!)) {
          isValid = false;
        }
        if (widget.lastDate != null && parsed.isAfter(widget.lastDate!)) {
          isValid = false;
        }

        setState(() {
          _selectedDate = isValid ? parsed : null;
          _hasError = !isValid;
        });

        if (isValid) {
          widget.onChanged?.call(parsed);
        }
      } else {
        setState(() {
          _selectedDate = null;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _selectedDate = null;
        _hasError = true;
      });
    }
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasError = false;
        _controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: (value) => _tryParseDate(value),
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          borderSide: BorderSide(
            color: getEnteColorScheme(context).strokeMuted,
          ),
        ),
        fillColor: getEnteColorScheme(context).fillFaint,
        filled: true,
        hintText: widget.hintText ??
            "Enter date (DD/MM/YYYY)${widget.isRequired ? '' : ' (optional)'}",
        hintStyle: getEnteTextTheme(context).bodyFaint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        error: _hasError
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Use format (MM-dd-YYYY or MM/dd/YYYY)',
                  style: getEnteTextTheme(context).miniMuted,
                ),
              )
            : null,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _showDatePicker,
          color: _hasError
              ? getEnteColorScheme(context).warning500
              : getEnteColorScheme(context).strokeMuted,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
