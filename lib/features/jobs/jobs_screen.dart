import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Job listings screen with teal header, search, filters, and sample job cards.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedFilter = 0;
  int _selectedNav = 0;

  static const Color _teal = Color(0xFF1B7A6E);

  static const _filters = ['All', 'Remote', 'Step-free', 'With Support'];

  static const _jobs = [
    _JobData(
      title: 'Customer Support Advisor',
      company: 'TechCorp Ltd',
      location: 'London, UK',
      tags: ['Remote OK', 'Written Instructions'],
    ),
    _JobData(
      title: 'Warehouse Operative',
      company: 'LogiNext',
      location: 'Manchester, UK',
      tags: ['Step-free Access', 'Flexible Hours'],
    ),
    _JobData(
      title: 'Data Entry Clerk',
      company: 'FinServe Group',
      location: 'Remote',
      tags: ['Remote OK', 'Flexible Hours', 'Written Instructions'],
    ),
    _JobData(
      title: 'Retail Assistant',
      company: 'GreenMart',
      location: 'Birmingham, UK',
      tags: ['Step-free Access', 'With Support'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dark teal header (no AppBar)
          _buildHeader(),
          // Search bar
          _buildSearchBar(),
          // Filter chips
          _buildFilterRow(),
          // Job cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.sm,
              ),
              itemCount: _jobs.length,
              itemBuilder: (context, index) =>
                  _JobCard(job: _jobs[index], teal: _teal),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNav,
        selectedItemColor: _teal,
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: (i) => setState(() => _selectedNav = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _teal,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Good morning!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Discover jobs that fit your needs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for jobs...',
          prefixIcon: const Icon(Icons.search),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _teal, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _teal : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected ? _teal : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1A1A1A),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

@immutable
class _JobData {
  const _JobData({
    required this.title,
    required this.company,
    required this.location,
    required this.tags,
  });

  final String title;
  final String company;
  final String location;
  final List<String> tags;
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.teal});

  final _JobData job;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: teal square icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.company} · ${job.location}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: job.tags.map((tag) => _TagChip(label: tag, teal: teal)).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Right: teal circle chevron
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.teal});

  final String label;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: teal),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: teal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
