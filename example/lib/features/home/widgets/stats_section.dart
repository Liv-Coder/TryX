import 'package:flutter/material.dart';

/// Stats section widget showing key metrics about Tryx
class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Tryx?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Stats grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              if (isWide) {
                return Row(
                  children: _buildStatItems(context)
                      .map((item) => Expanded(child: item))
                      .toList(),
                );
              } else {
                return Column(
                  children: _buildStatItems(context),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatItems(BuildContext context) {
    final stats = [
      const _StatItem(
        icon: Icons.speed,
        value: '0ms',
        label: 'Runtime Overhead',
        description: 'Zero-cost abstractions',
      ),
      const _StatItem(
        icon: Icons.code,
        value: '132',
        label: 'Tests Passing',
        description: 'Comprehensive coverage',
      ),
      const _StatItem(
        icon: Icons.security,
        value: '100%',
        label: 'Type Safety',
        description: 'Compile-time guarantees',
      ),
      const _StatItem(
        icon: Icons.trending_up,
        value: '3x',
        label: 'Less Boilerplate',
        description: 'Compared to try-catch',
      ),
    ];

    return stats.map((stat) => _buildStatCard(context, stat)).toList();
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              stat.icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 12),

          // Value
          Text(
            stat.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            stat.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            stat.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final String description;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.description,
  });
}
