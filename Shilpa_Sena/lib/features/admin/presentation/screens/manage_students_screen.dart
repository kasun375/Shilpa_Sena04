import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'Enrollment Requests',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          bottom: const TabBar(
            indicatorColor: DesignConstants.primaryCyan,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.white60,
            labelColor: DesignConstants.primaryCyan,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending_actions_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('PENDING'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('HISTORY'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: CustomBackground(
          child: TabBarView(
            children: [
              _buildEnrollmentList('pending'),
              _buildEnrollmentList(['purchased', 'rejected']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentList(dynamic statusQuery) {
    Query query = FirebaseFirestore.instance.collectionGroup('enrollments');

    if (statusQuery is String) {
      query = query.where('status', isEqualTo: statusQuery);
    } else if (statusQuery is List) {
      query = query.where('status', whereIn: statusQuery);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignConstants.primaryCyan),
          );
        }

        final enrollments = snapshot.data?.docs ?? [];

        if (enrollments.isEmpty) {
          return _buildEmptyState(statusQuery == 'pending');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final doc = enrollments[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildStudentCard(context, doc.reference, data);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) {
    final studentName = data['studentName'] ?? 'Unknown Student';
    final studentEmail = data['studentEmail'] ?? 'No Email';
    final courseTitle = data['courseTitle'] ?? 'Unknown Course';
    final status = data['status'] ?? 'pending';
    final requestedAt = data['requestedAt'] as Timestamp?;
    final dateStr = requestedAt != null
        ? "${requestedAt.toDate().day}/${requestedAt.toDate().month}/${requestedAt.toDate().year}"
        : 'Recently';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: DesignConstants.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        studentEmail,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Details Padding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: DesignConstants.primaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        courseTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Requested: $dateStr',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'pending')
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.close,
                            color: DesignConstants.notificationRed,
                            onTap: () =>
                                _updateEnrollmentStatus(docRef, 'rejected'),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.check,
                            color: Colors.greenAccent,
                            onTap: () =>
                                _updateEnrollmentStatus(docRef, 'purchased'),
                            isPrimary: true,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending
                  ? Icons.auto_awesome_outlined
                  : Icons.history_edu_outlined,
              size: 80,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPending ? 'No Pending Requests' : 'No Access History',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isPending
                  ? 'Great job! All student requests have been handled.'
                  : 'You haven\'t approved or rejected any students yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    final bool isPermissionError =
        error.contains('permission-denied') ||
        error.contains('Missing or insufficient permissions');
    final bool isIndexError =
        error.contains('requires an index') ||
        error.contains('failed-precondition');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignConstants.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPermissionError
                    ? Icons.shield_outlined
                    : (isIndexError
                          ? Icons.table_chart_outlined
                          : Icons.error_outline),
                color: DesignConstants.primaryCyan,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPermissionError
                  ? 'Security Access Required'
                  : (isIndexError
                        ? 'Action Required: Create Index'
                        : 'Database Connection Error'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isPermissionError
                    ? 'Your account does not have admin permissions to view these enrollment requests.'
                    : (isIndexError
                          ? 'Firestore requires a "Collection Group Index" for this query. Follow the link in the details below.'
                          : 'Something went wrong while connecting to the database. Please see the detailed error below.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesignConstants.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        color: DesignConstants.primaryCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPermissionError
                            ? 'REQUIRED SECURITY RULE:'
                            : 'ERROR DETAILS (COPY & READ CAREFULLY):',
                        style: const TextStyle(
                          color: DesignConstants.primaryCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    isPermissionError
                        ? 'match /{path=**}/enrollments/{id} {\n  allow read, write: if request.auth.token.email == "admin@eximgraphics.com";\n}'
                        : error,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ManageStudentsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignConstants.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'RETRY CONNECTION',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'purchased':
        return Colors.greenAccent;
      case 'rejected':
        return DesignConstants.notificationRed;
      default:
        return DesignConstants.accentYellow;
    }
  }

  Future<void> _updateEnrollmentStatus(
    DocumentReference docRef,
    String status,
  ) async {
    try {
      await docRef.update({'status': status});
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }
}
