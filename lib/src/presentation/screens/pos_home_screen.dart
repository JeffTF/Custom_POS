import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../widgets/admin_pin_dialog.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_editor_dialog.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/product_editor_dialog.dart';
import '../widgets/report_panel.dart';

class PosHomeScreen extends ConsumerStatefulWidget {
  const PosHomeScreen({super.key});

  @override
  ConsumerState<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends ConsumerState<PosHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _adminTabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _adminTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final filter = ref.watch(productFilterProvider);
    final appMode = ref.watch(appModeProvider);
    final taxRate = ref.watch(taxRateProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search product name or SKU',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(width: 16),
            SegmentedButton<AppMode>(
              segments: const [
                ButtonSegment<AppMode>(
                  value: AppMode.staff,
                  label: Text('Staff'),
                  icon: Icon(Icons.point_of_sale_outlined),
                ),
                ButtonSegment<AppMode>(
                  value: AppMode.admin,
                  label: Text('Admin'),
                  icon: Icon(Icons.admin_panel_settings_outlined),
                ),
              ],
              selected: {appMode},
              onSelectionChanged: (selection) => _changeMode(selection.first),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  categoriesAsync.when(
                    data: (categories) => _CategoryBar(
                      categories: categories,
                      selectedCategoryId: filter.categoryId,
                      onSelect: (categoryId) {
                        ref
                            .read(productFilterProvider.notifier)
                            .selectCategory(categoryId);
                      },
                      onAddCategory: appMode == AppMode.admin
                          ? () => _showCategoryEditor(categories: categories)
                          : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) =>
                        Text('Could not load categories: $error'),
                  ),
                  const SizedBox(height: 16),
                  if (appMode == AppMode.admin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          controller: _adminTabController,
                          isScrollable: true,
                          onTap: (_) => setState(() {}),
                          tabs: const [
                            Tab(text: 'Inventory'),
                            Tab(text: 'Reports'),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child:
                        appMode == AppMode.admin &&
                            _adminTabController.index == 1
                        ? _buildReportView()
                        : productsAsync.when(
                            data: (products) {
                              if (products.isEmpty) {
                                return const _EmptyState(
                                  icon: Icons.search_off_outlined,
                                  title: 'No products found',
                                  message:
                                      'Try another search term or switch categories.',
                                );
                              }

                              return Column(
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 1.03,
                                          ),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final product = products[index];
                                        return ProductCard(
                                          product: product,
                                          adminMode: appMode == AppMode.admin,
                                          onAdd: () => ref
                                              .read(cartProvider.notifier)
                                              .addProduct(product),
                                          onEdit: () => _showProductEditor(
                                            categories:
                                                categoriesAsync.value ??
                                                const <Category>[],
                                            product: product,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, _) => Center(
                              child: Text('Could not load products: $error'),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _CartSidebar(
                cart: cart,
                taxRate: taxRate,
                onIncrement: (productId, quantity) {
                  ref
                      .read(cartProvider.notifier)
                      .updateQuantity(productId, quantity + 1);
                },
                onDecrement: (productId, quantity) {
                  ref
                      .read(cartProvider.notifier)
                      .updateQuantity(productId, quantity - 1);
                },
                onRemove: (productId) {
                  ref.read(cartProvider.notifier).removeProduct(productId);
                },
                onClear: _confirmClearCart,
                onAdjustTaxRate: (value) =>
                    ref.read(taxRateProvider.notifier).state = value,
                onCheckout: cart.items.isEmpty ? null : _checkout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeMode(AppMode nextMode) async {
    if (nextMode == AppMode.admin) {
      final allowed = await showDialog<bool>(
        context: context,
        builder: (context) => const AdminPinDialog(),
      );
      if (allowed != true) {
        return;
      }
    }

    ref.read(appModeProvider.notifier).state = nextMode;
    if (nextMode == AppMode.staff) {
      _adminTabController.animateTo(0);
      setState(() {});
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(productFilterProvider.notifier).setSearchQuery(value);
    });
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear cart'),
          content: const Text('Remove all items from the cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart();
    }
  }

  Future<void> _checkout() async {
    final paymentMethod = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => const PaymentMethodDialog(),
    );
    if (paymentMethod == null) {
      return;
    }

    final message = await ref
        .read(cartProvider.notifier)
        .processSale(paymentMethod);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showProductEditor({
    Product? product,
    required List<Category> categories,
  }) async {
    final imageService = ref.read(imageServiceProvider);
    final saved = await showDialog<Product>(
      context: context,
      builder: (context) {
        return ProductEditorDialog(
          product: product,
          categories: categories,
          imageService: imageService,
        );
      },
    );
    if (saved == null) {
      return;
    }
    await ref.read(adminActionsProvider).saveProduct(saved);
  }

  Future<void> _showCategoryEditor({
    Category? category,
    required List<Category> categories,
  }) async {
    final saved = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryEditorDialog(category: category),
    );
    if (saved == null) {
      return;
    }
    await ref.read(adminActionsProvider).saveCategory(saved);
  }

  Widget _buildReportView() {
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final dailySummaryAsync = ref.watch(dailySummaryProvider);
    final topSellingAsync = ref.watch(topSellingProductsProvider);
    final hourlySalesAsync = ref.watch(hourlySalesProvider);

    if (dailySummaryAsync.isLoading ||
        lowStockAsync.isLoading ||
        topSellingAsync.isLoading ||
        hourlySalesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dailySummaryAsync.hasError ||
        lowStockAsync.hasError ||
        topSellingAsync.hasError ||
        hourlySalesAsync.hasError) {
      return const Center(child: Text('Reports could not be loaded.'));
    }

    return ReportPanel(
      summary: dailySummaryAsync.value!,
      lowStockProducts: lowStockAsync.value ?? const <Product>[],
      topSelling: topSellingAsync.value ?? const [],
      hourlySales: hourlySalesAsync.value ?? const [],
      onExport: () async {
        final path = await ref.read(adminActionsProvider).exportReportCsv();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report saved to $path')));
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    this.onAddCategory,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelect;
  final VoidCallback? onAddCategory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip.all(
                  selected: selectedCategoryId == null,
                  onTap: () => onSelect(null),
                ),
                const SizedBox(width: 8),
                ...categories.expand((category) {
                  return [
                    CategoryChip.fromCategory(
                      category: category,
                      selected: selectedCategoryId == category.id,
                      onTap: () => onSelect(category.id),
                    ),
                    const SizedBox(width: 8),
                  ];
                }),
              ],
            ),
          ),
        ),
        if (onAddCategory != null) ...[
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: onAddCategory,
            icon: const Icon(Icons.add),
            tooltip: 'Add category',
          ),
        ],
      ],
    );
  }
}

class _CartSidebar extends StatelessWidget {
  const _CartSidebar({
    required this.cart,
    required this.taxRate,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClear,
    required this.onAdjustTaxRate,
    required this.onCheckout,
  });

  final CartState cart;
  final double taxRate;
  final void Function(int productId, int quantity) onIncrement;
  final void Function(int productId, int quantity) onDecrement;
  final void Function(int productId) onRemove;
  final VoidCallback onClear;
  final ValueChanged<double> onAdjustTaxRate;
  final Future<void> Function()? onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Current Cart',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton.outlined(
                  onPressed: cart.items.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear cart',
                ),
              ],
            ),
            if (cart.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: _EmptyState(
                  icon: Icons.remove_shopping_cart_outlined,
                  title: 'Cart is empty',
                  message: 'Select products from the catalog to begin a sale.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemTile(
                      item: item,
                      onIncrement: () =>
                          onIncrement(item.product.id!, item.quantity),
                      onDecrement: () =>
                          onDecrement(item.product.id!, item.quantity),
                      onRemove: () => onRemove(item.product.id!),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text('Tax rate ${(taxRate * 100).toStringAsFixed(0)}%'),
            Slider(
              value: taxRate,
              min: 0,
              max: 0.2,
              divisions: 20,
              label: '${(taxRate * 100).round()}%',
              onChanged: onAdjustTaxRate,
            ),
            _SummaryRow(
              label: 'Subtotal',
              value: currencyFormatter.format(cart.subtotal()),
            ),
            _SummaryRow(
              label: 'Tax',
              value: currencyFormatter.format(cart.tax(taxRate)),
            ),
            _SummaryRow(
              label: 'Grand Total',
              value: currencyFormatter.format(cart.total(taxRate)),
              emphasized: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCheckout == null || cart.isProcessing
                    ? null
                    : () {
                        onCheckout!.call();
                      },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  cart.isProcessing ? 'Processing...' : 'Process Sale',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
