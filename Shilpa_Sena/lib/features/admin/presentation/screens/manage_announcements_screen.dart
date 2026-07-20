import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/models/announcement_model.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';

class ManageAnnouncementsScreen extends StatelessWidget {
  const ManageAnnouncementsScreen({super.key});

  void _showAddAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddAnnouncementDialog(
        dbProvider: context.read<DatabaseProvider>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final announcements = dbProvider.announcements;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            title: const Text(
              'Manage In-App Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddAnnouncementDialog(context),
            backgroundColor: DesignConstants.primaryCyan,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
          body: CustomBackground(
            child: announcements.isEmpty
                ? const Center(
                    child: Text(
                      'No in-app messages broadcasted yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final item = announcements[index];
                      Color badgeColor;
                      IconData iconData;

                      switch (item.type) {
                        case 'alert':
                          badgeColor = DesignConstants.notificationRed;
                          iconData = Icons.warning_amber_rounded;
                          break;
                        case 'promo':
                          badgeColor = DesignConstants.accentYellow;
                          iconData = Icons.campaign_rounded;
                          break;
                        default:
                          badgeColor = DesignConstants.primaryCyan;
                          iconData = Icons.info_outline_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: DesignConstants.cardGradient,
                          borderRadius: BorderRadius.circular(16),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: badgeColor.withOpacity(0.1),
                            child: Icon(iconData, color: badgeColor),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  item.type.toUpperCase(),
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                item.body,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Broadcasted: ${_formatDate(item.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white30,
                                ),
                              ),
                            ],
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
                                    'Delete Message',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this message?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: DesignConstants.notificationRed),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await dbProvider.deleteAnnouncement(item.id);
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AddAnnouncementDialog extends StatefulWidget {
  final DatabaseProvider dbProvider;

  const _AddAnnouncementDialog({required this.dbProvider});

  @override
  State<_AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<_AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();
  String _selectedType = 'info';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final imgUrl = _imageUrlController.text.trim();
      final actUrl = _actionUrlController.text.trim();

      final newMsg = AnnouncementModel(
        id: '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _selectedType,
        timestamp: DateTime.now(),
        imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
        actionUrl: actUrl.isNotEmpty ? actUrl : null,
      );

      await widget.dbProvider.addAnnouncement(newMsg);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message broadcasted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignConstants.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      title: const Text(
        'Broadcast Message',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                icon: Icons.title,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bodyController,
                label: 'Body Content',
                icon: Icons.description,
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: DesignConstants.cardBackground,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Message Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.label, color: DesignConstants.primaryCyan, size: 20),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: DesignConstants.primaryCyan),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Information')),
                  DropdownMenuItem(value: 'alert', child: Text('System Alert')),
                  DropdownMenuItem(value: 'promo', child: Text('Promotion/Offer')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Optional Image URL',
                icon: Icons.image_outlined,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _actionUrlController,
                label: 'Optional Action/Launch URL',
                icon: Icons.link,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignConstants.primaryCyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text('Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: DesignConstants.primaryCyan, size: 20),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: DesignConstants.primaryCyan),
        ),
        errorStyle: const TextStyle(color: DesignConstants.notificationRed),
      ),
      validator: validator,
    );
  }
}
