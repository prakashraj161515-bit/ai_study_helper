import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import 'input_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'marksheet_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.userName != null && state.userName!.isNotEmpty 
                            ? 'Hi ${state.userName} 👋' 
                            : 'Hi Student 👋',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      Text(
                        "Let's study smarter today!",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: state.userPhoto != null 
                              ? MemoryImage(base64Decode(state.userPhoto!)) 
                              : null,
                          child: state.userPhoto == null 
                              ? Icon(CupertinoIcons.person_fill, color: Theme.of(context).primaryColor)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Search/Ask Bar (Simulated)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.text))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.search, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ask anything to your AI Assistant...',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ),
                      const Icon(CupertinoIcons.mic_fill, color: Color(0xFF2E7D32), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildActionCard(
                    context,
                    'Ask AI',
                    'Get instant answers to any question',
                    CupertinoIcons.chat_bubble_2_fill,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF2E7D32),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.text))),
                  ),
                  _buildActionCard(
                    context,
                    'Scan Notes',
                    'Extract notes & summarize instantly',
                    CupertinoIcons.camera_viewfinder,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF1976D2),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.scan))),
                  ),
                  _buildActionCard(
                    context,
                    'Upload PDF',
                    'Analyze your study material (PDF)',
                    CupertinoIcons.doc_fill,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFF57C00),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen(mode: InputMode.upload))),
                  ),
                  _buildActionCard(
                    context,
                    'Saved Notes',
                    'View your saved notes & chats',
                    CupertinoIcons.bookmark_fill,
                    const Color(0xFFF3E5F5),
                    const Color(0xFF7B1FA2),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // AI Promo Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Study Assistant',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your personal AI tutor available 24/7 to help you learn better.',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recent Chats Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Chats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    child: const Text('See all', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Recent Chats List
              if (state.history.isEmpty)
                _buildEmptyHistory()
              else
                ...state.history.take(3).map((item) => _buildRecentChatItem(context, item)),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, 
    Color bgColor, 
    Color iconColor, 
    VoidCallback onTap
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChatItem(BuildContext context, StudyHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
          child: const Icon(CupertinoIcons.chat_bubble_text, size: 18, color: Color(0xFF2E7D32)),
        ),
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d • hh:mm a').format(item.timestamp),
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        trailing: Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey[300]),
        onTap: () {
          // Navigating to history detail (already existing function)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.chat_bubble_2, color: Colors.grey[200], size: 48),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
