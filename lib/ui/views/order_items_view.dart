import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product_item.dart';
import '../../state/shipment_state.dart';
import '../widgets/dialogs/product_edit_dialog.dart';
import '../widgets/product_card/product_card.dart';

class OrderItemsView extends ConsumerStatefulWidget {
  const OrderItemsView({super.key});

  @override
  ConsumerState<OrderItemsView> createState() => _OrderItemsViewState();
}

class _OrderItemsViewState extends ConsumerState<OrderItemsView> {
  String _searchQuery = '';
  StackingTier? _selectedTier;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(productItemsProvider);

    final filteredItems = items.where((item) {
      if (_selectedTier != null && item.stackingTier != _selectedTier) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchModel = item.modelNumber.toLowerCase().contains(q);
        final matchSupplier = item.supplierName.toLowerCase().contains(q);
        return matchName || matchModel || matchSupplier;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter & Search Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0B132B),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              // Search Input
              SizedBox(
                width: 280,
                height: 36,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search SKU, model, or factory...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Chips: All, Floor Heavy, Middle, Fragile Top
              _filterChip(
                label: 'All Tiers (${items.length})',
                isSelected: _selectedTier == null,
                onTap: () => setState(() => _selectedTier = null),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Floor (Heavy)',
                isSelected: _selectedTier == StackingTier.heavyFloor,
                onTap: () => setState(() => _selectedTier = StackingTier.heavyFloor),
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Mid (Standard)',
                isSelected: _selectedTier == StackingTier.mediumMiddle,
                onTap: () => setState(() => _selectedTier = StackingTier.mediumMiddle),
                color: const Color(0xFF818CF8),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Top (Fragile)',
                isSelected: _selectedTier == StackingTier.fragileTop,
                onTap: () => setState(() => _selectedTier = StackingTier.fragileTop),
                color: const Color(0xFFF43F5E),
              ),

              const Spacer(),

              if (items.isNotEmpty) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Erase All Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Erase All Container Products?',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: const SizedBox(
                          width: 380,
                          child: Text(
                            'Are you sure you want to erase all products in this active shipment? This will wipe all loaded items so you can start clean. This cannot be undone.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.delete_forever_rounded, size: 16),
                            label: const Text('Erase All Data', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              ref.read(productItemsProvider.notifier).clearAll();
                              ref.read(shipmentViewModelProvider.notifier).clearAllItems();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Product Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ProductEditDialog(),
                  );
                },
              ),
            ],
          ),
        ),

        // Product Cards Grid / List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded, size: 52, color: Color(0xFF475569)),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching product cards found',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try clearing the search query or tier filter.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredItems.length,
                  itemBuilder: (ctx, index) {
                    final item = filteredItems[index];
                    return ProductCard(
                      item: item,
                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (_) => ProductEditDialog(initialItem: item),
                        );
                      },
                      onDuplicate: () {
                        ref.read(productItemsProvider.notifier).addItem(
                              item.copyWith(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                modelNumber: '${item.modelNumber}-COPY',
                              ),
                            );
                      },
                      onDelete: () => ref.read(productItemsProvider.notifier).removeItem(item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFF0284C7);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
