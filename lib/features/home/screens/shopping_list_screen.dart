import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../services/shopping_service.dart';
import '../models/shopping_model.dart';
import '../models/food_model.dart'; // For UnitModel
import '../../../data/repositories/recipe_repository.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _shoppingService = ShoppingService();
  List<ShoppingListModel> _shoppingLists = [];
  List<UnitModel> _units = [];
  bool _isLoading = false;
  bool _isMarketMode = true; // true = market, false = recipe

  // Filtered lists based on current tab
  List<ShoppingListModel> get _filteredLists {
    final type = _isMarketMode ? 'market' : 'recipe';
    return _shoppingLists.where((list) => list.shoppingType == type).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Units
      final units = await context.read<RecipeRepository>().getUnits();
      _units = units;

      // 2. Fetch Lists
      await _refreshLists();
    } catch (e) {
      if (mounted) _showError('ไม่สามารถโหลดข้อมูลได้: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLists() async {
    try {
      final lists = await _shoppingService.getAllShoppingLists();
      print('Fetched ${lists.length} shopping lists'); // Debug log

      // Sort items: Unchecked first, Checked last
      for (var list in lists) {
        list.items.sort((a, b) {
          if (a.isCheck != b.isCheck) {
            return a.isCheck ? 1 : -1; // Unchecked (false) before Checked (true)
          }
          return a.itemId.compareTo(b.itemId); // Keep stable order
        });
      }

      if (mounted) {
        setState(() {
          _shoppingLists = lists;
        });
      }
    } catch (e) {
      print('Error refreshing lists: $e');
    }
  }

  Future<void> _createShoppingList() async {
    final TextEditingController nameController = TextEditingController();
    // Default type based on current tab
    String selectedType = _isMarketMode ? 'market' : 'recipe';
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        title: Text('สร้างรายการ${_isMarketMode ? "ตลาด" : "สูตรอาหาร"}ใหม่', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18.sp)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'ชื่อรากการ (เช่น ตลาดสด, เมนูเย็นนี้)',
            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 14.sp),
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12.scale),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _shoppingService.createNewShoppingList(
                    shoppingType: selectedType,
                    listName: nameController.text,
                  );
                  // Wait for backend to propagate
                  await Future.delayed(const Duration(seconds: 1));
                  await _refreshLists();
                } catch (e) {
                  _showError('สร้างรายการไม่สำเร็จ');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMarketMode ? AppTheme.primaryGreen : AppTheme.primaryOrange,
              foregroundColor: Colors.white
            ),
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(int listId, String name, double qty, int unitId) async {
    setState(() => _isLoading = true);
    try {
      await _shoppingService.addItemToShoppingList(
        itemName: name,
        quantity: qty,
        unitId: unitId,
        shoppingListId: listId,
      );
      // Wait for backend to propagate
      await Future.delayed(const Duration(seconds: 1));
      await _refreshLists();
    } catch (e) {
      _showError('เพิ่มรายการไม่สำเร็จ');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCheck(ShoppingItemModel item) async {
    HapticFeedback.selectionClick();
    // Optimistic update (optional, but let's stick to safe refresh for now)
    try {
      final success = await _shoppingService.updateShoppingItemStatus(item.itemId, !item.isCheck);
      if (success) {
        await _refreshLists();
      } else {
         _showError('อัปเดตสถานะไม่สำเร็จ (API Fail)');
      }
    } catch (e) {
      _showError('อัปเดตสถานะไม่สำเร็จ');
    }
  }

  void _showItemDialog({ShoppingItemModel? item, int? listId}) {
    if (listId == null && item == null) return;
    
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.itemName ?? '');
    final qtyController = TextEditingController(text: item?.quantity.toStringAsFixed(0) ?? '1');
    
    int? selectedUnitId = item?.unitId;
    // Default unit logic
    if ((selectedUnitId == null || selectedUnitId == 0) && _units.isNotEmpty) {
       selectedUnitId = _units.first.unitId;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // to allow custom decoration inside
      builder: (context) {
        final isDarkMode = context.read<ThemeCubit>().isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.scale)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            top: 20.h, left: 20.w, right: 20.w
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
             return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16.sp),
                    decoration: InputDecoration(
                      labelText: 'ชื่อวัตถุดิบ', 
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12.scale),
                    ),
                    enabled: !isEditing, 
                  ),
                SizedBox(height: 12.h),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                          controller: qtyController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16.sp),
                          decoration: InputDecoration(
                            labelText: 'จำนวน', 
                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.scale),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedUnitId,
                          isExpanded: true,
                          dropdownColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16.sp),
                          decoration: InputDecoration(
                            labelText: 'หน่วย', 
                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                          ),
                        items: _units.map((u) => DropdownMenuItem(value: u.unitId, child: Text(u.unitName, style: TextStyle(fontSize: 14.sp)))).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedUnitId = val);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    Navigator.pop(context);

                    if (isEditing) {
                       final quantity = double.tryParse(qtyController.text) ?? 1.0;
                       
                       // Parallel or sequential updates
                       if (quantity != item.quantity) {
                          await _shoppingService.updateShoppingItemQuantity(item.itemId, quantity);
                       }
                       if (selectedUnitId != null && selectedUnitId != item.unitId) {
                          await _shoppingService.updateShoppingItemUnit(item.itemId, selectedUnitId!);
                       }
                       await _refreshLists();
                    } else {
                       await _addItem(
                         listId!, 
                         nameController.text.trim(), 
                         double.tryParse(qtyController.text) ?? 1.0, 
                         selectedUnitId ?? 0
                       );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
                  ),
                  child: Text(isEditing ? 'บันทึก' : 'เพิ่มรายการ', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            );
          }
        ),
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildModeToggle({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12.scale),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4.scale, offset: Offset(0, 2.h))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.scale, color: isSelected ? (label == 'ตลาด' ? AppTheme.brandBlue : AppTheme.brandPurple) : Colors.grey),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    final filtered = _filteredLists;
    final activeColor = _isMarketMode ? AppTheme.brandBlue : AppTheme.brandPurple;
    final activeGradient = isDarkMode ? AppTheme.brandGradientDark : AppTheme.brandGradient;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshLists,
        color: activeColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 100.h,
              floating: true,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: activeGradient),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    _isMarketMode 
                      ? 'รายการจ่ายตลาด (${filtered.length}) 🛒' 
                      : 'รายการจากสูตร (${filtered.length}) 📝',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white),
                  ),
                ),
              ),
            ),

            // Tab Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Container(
                  padding: EdgeInsets.all(4.scale),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15.scale),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModeToggle(
                          label: 'ตลาด',
                          icon: Icons.store,
                          isSelected: _isMarketMode,
                          onTap: () => setState(() => _isMarketMode = true),
                        ),
                      ),
                      Expanded(
                        child: _buildModeToggle(
                          label: 'สูตรอาหาร',
                          icon: Icons.menu_book,
                          isSelected: !_isMarketMode,
                          onTap: () => setState(() => _isMarketMode = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_isLoading && _shoppingLists.isEmpty)
             const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
             SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16.scale),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final list = filtered[index];
                    return _buildShoppingListCard(list);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
            
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createShoppingList,
        backgroundColor: activeColor,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text(
          _isMarketMode ? 'สร้างรายการตลาด' : 'สร้างรายการสูตร',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Track which lists are in "Edit Mode"
  final Map<int, bool> _editingLists = {};

  Widget _buildShoppingListCard(ShoppingListModel list) {
    final isEditing = _editingLists[list.shoppingListId] ?? false;
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        borderRadius: BorderRadius.circular(15.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10.scale,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.scale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.scale),
                  decoration: BoxDecoration(
                    color: (list.shoppingType == 'recipe' ? AppTheme.brandPurple : AppTheme.brandBlue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    list.shoppingType == 'recipe' ? Icons.menu_book : Icons.store,
                    color: list.shoppingType == 'recipe' ? AppTheme.brandPurple : AppTheme.brandBlue,
                    size: 24.scale,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                   child: Text(
                    list.listName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                
                // Edit / Done / Delete List Button
                if (isEditing)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete ENTIRE List Button (Only in Edit Mode)
                      TextButton(
                        onPressed: () => _confirmDeleteList(list),
                        child: Text('ลบรายการ', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                      ),
                      SizedBox(width: 8.w),
                      // Done Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingLists[list.shoppingListId] = false;
                          });
                        },
                        child: Text('เสร็จสิ้น', style: TextStyle(color: list.shoppingType == 'recipe' ? AppTheme.brandPurple : AppTheme.brandBlue, fontSize: 14.sp)),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingLists[list.shoppingListId] = true;
                      });
                    },
                    child: Text('แก้ไข', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Items
          if (list.items.isEmpty)
             Padding(
              padding: EdgeInsets.all(24.scale),
              child: Center(child: Text('ยังไม่มีรายการในตระกร้านี้', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 14.sp))),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: list.items.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 60.w),
              itemBuilder: (context, index) {
                final item = list.items[index];
                return InkWell(
                  onTap: isEditing ? null : () => _showItemDialog(item: item), // Disable edit dialog in edit mode
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: item.isCheck ? 0.5 : 1.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          // Checkbox (Hide in Edit Mode)
                          if (!isEditing)
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: item.isCheck,
                                activeColor: AppTheme.primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => _toggleCheck(item),
                              ),
                            )
                          else
                            const SizedBox(width: 24), // Keep spacing or remove

                          const SizedBox(width: 16),
                          
                          // Image placeholder
                          Container(
                            width: 50.scale,
                            height: 50.scale,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.scale),
                              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.fastfood, 
                                size: 20.scale, 
                                color: isDarkMode ? Colors.white54 : Colors.grey[400]
                              )
                            ),
                          ),
                          SizedBox(width: 16.w),
                          
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    decoration: item.isCheck ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4.scale),
                                  ),
                                  child: Text(
                                    '${item.quantity.toStringAsFixed(0)} ${item.unitName ?? 'หน่วย'}',
                                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[600], fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Delete Item Button (Only in Edit Mode)
                          if (isEditing)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.deepOrange, size: 24.scale),
                              onPressed: () => _confirmDeleteItem(item),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          const Divider(height: 1),
          
          // Footer Action (Hide Add Item in Edit Mode?)
          if (!isEditing)
            InkWell(
              onTap: () => _showItemDialog(listId: list.shoppingListId),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15.scale)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: list.shoppingType == 'recipe' ? AppTheme.brandPurple : AppTheme.brandBlue, size: 20.scale),
                    SizedBox(width: 8.w),
                    Text(
                      'เพิ่มวัตถุดิบลงในรายการนี้',
                      style: TextStyle(
                        color: list.shoppingType == 'recipe' ? AppTheme.brandPurple : AppTheme.brandBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteList(ShoppingListModel list) async {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        title: Text('ลบรายการ?', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18.sp)),
        content: Text('คุณต้องการลบรายการ "${list.listName}" ใช่หรือไม่?', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก', style: TextStyle(fontSize: 14.sp))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 14.sp))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _shoppingService.deleteShoppingList(list.shoppingListId);
        await Future.delayed(const Duration(milliseconds: 500));
        await _refreshLists();
      } catch (e) {
        _showError('ลบรายการไม่สำเร็จ');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDeleteItem(ShoppingItemModel item) async {
     // Direct delete or confirm? Assuming direct for speed or confirm for safety. Let's do confirm.
     final isDarkMode = context.read<ThemeCubit>().isDarkMode;
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        title: Text('ลบสินค้า?', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18.sp)),
        content: Text('คุณต้องการลบ "${item.itemName}" ใช่หรือไม่?', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก', style: TextStyle(fontSize: 14.sp))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 14.sp))),
        ],
      ),
    );

    if (confirm == true) {
       // Optimistic UI update could be good here, but let's stick to refresh for safety
      try {
        await _shoppingService.deleteItemFromShoppingList(item.itemId);
        await _refreshLists();
      } catch (e) {
        _showError('ลบสินค้าไม่สำเร็จ');
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80.scale, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text('ยังไม่มีรายการซื้อของ', style: TextStyle(fontSize: 18.sp, color: Colors.grey[600])),
          SizedBox(height: 8.h),
          Text('กด "สร้างรายการใหม่" เพื่อเริ่มใช้งาน', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        ],
      ),
    );
  }
}

