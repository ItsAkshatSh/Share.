import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/hangout.dart';
import '../services/hangout_repository.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/panel.dart';
import 'hangout_detail_screen.dart';

/// One field that filters event shares and guests by name.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = HangoutRepository.instance;
    final results = repo.search(_query);
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 6),
            AppScreenHeader(
              title: 'Search',
              subtitle: 'EVENTS · GUESTS',
              onBack: () => Navigator.maybePop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Panel(
                margin: EdgeInsets.zero,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search events and guests…',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: !hasQuery
                  ? _Hint()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (results.events.isNotEmpty) ...[
                          const SectionLabel('EVENT SHARES',
                              trailing: null),
                          for (final h in results.events) ...[
                            _EventResult(hangout: h),
                            const SizedBox(height: 10),
                          ],
                        ],
                        if (results.people.isNotEmpty) ...[
                          const SectionLabel('GUESTS'),
                          Panel(
                            child: Column(
                              children: [
                                for (final a in results.people)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              NetworkImage(a.avatarUrl),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                a.subtitle,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${repo.totalPhotosOfUser}',
                                          style: AppTheme.mono(
                                            size: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (results.events.isEmpty && results.people.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'No matches for "$_query"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
    );
  }
}

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            'Find a share or a friend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventResult extends StatelessWidget {
  final Hangout hangout;

  const _EventResult({required this.hangout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HangoutRepository.instance.selectHangout(hangout.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HangoutDetailScreen(hangout: hangout),
          ),
        );
      },
      child: Panel(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusChip),
                child: Image.network(
                  hangout.heroImageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hangout.title.replaceAll('\n', ' '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hangout.category} · ${hangout.ttlLabel}',
                      style: AppTheme.mono(
                        size: 9,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
