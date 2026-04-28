import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'input_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Helper'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
            icon: const Icon(CupertinoIcons.star_fill, size: 20, color: Colors.amber),
            label: const Text(
              'Premium',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.wifi_slash, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            _buildWelcomeCard(context),
            const SizedBox(height: 24),
            const Text(
              'What would you like to do?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Scan',
                  CupertinoIcons.camera_fill,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.scan))),
                ),
                _buildActionCard(
                  context,
                  'Upload',
                  CupertinoIcons.photo_fill,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.upload))),
                ),
                _buildActionCard(
                  context,
                  'Enter Text',
                  CupertinoIcons.pencil_ellipsis_rectangle,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.text))),
                ),
                _buildActionCard(
                  context,
                  'Voice Input',
                  CupertinoIcons.mic_fill,
                  Colors.red,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.voice))),
                ),
                _buildActionCard(
                  context,
                  'History',
                  CupertinoIcons.clock_fill,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
                _buildActionCard(
                  context,
                  'Progress',
                  CupertinoIcons.graph_square_fill,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final state = context.watch<AppState>();
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: state.userPhoto != null 
                    ? MemoryImage(base64Decode(state.userPhoto!)) 
                    : null,
                child: state.userPhoto == null 
                    ? Icon(CupertinoIcons.person_fill, color: Theme.of(context).primaryColor)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName != null && state.userName!.isNotEmpty 
                          ? 'Welcome Back, ${state.userName}!' 
                          : 'Welcome Back!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      state.isPremium ? 'Premium Plan Active' : 'Free Plan: ${15 - state.dailyCount} questions left',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.pencil_circle_fill, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
