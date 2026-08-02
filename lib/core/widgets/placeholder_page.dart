import 'package:flutter/material.dart';

/// Generic "coming soon" screen used for feature routes that are prepared
/// in the router but not yet implemented (Pets, Profile, Genealogy,
/// Matching, Health).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — Coming soon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
