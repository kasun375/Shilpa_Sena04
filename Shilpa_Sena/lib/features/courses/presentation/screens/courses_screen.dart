import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import 'package:exim_graphics_lms/features/courses/presentation/widgets/stripe_payment_sheet.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'All Courses',
        showDrawerButton: true,
      ),
      drawer: const AppDrawer(),
      body: CustomBackground(
        child: Consumer<DatabaseProvider>(
          builder: (context, dbProvider, child) {
            final courses = dbProvider.courses;

            return courses.isEmpty
                ? const Center(
                    child: Text(
                      'No courses available yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return FutureBuilder<String>(
                        future: dbProvider.getEnrollmentStatusForCourse(
                          course.id,
                        ),
                        builder: (context, snapshot) {
                          final status = snapshot.data ?? 'available';
                          return _buildCourseCard(
                            context,
                            course,
                            status,
                            dbProvider,
                          );
                        },
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    CourseModel course,
    String status,
    DatabaseProvider db,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'purchased':
        statusColor = Colors.green;
        statusText = 'Purchased';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_top;
        break;
      case 'expired':
        statusColor = DesignConstants.notificationRed;
        statusText = 'Expired';
        statusIcon = Icons.timer_off;
        break;
      default:
        statusColor = DesignConstants.primaryCyan;
        statusText = 'Available';
        statusIcon = Icons.shopping_cart;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        gradient: DesignConstants.cardGradient,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Next Class: ${course.date} at ${course.time}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sell_outlined, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Monthly Price: ${course.formattedMonthlyPrice}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white12, thickness: 1),
            const SizedBox(height: 16),
            _buildActionArea(context, course, status, db),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    CourseModel course,
    String status,
    DatabaseProvider db,
  ) {
    if (status == 'purchased') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(course.zoomLink);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Join Zoom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignConstants.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/studypacks'),
              icon: const Icon(Icons.library_books),
              label: const Text('Materials'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'pending') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Your payment is being verified by admin. Please check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      );
    } else if (status == 'expired') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: DesignConstants.notificationRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DesignConstants.notificationRed.withOpacity(0.3)),
            ),
            child: const Text(
              'Your monthly subscription has expired. Renew to access classes & materials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignConstants.notificationRed, fontSize: 12),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: StripePaymentSheet(
                      course: course,
                      onSuccess: () {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.autorenew, color: Colors.black),
              label: Text('Pay Fees (${course.formattedMonthlyPrice})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignConstants.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: StripePaymentSheet(
                  course: course,
                  onSuccess: () {
                    // Enrollment is handled inside the sheet
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.payment, color: Colors.black),
          label: Text('Pay Fees (${course.formattedMonthlyPrice})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignConstants.primaryCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  }
}
