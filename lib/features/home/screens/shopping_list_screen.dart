import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
    String selectedType = 'market'; // Default to market
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('สร้างรายการใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'ชื่อรายการ (เช่น ตลาดสด, ซุปเปอร์)',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('ประเภท: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('ตลาด'),
                    selected: selectedType == 'market',
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedType = 'market');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('สูตรอาหาร'),
                    selected: selectedType == 'recipe',
                    selectedColor: AppTheme.primaryOrange.withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedType = 'recipe');
                    },
                  ),
                ],
              ),
            ],
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
                    // Wait for backend to propagate (Increased to 2s due to slow server)
                    await Future.delayed(const Duration(seconds: 2));
                    await _refreshLists();
                  } catch (e) {
                    _showError('สร้างรายการไม่สำเร็จ');
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
              child: const Text('สร้าง'),
            ),
          ],
        ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20, left: 20, right: 20
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
             return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อวัตถุดิบ', border: OutlineInputBorder()),
                  enabled: !isEditing, 
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(labelText: 'จำนวน', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: selectedUnitId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'หน่วย', border: OutlineInputBorder()),
                        items: _units.map((u) => DropdownMenuItem(value: u.unitId, child: Text(u.unitName))).toList(),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEditing ? 'บันทึก' : 'เพิ่มรายการ', style: const TextStyle(fontSize: 16)),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshLists,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(

            expandedHeight: 100,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('รายการจ่ายตลาด (${_shoppingLists.length}) 🛒', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
              ),
            ),
          ),
          
          if (_isLoading && _shoppingLists.isEmpty)
             const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_shoppingLists.isEmpty)
             SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final list = _shoppingLists[index];
                    return _buildShoppingListCard(list);
                  },
                  childCount: _shoppingLists.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createShoppingList,
        backgroundColor: AppTheme.primaryOrange,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('สร้างรายการใหม่', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Track which lists are in "Edit Mode"
  final Map<int, bool> _editingLists = {};

  Widget _buildShoppingListCard(ShoppingListModel list) {
    final isEditing = _editingLists[list.shoppingListId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    list.listName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                        child: const Text('ลบรายการ', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      // Done Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingLists[list.shoppingListId] = false;
                          });
                        },
                        child: const Text('เสร็จสิ้น', style: TextStyle(color: AppTheme.primaryGreen)),
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
                    child: const Text('แก้ไข', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Items
          if (list.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('ยังไม่มีรายการในตระกร้านี้', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: list.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
              itemBuilder: (context, index) {
                final item = list.items[index];
                return InkWell(
                  onTap: isEditing ? null : () => _showItemDialog(item: item), // Disable edit dialog in edit mode
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Center(child: Icon(Icons.fastfood, size: 20, color: Colors.grey[400])),
                        ),
                        const SizedBox(width: 16),
                        
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.quantity.toStringAsFixed(0)} ${item.unitName ?? 'หน่วย'}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Delete Item Button (Only in Edit Mode)
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.deepOrange),
                            onPressed: () => _confirmDeleteItem(item),
                          ),
                      ],
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'เพิ่มวัตถุดิบลงในรายการนี้',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการ?'),
        content: Text('คุณต้องการลบรายการ "${list.listName}" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red))),
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
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบสินค้า?'),
        content: Text('คุณต้องการลบ "${item.itemName}" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red))),
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
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('ยังไม่มีรายการซื้อของ', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text('กด "สร้างรายการใหม่" เพื่อเริ่มใช้งาน', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

