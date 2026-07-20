import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import '../../../home/presentation/widgets/section_list.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Courses',
        showDrawerButton: true,
      ),
      drawer: const AppDrawer(),
      body: CustomBackground(
        child: Consumer<DatabaseProvider>(
          builder: (context, dbProvider, _) {
            final myCourses = dbProvider.myCourses;
            
            if (myCourses.isEmpty) {
              return _buildEmptyState();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                   SectionList<CourseModel>(
                    title: 'Current Enrollments',
                    items: myCourses,
                    itemBuilder: (context, course) => _buildCourseCard(context, course),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: DesignConstants.cardGradient,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/courses'),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignConstants.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_outline, color: DesignConstants.primaryCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Class: ${course.date}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, color: Colors.white10, size: 80),
          SizedBox(height: 16),
          Text(
            'No courses enrolled yet',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
