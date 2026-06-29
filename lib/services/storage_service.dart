import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dish.dart';

class StorageService {
  static const String _dishesKey = 'dishes';
  static const String _weekPlanKey = 'week_plan';

  static Future<List<Dish>> loadDishes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_dishesKey) ?? [];
    return raw
        .map((e) => Dish.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveDishes(List<Dish> dishes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dishesKey,
      dishes.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  static Future<List<String>> loadWeekPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_weekPlanKey);
    if (stored != null && stored.length == 5) return stored;
    return const ['', '', '', '', ''];
  }

  static Future<void> saveWeekPlan(List<String> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_weekPlanKey, plan);
  }
}
