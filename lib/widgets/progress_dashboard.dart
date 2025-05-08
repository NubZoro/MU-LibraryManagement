import 'package:flutter/material.dart';
import 'package:libmu/models/user_model.dart';
import 'package:libmu/services/gamification_service.dart';

class ProgressDashboard extends StatelessWidget {
  final UserModel user;

  const ProgressDashboard({
    Key? key,
    required this.user,
  }) : super(key: key);

  String _getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Freshman';
      case 2:
        return 'Sophomore';
      case 3:
        return 'Junior';
      case 4:
        return 'Senior';
      case 5:
        return 'Scholar';
      case 6:
        return 'Master';
      case 7:
        return 'Grand Master';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> _getLevelProgress(int points) {
    final currentLevel = GamificationService.LEVEL_THRESHOLDS.entries
        .where((entry) => points >= entry.value)
        .last;
    
    final nextLevel = GamificationService.LEVEL_THRESHOLDS.entries
        .where((entry) => points < entry.value)
        .firstOrNull;

    if (nextLevel == null) return {
      'progress': 1.0,
      'currentPoints': points,
      'nextLevelPoints': null,
      'pointsNeeded': 0,
      'nextLevel': null,
    };

    final pointsForCurrentLevel = currentLevel.value;
    final pointsForNextLevel = nextLevel.value;
    final pointsNeeded = pointsForNextLevel - pointsForCurrentLevel;
    final pointsGained = points - pointsForCurrentLevel;

    return {
      'progress': pointsGained / pointsNeeded,
      'currentPoints': points,
      'nextLevelPoints': pointsForNextLevel,
      'pointsNeeded': pointsNeeded - pointsGained,
      'nextLevel': nextLevel.key,
    };
  }

  Widget _buildNextLevelPreview(BuildContext context, int currentLevel, int nextLevel) {
    final gamification = GamificationService();
    final currentBooks = gamification.getMaxBooksAllowed(currentLevel);
    final nextBooks = gamification.getMaxBooksAllowed(nextLevel);
    final currentDuration = gamification.getBorrowingDuration(currentLevel);
    final nextDuration = gamification.getBorrowingDuration(nextLevel);
    final willGetPriority = !gamification.hasPriorityReservation(currentLevel) && 
                           gamification.hasPriorityReservation(nextLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Level Privileges',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (nextBooks > currentBooks)
          _buildUpgradeItem(
            context,
            'Borrow up to $nextBooks books',
            '(+${nextBooks - currentBooks})',
          ),
        if (nextDuration > currentDuration)
          _buildUpgradeItem(
            context,
            '$nextDuration days borrowing time',
            '(+${nextDuration - currentDuration} days)',
          ),
        if (willGetPriority)
          _buildUpgradeItem(
            context,
            'Priority Reservation',
            '(New!)',
          ),
      ],
    );
  }

  Widget _buildUpgradeItem(BuildContext context, String text, String bonus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_circle_up,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(text),
          const SizedBox(width: 4),
          Text(
            bonus,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelProgress = _getLevelProgress(user.points);
    final nextLevel = levelProgress['nextLevel'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLevelTitle(user.level),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${user.level}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.points} Points',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextLevel != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: levelProgress['progress'],
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${levelProgress['pointsNeeded']} points needed for ${_getLevelTitle(nextLevel)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildNextLevelPreview(context, user.level, nextLevel),
              const Divider(height: 32),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.consecutiveReturns > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.consecutiveReturns}x Streak',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (user.badges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Borrow your first book to start earning badges!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.badges.map((badge) {
                  return Chip(
                    avatar: const Icon(Icons.emoji_events, size: 18),
                    label: Text(badge),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
} 