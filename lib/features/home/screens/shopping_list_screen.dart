import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with TickerProviderStateMixin {
  List<String> _items = [];
  List<bool> _checkedItems = [];
  final TextEditingController _controller = TextEditingController();
  late AnimationController _addButtonController;
  late Animation<double> _addButtonAnimation;

  @override
  void initState() {
    super.initState();
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _addButtonAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _addButtonController, curve: Curves.easeInOut),
    );
    _loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    _addButtonController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items = prefs.getStringList('shopping_list') ?? [];
      _checkedItems = List.filled(_items.length, false, growable: true);
    });
  }

  Future<void> _addItem(String item) async {
    if (item.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items.add(item);
      _checkedItems.add(false);
    });
    await prefs.setStringList('shopping_list', _items);
    _controller.clear();
    HapticFeedback.lightImpact();
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final removedItem = _items[index];
    setState(() {
      _items.removeAt(index);
      _checkedItems.removeAt(index);
    });
    await prefs.setStringList('shopping_list', _items);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบ "$removedItem" แล้ว'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'ยกเลิก',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _items.insert(index, removedItem);
                _checkedItems.insert(index, false);
              });
              await prefs.setStringList('shopping_list', _items);
            },
          ),
        ),
      );
    }
  }

  void _toggleCheck(int index) {
    setState(() {
      _checkedItems[index] = !_checkedItems[index];
    });
    HapticFeedback.selectionClick();
  }

  int get _completedCount => _checkedItems.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.greenGradient,
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'รายการจ่ายตลาด 🛒',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.greenGradient,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: 0.3,
                      child: Icon(
                        Icons.shopping_cart,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Progress bar and input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress indicator
                  if (_items.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ความคืบหน้า',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$_completedCount / ${_items.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _items.isEmpty
                                  ? 0
                                  : _completedCount / _items.length,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Input field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'เพิ่มรายการ (เช่น หมูสับ 200g)',
                              prefixIcon: const Icon(Icons.edit_outlined,
                                  color: AppTheme.primaryGreen),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color ??
                                  Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: _addItem,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTapDown: (_) => _addButtonController.forward(),
                          onTapUp: (_) {
                            _addButtonController.reverse();
                            _addItem(_controller.text);
                          },
                          onTapCancel: () => _addButtonController.reverse(),
                          child: ScaleTransition(
                            scale: _addButtonAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: AppTheme.greenGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(46, 204, 113, 0.4),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shopping list items
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _ShoppingListItem(
                      item: _items[index],
                      isChecked: _checkedItems[index],
                      index: index,
                      onToggle: () => _toggleCheck(index),
                      onDelete: () => _removeItem(index),
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
                  AppTheme.accentYellow.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: AppTheme.primaryGreen.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ยังไม่มีรายการที่จะซื้อ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'พิมพ์วัตถุดิบที่ต้องการด้านบน',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListItem extends StatelessWidget {
  final String item;
  final bool isChecked;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingListItem({
    required this.item,
    required this.isChecked,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key('$item-$index'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isChecked ? AppTheme.greenGradient : null,
                  border: isChecked
                      ? null
                      : Border.all(color: AppTheme.primaryGreen, width: 2),
                ),
                child: isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            title: Text(
              item,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? Colors.grey[400] : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[300],
              ),
              onPressed: onDelete,
            ),
          ),
        ),
      ),
    );
  }
}
