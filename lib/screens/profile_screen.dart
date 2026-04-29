import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'premium_screen.dart';
import 'study_plan_screen.dart';
import 'reminder_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    if (state.userName != null) {
      _nameController.text = state.userName!;
    }
    _base64Image = state.userPhoto;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
      // Auto-save image to state
      if (mounted) {
        final state = Provider.of<AppState>(context, listen: false);
        state.setProfile(_nameController.text.trim(), _base64Image);
      }
    }
  }

  void _saveProfile() {
    final state = Provider.of<AppState>(context, listen: false);
    state.setProfile(_nameController.text.trim(), _base64Image);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green Header Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white24,
                              backgroundImage: _base64Image != null 
                                  ? MemoryImage(base64Decode(_base64Image!)) 
                                  : null,
                              child: _base64Image == null 
                                  ? const Icon(CupertinoIcons.person_fill, size: 45, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF2E7D32), size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.userName ?? 'Student Name',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'learner@studynova.com',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showEditNameDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E7D32),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    ),
                    child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Settings List
            _buildSettingTile(CupertinoIcons.star_fill, 'Get Premium', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
            }, color: Colors.amber),
            _buildSettingTile(CupertinoIcons.calendar, 'Study Plan', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPlanScreen()));
            }),
            _buildSettingTile(CupertinoIcons.bell, 'Reminders', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()));
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _saveProfile();
              Navigator.pop(context);
            }, 
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing, Color? color}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color ?? Colors.black87, size: 22),
      title: Text(
        title, 
        style: TextStyle(
          color: color ?? Colors.black87, 
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: trailing ?? Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey[300]),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
