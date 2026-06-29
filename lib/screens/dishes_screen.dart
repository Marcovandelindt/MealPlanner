import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../services/storage_service.dart';

class DishesScreen extends StatefulWidget {
  const DishesScreen({super.key});

  @override
  State<DishesScreen> createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  List<Dish> _dishes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dishes = await StorageService.loadDishes();
    if (mounted) {
      setState(() {
        _dishes = dishes;
        _loaded = true;
      });
    }
  }

  Future<void> _addDish(String name) async {
    final dish = Dish(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    setState(() => _dishes.add(dish));
    await StorageService.saveDishes(_dishes);
  }

  Future<void> _deleteDish(String id) async {
    setState(() => _dishes.removeWhere((d) => d.id == id));
    await StorageService.saveDishes(_dishes);
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerecht toevoegen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'bijv. Spaghetti Bolognese',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              _addDish(v);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleer'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addDish(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Dish dish) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verwijderen?'),
        content: Text('"${dish.name}" verwijderen uit je lijst?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDish(dish.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needed = (5 - _dishes.length).clamp(0, 5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text('Gerechten${_dishes.isNotEmpty ? ' (${_dishes.length})' : ''}'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_dishes.isNotEmpty && needed > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Voeg nog $needed gerecht${needed == 1 ? '' : 'en'} toe om het wiel te draaien',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Expanded(
                  child: _dishes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 72,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Geen gerechten nog',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tik op + om je favorieten toe te voegen',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _dishes.length,
                          itemBuilder: (context, i) {
                            final dish = _dishes[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  dish.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(dish.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: theme.colorScheme.error,
                                onPressed: () => _confirmDelete(dish),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Gerecht toevoegen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
