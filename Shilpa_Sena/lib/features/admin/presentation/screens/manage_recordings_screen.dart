import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../courses/presentation/providers/database_provider.dart';
import '../../../../models/recording_model.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class ManageRecordingsScreen extends StatefulWidget {
  const ManageRecordingsScreen({super.key});

  @override
  State<ManageRecordingsScreen> createState() => _ManageRecordingsScreenState();
}

class _ManageRecordingsScreenState extends State<ManageRecordingsScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _showAddRecordingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignConstants.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Add New Recording',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  icon: Icons.title,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descController,
                  label: 'Description',
                  icon: Icons.description,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _linkController,
                  label: 'Video Link (URL)',
                  icon: Icons.link,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final recording = RecordingModel(
                    id: '',
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    videoUrl: _linkController.text.trim(),
                    uploadedAt: DateTime.now(),
                  );
                  await context.read<DatabaseProvider>().addRecording(
                    recording,
                  );

                  // Pop loading
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recording added successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _titleController.clear();
                    _descController.clear();
                    _linkController.clear();
                  }
                } catch (e) {
                  // Pop loading
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add recording: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
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
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Manage Recordings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomBackground(
        child: Consumer<DatabaseProvider>(
          builder: (context, db, child) {
            final recordings = db.recordings;
            if (recordings.isEmpty) {
              return const Center(
                child: Text(
                  'No recordings found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    title: Text(
                      recording.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Text(
                      recording.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: DesignConstants.notificationRed,
                      ),
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
                              'Delete Recording',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this recording?',
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
                          await db.deleteRecording(recording.id);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordingDialog,
        backgroundColor: DesignConstants.primaryCyan,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
