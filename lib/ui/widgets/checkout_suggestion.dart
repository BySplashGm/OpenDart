import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/checkout_helper.dart';

class CheckoutSuggestion extends StatelessWidget {
  final int remaining;

  const CheckoutSuggestion({super.key, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final suggestion = CheckoutHelper.getSuggestion(remaining);
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_score_rounded,
              size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            suggestion.join(' → '),
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
