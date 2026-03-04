import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/screens/kitchen/add_kitchen_item_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final KitchenService _kitchenService = KitchenService();
  bool _isLoading = true;
  List<KitchenItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _kitchenService.getAllItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // Groups items by basisProdukt. Value is a Map grouped by einheit.
  Map<String, Map<String, List<KitchenItem>>> _groupItems(List<KitchenItem> items) {
    final Map<String, Map<String, List<KitchenItem>>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.basisProdukt)) {
        grouped[item.basisProdukt] = {};
      }
      if (!grouped[item.basisProdukt]!.containsKey(item.einheit)) {
        grouped[item.basisProdukt]![item.einheit] = [];
      }
      grouped[item.basisProdukt]![item.einheit]!.add(item);
    }
    return grouped;
  }

  void _showConsumeDialog(KitchenItem item) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verbrauchen: ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aktuelle Menge: ${_formatAmount(item.menge)} ${item.einheit}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Verbrauchte Menge (${item.einheit})',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.replaceAll(',', '.');
                final amount = double.tryParse(amountText);
                if (amount != null && amount > 0) {
                  Navigator.of(context).pop();
                  await _kitchenService.consumeItem(item.id!, amount);
                  _loadItems();
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getExpirationColor(DateTime? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;

    if (difference < 0) return Colors.red; // Expired
    if (difference <= 3) return Colors.orange; // Expiring soon
    return Colors.green; // Still good
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItems(_items);
    final sortedBasisProdukts = groupedItems.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Küche - Vorrat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Keine Vorräte vorhanden. Füge etwas hinzu!'))
              : ListView.builder(
                  itemCount: sortedBasisProdukts.length,
                  itemBuilder: (context, index) {
                    final basisProdukt = sortedBasisProdukts[index];
                    final byEinheit = groupedItems[basisProdukt]!;

                    // Create an expansion tile for each unit of the same basis produkt
                    return Column(
                      children: byEinheit.entries.map((entry) {
                        final einheit = entry.key;
                        final itemsForEinheit = entry.value;

                        // Sort items by expiration date
                        itemsForEinheit.sort((a, b) {
                          if (a.haltbarBis == null && b.haltbarBis == null) return 0;
                          if (a.haltbarBis == null) return 1;
                          if (b.haltbarBis == null) return -1;
                          return a.haltbarBis!.compareTo(b.haltbarBis!);
                        });

                        final totalMenge = itemsForEinheit.fold(0.0, (sum, item) => sum + item.menge);

                        // Formatter for total display (e.g. 1000g -> 1kg)
                        String displayTotal = '';
                        if (einheit == 'g' && totalMenge >= 1000) {
                          displayTotal = '${_formatAmount(totalMenge / 1000)} kg';
                        } else if (einheit == 'ml' && totalMenge >= 1000) {
                          displayTotal = '${_formatAmount(totalMenge / 1000)} l';
                        } else {
                          displayTotal = '${_formatAmount(totalMenge)} $einheit';
                        }

                        return ExpansionTile(
                          title: Text(
                            basisProdukt,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Gesamt: $displayTotal'),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.kitchen, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          children: itemsForEinheit.map((item) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 72, right: 16),
                              title: Text(item.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.marke != null && item.marke!.isNotEmpty)
                                    Text('Marke: ${item.marke}'),
                                  if (item.haltbarBis != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: _getExpirationColor(item.haltbarBis),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'MHD: ${_formatDate(item.haltbarBis!)}',
                                          style: TextStyle(
                                            color: _getExpirationColor(item.haltbarBis),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_formatAmount(item.menge)} ${item.einheit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.restaurant),
                                    onPressed: () => _showConsumeDialog(item),
                                    tooltip: 'Verbrauchen',
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddKitchenItemScreen()),
          );
          if (result == true) {
            _loadItems();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
