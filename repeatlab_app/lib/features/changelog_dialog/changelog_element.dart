import 'package:flutter/material.dart';

class ChangelogElement extends StatelessWidget {
  final String title;
  final String description;
  final List<String>? imagePaths;
  // final VoidCallback? onTapImage;

  const ChangelogElement({
    super.key,
    required this.title,
    required this.description,
    this.imagePaths,
    // this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: onTapImage != null ? () => onTapImage!() : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            if (imagePaths != null && imagePaths!.isNotEmpty)
              for (final imagePath in imagePaths!)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Theme.of(context).colorScheme.primary,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      width: MediaQuery.sizeOf(context).width / 2,
                      semanticLabel: 'Image Background',
                    ),
                  ),
                )
            else
              const SizedBox.shrink(),
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              thickness: 1,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
