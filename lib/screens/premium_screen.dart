import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(CupertinoIcons.star_circle_fill, size: 50, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Unlock Full Potential',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(CupertinoIcons.infinite, 'Unlimited AI Questions'),
            _buildFeatureRow(CupertinoIcons.doc_text_search, 'Detailed AI Explanations'),
            _buildFeatureRow(CupertinoIcons.list_number, 'Customize MCQ Count (up to 15)'),
            _buildFeatureRow(CupertinoIcons.gauge, 'All Difficulty Levels (Hard/Medium)'),
            _buildFeatureRow(CupertinoIcons.cloud_download, 'Download Marksheet as PDF'),
            _buildFeatureRow(CupertinoIcons.clock_fill, 'Unlimited Study History'),
            const SizedBox(height: 40),
            _buildPlanCard(
              context,
              'Monthly',
              '₹99',
              'premium_monthly',
              state.isPremium,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context,
              '6 Months',
              '₹499',
              'premium_6month',
              state.isPremium,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context,
              'Yearly',
              '₹799',
              'premium_yearly',
              state.isPremium,
              isBestOffer: true,
            ),
            const SizedBox(height: 32),
            if (state.isPremium)
              const Text(
                'You are currently a Premium member!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else
              TextButton(
                onPressed: () => state.togglePremium(),
                child: const Text('Restore Purchases (Simulated for Demo)'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String title, String price, String id, bool isSubscribed, {bool isBestOffer = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestOffer ? Colors.amber : Colors.grey[300]!,
          width: isBestOffer ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isBestOffer ? const Text('Best Value', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('/ period', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        onTap: () {
          Provider.of<AppState>(context, listen: false).togglePremium();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription toggled (Demo Mode)")),
          );
        },
      ),
    );
  }
}
