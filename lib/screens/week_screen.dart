import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../services/storage_service.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  List<String> _weekPlan = const ['', '', '', '', ''];
  bool _isSpinning = false;
  final Set<int> _spinningSlots = {};

  static const List<String> _days = [
    'Maandag',
    'Dinsdag',
    'Woensdag',
    'Donderdag',
    'Vrijdag',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final plan = await StorageService.loadWeekPlan();
    if (mounted) setState(() => _weekPlan = plan);
  }

  Future<void> _spin() async {
    final dishes = await StorageService.loadDishes();

    if (!mounted) return;
    if (dishes.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dishes.isEmpty
                ? 'Voeg gerechten toe via het tabblad "Gerechten"!'
                : 'Je hebt nog ${5 - dishes.length} gerecht(en) nodig. Voeg meer toe!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shuffled = List<Dish>.from(dishes)..shuffle(Random());
    final picked = shuffled.take(5).map((d) => d.name).toList();

    setState(() {
      _isSpinning = true;
      _spinningSlots.addAll([0, 1, 2, 3, 4]);
      _weekPlan = const ['', '', '', '', ''];
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final newPlan = List<String>.filled(5, '');
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _spinningSlots.remove(i);
        newPlan[i] = picked[i];
        _weekPlan = List.from(newPlan);
      });
    }

    setState(() => _isSpinning = false);
    await StorageService.saveWeekPlan(_weekPlan);
  }

  bool get _hasPlan => _weekPlan.any((m) => m.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('Deze week'),
      ),
      body: Column(
        children: [
          if (_hasPlan)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Haal maandag de boodschappen!',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: 5,
              itemBuilder: (context, i) => _MealSlot(
                day: _days[i],
                meal: _weekPlan[i],
                isSpinning: _spinningSlots.contains(i),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSpinning ? null : _spin,
                  icon: _isSpinning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.casino),
                  label: Text(
                    _isSpinning ? 'Aan het draaien...' : 'Draai het wiel!',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String day;
  final String meal;
  final bool isSpinning;

  const _MealSlot({
    required this.day,
    required this.meal,
    required this.isSpinning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFood = meal.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSpinning
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpinning
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSpinning ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSpinning
                  ? SizedBox(
                      key: const ValueKey('spin'),
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : CircleAvatar(
                      key: const ValueKey('icon'),
                      radius: 18,
                      backgroundColor: hasFood
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.restaurant,
                        size: 18,
                        color: hasFood
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.outline,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      isSpinning
                          ? '...'
                          : hasFood
                              ? meal
                              : 'Nog niet gepland',
                      key: ValueKey('$meal-$isSpinning'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            hasFood && !isSpinning ? FontWeight.w600 : FontWeight.normal,
                        color: hasFood && !isSpinning
                            ? null
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
