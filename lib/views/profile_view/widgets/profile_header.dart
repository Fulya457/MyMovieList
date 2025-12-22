import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onEditAvatar;

  const ProfileHeader({super.key, required this.onEditAvatar});

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'User';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@')).toUpperCase();
    }
    return 'USER';
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final userName = _getMemberName();

    return Center(
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: MovieManager.instance.getCurrentUserIconIndex(),
            builder: (context, snapshot) {
              final iconIndex = snapshot.data ?? 0;
              final iconUrl = MovieManager.instance.profileIcons[iconIndex];

              return GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                      backgroundImage: NetworkImage(iconUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userEmail,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
