import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id'); // 1.000.000

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Ambil hanya digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Kosong? kembalikan kosong
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Hitung posisi kursor relatif dari kanan (supaya caret tidak “loncat” ke akhir)
    final selectionIndexFromRight = newValue.text.length - newValue.selection.end;

    // Format
    final value = int.parse(digitsOnly);
    final formatted = _formatter.format(value); // contoh: 1234567 -> 1.234.567

    // Posisi caret baru (sebisa mungkin pertahankan relatif dari kanan)
    final newSelectionIndex = formatted.length - selectionIndexFromRight;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionIndex.clamp(0, formatted.length)),
    );
  }
}
