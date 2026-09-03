import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/depth_ladder.dart';

class DepthTab extends StatelessWidget {
  final Quote quote;

  const DepthTab({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DepthLadder(depth: quote.depth),
    );
  }
}
