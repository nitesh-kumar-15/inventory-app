import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item.dart';
import '../services/inventory_service.dart';

/// threshold for low-stock highlighting and filter (enhanced feature).
const int kLowStockThreshold = 10;

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.service});

  final InventoryService service;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> _filteredAndSorted(List<Item> items) {
    var list = List<Item>.from(items);
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (_lowStockOnly) {
      list = list.where((i) => i.quantity < kLowStockThreshold).toList();
    }
    return list;
  }

  Future<void> _confirmDelete(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.service.deleteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${item.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openItemForm({Item? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ItemFormSheet(
        existing: existing,
        service: widget.service,
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text('Low stock (<$kLowStockThreshold)'),
                  selected: _lowStockOnly,
                  onSelected: (v) => setState(() => _lowStockOnly = v),
                ),
                Text(
                  'Live updates from Firestore',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: widget.service.streamItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final items = _filteredAndSorted(all);

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        all.isEmpty
                            ? 'No items yet.\nTap + to add your first item.'
                            : 'No items match your search or filter.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final low = item.quantity < kLowStockThreshold;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty ${item.quantity}  ·  \$${item.price.toStringAsFixed(2)}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: low
                              ? colorScheme.errorContainer
                              : colorScheme.primaryContainer,
                          foregroundColor: low
                              ? colorScheme.onErrorContainer
                              : colorScheme.onPrimaryContainer,
                          child: Icon(
                            low ? Icons.warning_amber_rounded : Icons.inventory_2,
                            size: 22,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (low)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Chip(
                                  label: const Text('Low'),
                                  visualDensity: VisualDensity.compact,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                  backgroundColor: colorScheme.errorContainer,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openItemForm(existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openItemForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// the sheet is removed (avoids "used after being disposed").
class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({
    required this.existing,
    required this.service,
    required this.parentContext,
  });

  final Item? existing;
  final InventoryService service;
  final BuildContext parentContext;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _qtyController = TextEditingController(
      text: e != null ? '${e.quantity}' : '',
    );
    _priceController = TextEditingController(
      text: e != null ? e.price.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext sheetContext) async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final qty = int.parse(_qtyController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final item = Item(
      id: widget.existing?.id ?? '',
      name: name,
      quantity: qty,
      price: price,
    );
    try {
      if (_isEdit) {
        await widget.service.updateItem(item);
      } else {
        await widget.service.addItem(item);
      }
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Item updated' : 'Item added'),
          ),
        );
      }
    } catch (e) {
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Edit item' : 'Add item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Enter a whole number';
                  if (n < 0) return 'Quantity cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Unit price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null) {
                    return 'Enter a valid number (e.g. 12.99)';
                  }
                  if (n < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _submit(context),
                child: Text(_isEdit ? 'Save changes' : 'Add to inventory'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
