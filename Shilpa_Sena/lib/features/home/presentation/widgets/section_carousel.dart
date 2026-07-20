import 'package:flutter/material.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class SectionCarousel<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback? onSeeAll;

  const SectionCarousel({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignConstants.horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'See All',
                    style: TextStyle(color: DesignConstants.primaryCyan),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110, // Reduced height for the "half height" cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.horizontalPadding - 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index]);
            },
          ),
        ),
      ],
    );
  }
}
