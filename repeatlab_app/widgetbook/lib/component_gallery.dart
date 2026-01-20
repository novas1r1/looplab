import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:web/web.dart' as web;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A zoomable canvas showing all components at a glance.
/// Use pinch-to-zoom or scroll wheel to zoom, and drag to pan around.
@UseCase(name: 'Overview', type: ComponentGallery)
Widget componentGalleryUseCase(BuildContext context) {
  return const ComponentGallery();
}

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.1,
          maxScale: 4.0,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Buttons'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _ComponentCard(
                        name: 'PrimaryButton',
                        variant: 'Active',
                        widgetbookPath: 'core/ui/interaction/primarybutton/active',
                        child: PrimaryButton(onPressed: () {}, text: 'Click me'),
                      ),
                      _ComponentCard(
                        name: 'PrimaryButton',
                        variant: 'Disabled',
                        widgetbookPath: 'core/ui/interaction/primarybutton/disabled',
                        child: const PrimaryButton(onPressed: null, text: 'Disabled'),
                      ),
                      _ComponentCard(
                        name: 'PrimaryButton',
                        variant: 'Long Text',
                        width: 120,
                        child: PrimaryButton(onPressed: () {}, text: 'Very Long Button Text Here'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Sliders'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _ComponentCard(
                        name: 'CustomSlider',
                        variant: 'Default (50%)',
                        width: 250,
                        child: CustomSlider(
                          value: 0.5,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          onChanged: (_) {},
                        ),
                      ),
                      _ComponentCard(
                        name: 'CustomSlider',
                        variant: 'Min Value',
                        width: 250,
                        child: CustomSlider(
                          value: 0,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          onChanged: (_) {},
                        ),
                      ),
                      _ComponentCard(
                        name: 'CustomSlider',
                        variant: 'Max Value',
                        width: 250,
                        child: CustomSlider(
                          value: 1,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('More Components'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Add more components here as you build them!\n'
                      'Simply add new _ComponentCard widgets to display them.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Zoom controls overlay
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add,
                onPressed: () {
                  final currentScale = _transformationController.value.getMaxScaleOnAxis();
                  final newScale = (currentScale * 1.2).clamp(0.1, 4.0);
                  _transformationController.value = Matrix4.identity()..scale(newScale);
                },
              ),
              const SizedBox(height: 8),
              _ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final currentScale = _transformationController.value.getMaxScaleOnAxis();
                  final newScale = (currentScale / 1.2).clamp(0.1, 4.0);
                  _transformationController.value = Matrix4.identity()..scale(newScale);
                },
              ),
              const SizedBox(height: 8),
              _ZoomButton(icon: Icons.fit_screen, onPressed: _resetZoom),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  final String name;
  final String variant;
  final Widget child;
  final double? width;

  /// The Widgetbook path to navigate to when tapped.
  /// Format: 'folder/subfolder/ComponentName-UseCaseName'
  /// Example: 'core/ui/interaction/PrimaryButton-Active'
  final String? widgetbookPath;

  const _ComponentCard({
    required this.name,
    required this.variant,
    required this.child,
    this.width,
    this.widgetbookPath,
  });

  void _navigateToWidgetbook() {
    if (widgetbookPath == null) return;

    final currentUrl = web.window.location.href;
    // Extract base URL (everything before #)
    final baseUrl = currentUrl.split('#').first;
    final newUrl = '$baseUrl#/?path=$widgetbookPath';
    web.window.location.href = newUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isClickable = widgetbookPath != null;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isClickable ? _navigateToWidgetbook : null,
        child: Container(
          width: width ?? 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isClickable ? Colors.blue.shade200 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with component info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isClickable ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            variant,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    if (isClickable) Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade400),
                  ],
                ),
              ),
              // Component preview
              Container(
                padding: const EdgeInsets.all(16),
                child: Center(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
