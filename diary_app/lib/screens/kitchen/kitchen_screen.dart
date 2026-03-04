import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/screens/kitchen/add_kitchen_item_screen.dart';

enum KitchenSortOption { basisProdukt, mhd, tags }

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final KitchenService _kitchenService = KitchenService();
  bool _isLoading = true;
  List<KitchenItem> _allItems = []; // All items from DB
  Map<int, List<KitchenTag>> _itemTags = {}; // Map of itemId to its tags

  String _searchQuery = '';
  KitchenSortOption _sortOption = KitchenSortOption.basisProdukt;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _kitchenService.getAllItems();

    // Load tags for each item to allow filtering/sorting by tags
    Map<int, List<KitchenTag>> tagsMap = {};
    for (var item in items) {
      if (item.id != null) {
        tagsMap[item.id!] = await _kitchenService.getTagsForItem(item.id!);
      }
    }

    if (mounted) {
      setState(() {
        _allItems = items;
        _itemTags = tagsMap;
        _isLoading = false;
      });
    }
  }

  List<KitchenItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _allItems;

    return _allItems.where((item) {
      final nameMatch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final basisMatch = item.basisProdukt.toLowerCase().contains(_searchQuery.toLowerCase());

      bool tagMatch = false;
      if (item.id != null && _itemTags.containsKey(item.id)) {
        tagMatch = _itemTags[item.id!]!.any(
          (tag) => tag.name.toLowerCase().contains(_searchQuery.toLowerCase())
        );
      }

      return nameMatch || basisMatch || tagMatch;
    }).toList();
  }

  // Groups items. The outer key is the grouping criterion (based on sort option).
  // The inner Map is grouped by "basisProdukt|einheit" to aggregate identical products.
  Map<String, Map<String, List<KitchenItem>>> _groupItems(List<KitchenItem> items) {
    final Map<String, Map<String, List<KitchenItem>>> grouped = {};

    for (final item in items) {
      String groupKey;

      switch (_sortOption) {
        case KitchenSortOption.basisProdukt:
          groupKey = item.basisProdukt;
          break;
        case KitchenSortOption.mhd:
          if (item.haltbarBis != null) {
            // Group by year-month-day for MHD sorting
            groupKey = DateFormat('yyyy-MM-dd').format(item.haltbarBis!);
          } else {
            groupKey = 'Ohne MHD';
          }
          break;
        case KitchenSortOption.tags:
          if (item.id != null && _itemTags.containsKey(item.id!) && _itemTags[item.id!]!.isNotEmpty) {
            // Take the first tag as primary group, or join them
            groupKey = _itemTags[item.id!]!.first.name;
          } else {
            groupKey = 'Ohne Tags';
          }
          break;
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = {};
      }

      // Secondary grouping: always group identical products together so we can sum their amounts
      final secondaryKey = '${item.basisProdukt}|${item.einheit}';

      if (!grouped[groupKey]!.containsKey(secondaryKey)) {
        grouped[groupKey]![secondaryKey] = [];
      }
      grouped[groupKey]![secondaryKey]!.add(item);
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
              Text('Aktuelle Menge: ${_formatTotal(item.menge)} ${item.einheit}'),
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

  String _formatTotal(double total) {
    if (total == total.toInt()) return total.toInt().toString();
    return total.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Color _getExpirationColor(DateTime? expirationDate) {
    if (expirationDate == null) return Colors.grey.shade400; // hellgrau kein MHD
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
    final difference = expiration.difference(today).inDays;

    if (difference < 4) return Colors.red; // Rot < 4 Tage verbleibend (0, 1, 2, 3) + abgelaufen
    if (difference < 10) return Colors.orange; // Gelb < 10 Tage verbleibend (4, 5, 6, 7, 8, 9)
    return Colors.green; // Grün >= 10 Tage verbleibend
  }

  Color _getMostCriticalColor(List<KitchenItem> items) {
    int severity = 0; // 0 = grey, 1 = green, 2 = orange, 3 = red
    for (var item in items) {
      final color = _getExpirationColor(item.haltbarBis);
      if (color == Colors.red) {
        severity = 3;
        break; // Max severity
      } else if (color == Colors.orange && severity < 2) {
        severity = 2;
      } else if (color == Colors.green && severity < 1) {
        severity = 1;
      }
    }

    if (severity == 3) return Colors.red;
    if (severity == 2) return Colors.orange;
    if (severity == 1) return Colors.green;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final groupedItems = _groupItems(filtered);

    final sortedGroupKeys = groupedItems.keys.toList();
    sortedGroupKeys.sort((a, b) {
       // Custom sorting for groups
       if (_sortOption == KitchenSortOption.mhd) {
         if (a == 'Ohne MHD') return 1;
         if (b == 'Ohne MHD') return -1;
       }
       if (_sortOption == KitchenSortOption.tags) {
         if (a == 'Ohne Tags') return 1;
         if (b == 'Ohne Tags') return -1;
       }

       if (_sortOption == KitchenSortOption.basisProdukt) {
         // Sort by MHD of the most critical item in the group, then alphabetically
         DateTime? getEarliestMhd(String key) {
           DateTime? earliest;
           for (var secondary in groupedItems[key]!.values) {
             for (var item in secondary) {
               if (item.haltbarBis != null) {
                 if (earliest == null || item.haltbarBis!.isBefore(earliest)) {
                   earliest = item.haltbarBis;
                 }
               }
             }
           }
           return earliest;
         }

         final earliestA = getEarliestMhd(a);
         final earliestB = getEarliestMhd(b);

         if (earliestA == null && earliestB == null) return a.compareTo(b);
         if (earliestA == null) return 1;
         if (earliestB == null) return -1;

         final dateComparison = earliestA.compareTo(earliestB);
         if (dateComparison != 0) return dateComparison;
       }

       return a.compareTo(b);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Küche - Vorrat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Suchen (Name, Basis-Produkt, Tag)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Gruppieren nach: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<KitchenSortOption>(
                        isExpanded: true,
                        value: _sortOption,
                        items: const [
                          DropdownMenuItem(
                            value: KitchenSortOption.basisProdukt,
                            child: Text('Basis-Produkt'),
                          ),
                          DropdownMenuItem(
                            value: KitchenSortOption.mhd,
                            child: Text('Haltbarkeit (MHD)'),
                          ),
                          DropdownMenuItem(
                            value: KitchenSortOption.tags,
                            child: Text('Tags'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortOption = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allItems.isEmpty
              ? const Center(child: Text('Keine Vorräte vorhanden. Füge etwas hinzu!'))
              : filtered.isEmpty
                  ? const Center(child: Text('Keine Ergebnisse für deine Suche.'))
                  : ListView.builder(
                      itemCount: sortedGroupKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final groupKey = sortedGroupKeys[groupIndex];
                        final secondaryGroups = groupedItems[groupKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show group header if not grouped by basis_produkt
                            if (_sortOption != KitchenSortOption.basisProdukt)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  groupKey == 'Ohne MHD' || groupKey == 'Ohne Tags'
                                      ? groupKey
                                      : (_sortOption == KitchenSortOption.mhd
                                          ? 'MHD: ${DateFormat("dd.MM.yyyy").format(DateTime.parse(groupKey))}'
                                          : 'Tag: $groupKey'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),

                            ...secondaryGroups.entries.map((entry) {
                              final secondaryKey = entry.key; // "basisProdukt|einheit"
                              final itemsForSecondaryGroup = entry.value;

                              final parts = secondaryKey.split('|');
                              final basisProdukt = parts[0];
                              final einheit = parts[1];

                              // Sort individual items by expiration date inside this expansion tile
                              itemsForSecondaryGroup.sort((a, b) {
                                // If grouped by tags, and both have MHD, prioritize tags sorting logic but secondary is MHD
                                // We always secondary sort by MHD inside the ExpansionTile
                                if (a.haltbarBis == null && b.haltbarBis == null) {
                                   // third-level sort by tags if possible, otherwise by name
                                   return a.name.compareTo(b.name);
                                }
                                if (a.haltbarBis == null) return 1;
                                if (b.haltbarBis == null) return -1;
                                return a.haltbarBis!.compareTo(b.haltbarBis!);
                              });

                              final totalMenge = itemsForSecondaryGroup.fold(0.0, (sum, item) => sum + item.menge);

                              String displayTotal = '';
                              if (einheit == 'g' && totalMenge >= 1000) {
                                displayTotal = '${_formatTotal(totalMenge / 1000)} kg';
                              } else if (einheit == 'ml' && totalMenge >= 1000) {
                                displayTotal = '${_formatTotal(totalMenge / 1000)} l';
                              } else {
                                displayTotal = '${_formatTotal(totalMenge)} $einheit';
                              }

                              return Column(
                                children: [
                                  ExpansionTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 24,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: _getMostCriticalColor(itemsForSecondaryGroup),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            basisProdukt,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text('Gesamt: $displayTotal'),
                                    children: itemsForSecondaryGroup.map<Widget>((item) {
                                      // Get tags for display
                                      final itemTags = item.id != null && _itemTags.containsKey(item.id!)
                                          ? _itemTags[item.id!]!.map((t) => t.name).join(', ')
                                          : '';

                                      return ListTile(
                                        onTap: () async {
                                          final tags = item.id != null && _itemTags.containsKey(item.id!) ? _itemTags[item.id!]! : <KitchenTag>[];
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => AddKitchenItemScreen(
                                                existingItem: item,
                                                existingTags: tags,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadItems();
                                          }
                                        },
                                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                                        title: Text(item.name),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (item.marke != null && item.marke!.isNotEmpty)
                                              Text('Marke: ${item.marke}'),
                                            if (itemTags.isNotEmpty)
                                              Text('Tags: $itemTags', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
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
                                                    'MHD: ${DateFormat('dd.MM.yyyy').format(item.haltbarBis!)}',
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
                                              '${_formatTotal(item.menge)} ${item.einheit}',
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
                                  ),
                                  const Divider(height: 1),
                                ],
                              );
                            }),
                          ],
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
