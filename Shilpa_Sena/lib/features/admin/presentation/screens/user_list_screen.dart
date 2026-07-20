import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

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
        title: const Text('Manage Students (User Directory)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DesignConstants.notificationRed),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: DesignConstants.primaryCyan),
              );
            }

            final users = snapshot.data?.docs ?? [];

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  'No students registered yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final name = userData['name'] ?? 'No Name';
                final email = userData['email'] ?? 'No Email';
                final role = userData['role'] ?? 'student';
                final isAdmin = role == 'admin' || email.toLowerCase() == 'admin@eximgraphics.com';

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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: (isAdmin ? DesignConstants.notificationRed : DesignConstants.primaryCyan).withOpacity(0.1),
                      child: Icon(
                        Icons.person_outline,
                        color: isAdmin ? DesignConstants.notificationRed : DesignConstants.primaryCyan,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Text(
                      email,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isAdmin ? DesignConstants.notificationRed : DesignConstants.primaryCyan).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isAdmin ? DesignConstants.notificationRed : DesignConstants.primaryCyan).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        (isAdmin ? 'ADMIN' : 'STUDENT'),
                        style: TextStyle(
                          color: isAdmin ? DesignConstants.notificationRed : DesignConstants.primaryCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
