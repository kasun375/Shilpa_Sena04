import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class ManagePromosScreen extends StatefulWidget {
  const ManagePromosScreen({super.key});

  @override
  State<ManagePromosScreen> createState() => _ManagePromosScreenState();
}

class _ManagePromosScreenState extends State<ManagePromosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(BuildContext dialogContext) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      try {
        final bytes = await image.readAsBytes();
        await context.read<DatabaseProvider>().uploadPromoImage(
          bytes,
        );
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAddPromoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final dbProvider = context.watch<DatabaseProvider>();

            return AlertDialog(
              backgroundColor: DesignConstants.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: const Text(
                'Add Promo Banner',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dbProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(DesignConstants.primaryCyan),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Uploading banner...',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: () => _pickAndUploadImage(dialogContext),
                      icon: const Icon(Icons.image),
                      label: const Text('Upload PNG Image', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignConstants.primaryCyan,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Paste Image URL',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'https://example.com/image.png',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.link, color: DesignConstants.primaryCyan, size: 20),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DesignConstants.primaryCyan),
                          ),
                          errorStyle: const TextStyle(color: DesignConstants.notificationRed),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Please enter a valid URL' : null,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dbProvider.isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                if (!dbProvider.isLoading)
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await dbProvider.addPromoUrl(
                            _urlController.text.trim(),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URL added successfully'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _urlController.clear();
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add URL: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignConstants.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add URL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final promos = dbProvider.promoImageUrls;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            elevation: 0,
            title: const Text('Manage Carousel Banners', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddPromoDialog,
            backgroundColor: DesignConstants.primaryCyan,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
          body: CustomBackground(
            child: promos.isEmpty
                ? const Center(
                    child: Text(
                      'No banners added yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: promos.length,
                    itemBuilder: (context, index) {
                      final promoUrl = promos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          gradient: DesignConstants.cardGradient,
                          borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              promoUrl,
                              width: 80,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.white30),
                            ),
                          ),
                          title: Text(
                            promoUrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: DesignConstants.notificationRed),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: DesignConstants.cardBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  title: const Text(
                                    'Delete Banner',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this promo banner?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: DesignConstants.notificationRed)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                var snapshot = await dbProvider.firestore
                                    .collection('promos')
                                    .where('url', isEqualTo: promoUrl)
                                    .get();
                                for (var doc in snapshot.docs) {
                                  await dbProvider.deletePromoUrl(doc.id);
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
