import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({super.key});

  void _showAddCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _AddCourseDialog(dbProvider: context.read<DatabaseProvider>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final courses = dbProvider.courses;

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
              'Manage Courses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCourseDialog(context),
            backgroundColor: DesignConstants.primaryCyan,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
          body: CustomBackground(
            child: courses.isEmpty
                ? const Center(
                    child: Text(
                      'No courses added yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          title: Text(
                            course.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${course.date} at ${course.time}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sell_outlined,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Price: \$${course.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                    'Delete Course',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${course.title}"?',
                                    style: const TextStyle(color: Colors.white70),
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
                                        style: TextStyle(
                                          color: DesignConstants.notificationRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await dbProvider.deleteCourse(course.id);
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

class _AddCourseDialog extends StatefulWidget {
  final DatabaseProvider dbProvider;

  const _AddCourseDialog({required this.dbProvider});

  @override
  State<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<_AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _zoomLinkController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _zoomLinkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final priceVal = double.tryParse(_priceController.text.trim()) ?? 10.0;
      final newCourse = CourseModel(
        id: '',
        title: _titleController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        zoomLink: _zoomLinkController.text.trim(),
        price: priceVal,
        createdAt: DateTime.now(),
      );

      await widget.dbProvider.addCourse(newCourse);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add course: ${e.toString()}'),
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
        'Add New Course',
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
                label: 'Course Title',
                icon: Icons.title,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _dateController,
                label: 'Next Class Date (e.g. Monday)',
                icon: Icons.calendar_today,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _timeController,
                label: 'Class Time (e.g. 7:00 PM)',
                icon: Icons.schedule,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _zoomLinkController,
                label: 'Zoom Link',
                icon: Icons.videocam,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _priceController,
                label: 'Price (USD)',
                icon: Icons.sell,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a valid number';
                  return null;
                },
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
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
