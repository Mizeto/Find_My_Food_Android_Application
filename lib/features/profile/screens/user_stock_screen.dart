import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../home/models/food_model.dart';
import 'package:intl/intl.dart';

class UserStockScreen extends StatefulWidget {
  const UserStockScreen({super.key});

  @override
  State<UserStockScreen> createState() => _UserStockScreenState();
}

class _UserStockScreenState extends State<UserStockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _locations = ['pantry', 'fridge', 'freezer'];
  final Map<String, String> _locationDisplayNames = {
    'pantry': 'อุณหภูมิห้อง',
    'fridge': 'ช่องแช่เย็น',
    'freezer': 'ช่องแช่แข็ง',
  };
  bool _isLoading = false;
  List<UnitModel> _units = [];
  Map<String, List<UserStockModel>> _stockByLocation = {
    'pantry': [],
    'fridge': [],
    'freezer': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _locations.length, vsync: this);
    _loadAllStocks();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await context.read<RecipeRepository>().getUnits();
      if (mounted) {
        setState(() {
          _units = units;
        });
      }
    } catch (e) {
      debugPrint('Error loading units: $e');
    }
  }

  Future<void> _loadAllStocks() async {
    setState(() => _isLoading = true);
    final repo = context.read<RecipeRepository>();
    
    try {
      for (var loc in _locations) {
        final items = await repo.getUserStockByStorage(loc);
        _stockByLocation[loc] = items;
      }
    } catch (e) {
      debugPrint('Error loading stocks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(UserStockModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบวัตถุดิบ'),
        content: Text('คุณต้องการลบ "${item.itemName}" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = context.read<RecipeRepository>();
      final success = await repo.deleteUserStock(item.stockId);
      if (success) {
        _loadAllStocks();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบวัตถุดิบเรียบร้อยแล้ว')),
          );
        }
      }
    }
  }

  void _showAddDialog() {
    _showItemDialog();
  }

  void _showEditDialog(UserStockModel item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({UserStockModel? item}) {
    final nameCtrl = TextEditingController(text: item?.itemName ?? '');
    final qtyCtrl = TextEditingController(text: item?.quantity?.toString() ?? '1');
    String selectedLocation = item?.storageLocation ?? _locations[_tabController.index];
    int selectedUnitId = item?.unitId ?? (_units.isNotEmpty ? _units.first.unitId : 0);
    int? selectedIngredientId = item?.ingredientId;
    bool hasExpiryDate = item == null ? true : (item.expireDate != null && item.expireDate!.isNotEmpty);
    DateTime? selectedDate = (item?.expireDate != null && item!.expireDate!.isNotEmpty)
        ? DateTime.parse(item.expireDate!) 
        : null; // Initialize to null for new items or if no date

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                    item == null ? 'เพิ่มวัตถุดิบ 🥦' : 'แก้ไขวัตถุดิบ ✏️',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Item Name Field with Autocomplete
                  _buildLabel('ชื่อวัตถุดิบ'),
                  Autocomplete<IngredientModel>(
                    optionsBuilder: (TextEditingValue textValue) async {
                      if (textValue.text.isEmpty) return const Iterable<IngredientModel>.empty();
                      return await context.read<RecipeRepository>().getIngredientByName(textValue.text);
                    },
                    displayStringForOption: (option) => option.ingredientName,
                    onSelected: (option) async {
                      setDialogState(() {
                        nameCtrl.text = option.ingredientName;
                        selectedIngredientId = option.ingredientId;
                      });
                      
                      // Auto-fetch expiry date
                      try {
                        final repo = context.read<RecipeRepository>();
                        final expireDate = await repo.getItemExpireDate(selectedLocation, option.ingredientId);
                        if (expireDate != null && expireDate.isNotEmpty) {
                          setDialogState(() {
                            try {
                              selectedDate = DateTime.parse(expireDate);
                              hasExpiryDate = true;
                            } catch (e) {
                              debugPrint('Error parsing auto expiry date: $e');
                            }
                          });
                        }
                      } catch (e) {
                        debugPrint('Error fetching auto expiry: $e');
                      }
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      if (textController.text.isEmpty && nameCtrl.text.isNotEmpty) {
                        textController.text = nameCtrl.text;
                      }
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: _buildInputDecoration(
                          hintText: 'เช่น หมูสับ, ไข่ไก่',
                          prefixIcon: Icons.shopping_basket_outlined,
                        ),
                        enabled: item == null,
                        onChanged: (val) {
                          setDialogState(() {
                            nameCtrl.text = val;
                            selectedIngredientId = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('จำนวน'),
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                hintText: '0',
                                prefixIcon: Icons.scale_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit selection
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('หน่วย'),
                            DropdownButtonFormField<int>(
                              value: selectedUnitId == 0 && _units.isNotEmpty ? _units.first.unitId : (selectedUnitId != 0 ? selectedUnitId : null),
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                prefixIcon: Icons.unfold_more_outlined,
                              ),
                              items: _units.map((u) => DropdownMenuItem(
                                value: u.unitId,
                                child: Text(u.unitName, style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedUnitId = val!),
                              hint: const Text('เลือกหน่วย', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Storage Location
                  _buildLabel('ที่เก็บ'),
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      decoration: _buildInputDecoration(
                        prefixIcon: Icons.place_outlined,
                      ),
                      items: _locations.map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(_locationDisplayNames[loc] ?? loc, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (val) async {
                        setDialogState(() => selectedLocation = val!);
                        
                        // Re-fetch expiry if ingredient is already selected
                        if (selectedIngredientId != null) {
                          try {
                            final repo = context.read<RecipeRepository>();
                            final expireDate = await repo.getItemExpireDate(selectedLocation, selectedIngredientId!);
                            if (expireDate != null && expireDate.isNotEmpty) {
                              setDialogState(() {
                                try {
                                  selectedDate = DateTime.parse(expireDate);
                                  hasExpiryDate = true;
                                } catch (e) {
                                  debugPrint('Error parsing auto expiry date: $e');
                                }
                              });
                            }
                          } catch (e) {
                            debugPrint('Error fetching auto expiry on location change: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
                    ),
                  const SizedBox(height: 20),
                  
                  // Expiry Date picker toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('ระบุวันหมดอายุ'),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: hasExpiryDate,
                          onChanged: (val) => setDialogState(() => hasExpiryDate = val),
                          activeColor: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  
                  if (hasExpiryDate) ...[
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('th', 'TH'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryOrange,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: selectedDate == null && hasExpiryDate ? Colors.red.shade300 : Colors.grey.shade300),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryOrange, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null 
                                ? DateFormat.yMMMd('th').format(selectedDate!)
                                : 'เลือกวันที่',
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedDate != null ? Colors.black : Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_outlined, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (selectedDate == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, left: 4),
                        child: Text('กรุณาระบุวันหมดอายุ', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty) return;
                            
                            // Date validation
                            if (hasExpiryDate && selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาระบุวันหมดอายุ')),
                              );
                              return;
                            }

                            final repo = context.read<RecipeRepository>();
                            bool success = false;

                            if (item == null) {
                              success = await repo.addUserStock(UserStockRequest(
                                ingredientId: selectedIngredientId,
                                itemName: nameCtrl.text,
                                quantity: double.tryParse(qtyCtrl.text) ?? 1.0,
                                unitId: selectedUnitId,
                                expireDate: hasExpiryDate ? selectedDate?.toIso8601String().split('T')[0] : null,
                                storageLocation: selectedLocation,
                              ));
                            } else {
                              success = await repo.updateUserStock(item.stockId, UserStockUpdateRequest(
                                quantity: double.tryParse(qtyCtrl.text) ?? item.quantity,
                                unitId: selectedUnitId,
                                expireDate: hasExpiryDate ? selectedDate?.toIso8601String().split('T')[0] : null,
                                storageLocation: selectedLocation,
                              ));
                            }

                            if (success) {
                              Navigator.pop(ctx);
                              _loadAllStocks();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            item == null ? 'เพิ่มวัตถุดิบ' : 'บันทึกการแก้ไข',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primaryOrange, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการวัตถุดิบ 🧊'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: [
            Tab(text: _locationDisplayNames['pantry'], icon: const Icon(Icons.inventory_2)),
            Tab(text: _locationDisplayNames['fridge'], icon: const Icon(Icons.kitchen)),
            Tab(text: _locationDisplayNames['freezer'], icon: const Icon(Icons.ac_unit)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: _locations.map((loc) => _buildStockList(loc)).toList(),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStockList(String location) {
    final items = _stockByLocation[location] ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('ไม่มีวัตถุดิบใน ${_locationDisplayNames[location] ?? location}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllStocks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isExpired = item.expireDate != null && DateTime.parse(item.expireDate!).isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getEmojiForItem(item.itemName),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                item.itemName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('จำนวน: ${item.quantity} ${item.unitName ?? ""}'),
                   if (item.expireDate != null && item.expireDate!.isNotEmpty)
                     Text(
                       'หมดอายุ: ${DateFormat('dd MMM yyyy').format(DateTime.parse(item.expireDate!))}',
                       style: TextStyle(
                         color: isExpired ? Colors.red : Colors.grey,
                         fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                       ),
                     ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showEditDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getEmojiForItem(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('หมู') || lower.contains('pork')) return '🐷';
    if (lower.contains('ไก่') || lower.contains('chicken')) return '🍗';
    if (lower.contains('ไข่') || lower.contains('egg')) return '🥚';
    if (lower.contains('กาก') || lower.contains('rice')) return '🍚';
    if (lower.contains('ผัก') || lower.contains('veg')) return '🥦';
    if (lower.contains('น้ำ') || lower.contains('water')) return '💧';
    if (lower.contains('นม') || lower.contains('milk')) return '🥛';
    if (lower.contains('เนื้อ') || lower.contains('beef')) return '🥩';
    if (lower.contains('ปลา') || lower.contains('fish')) return '🐟';
    return '📦';
  }
}
