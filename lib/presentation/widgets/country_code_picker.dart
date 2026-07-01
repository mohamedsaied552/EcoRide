import 'package:flutter/material.dart';

import 'package:zakzouka/presentation/utils/phone_utils.dart';

class CountryCodePicker extends StatelessWidget {
  const CountryCodePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CountryDialCode selected;
  final ValueChanged<CountryDialCode> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Code',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1FAE6C), width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              selected.dialCode,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF667085)),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<CountryDialCode>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CountryDialCode.supported
                .map(
                  (country) => ListTile(
                    leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(country.name),
                    trailing: Text(country.dialCode),
                    onTap: () => Navigator.pop(context, country),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}
