import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
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
        
        // Sort items by expiration date
        items.sort((a, b) {
          // Both have dates
          if (a.expireDate != null && a.expireDate!.isNotEmpty && 
              b.expireDate != null && b.expireDate!.isNotEmpty) {
            final dateA = DateTime.parse(a.expireDate!);
            final dateB = DateTime.parse(b.expireDate!);
            return dateA.compareTo(dateB);
          }
          // A has date, B doesn't -> A comes first
          if (a.expireDate != null && a.expireDate!.isNotEmpty) {
            return -1;
          }
          // B has date, A doesn't -> B comes first
          if (b.expireDate != null && b.expireDate!.isNotEmpty) {
            return 1;
          }
          // Neither has date
          return 0;
        });

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
        title: Text('ลบวัตถุดิบ', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบ "${item.itemName}" ใช่หรือไม่?', style: TextStyle(fontSize: 16.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ยกเลิก', style: TextStyle(fontSize: 14.sp))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('ลบ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
            SnackBar(content: Text('ลบวัตถุดิบเรียบร้อยแล้ว', style: TextStyle(fontSize: 14.sp))),
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
      builder: (ctx) {
        final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.scale)),
            backgroundColor: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
            child: Container(
              padding: EdgeInsets.all(24.scale),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.scale),
                color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                   Text(
                      item == null ? 'เพิ่มวัตถุดิบ 🥦' : 'แก้ไขวัตถุดิบ ✏️',
                      style: TextStyle(
                        fontSize: 24.sp, 
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                  
                    // Item Name Field with Autocomplete
                    _buildLabel('ชื่อวัตถุดิบ', isDarkMode),
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
                            isDarkMode: isDarkMode,
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
                  SizedBox(height: 20.h),
                  
                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('จำนวน', isDarkMode),
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                hintText: '0',
                                prefixIcon: Icons.scale_outlined,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Unit selection
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('หน่วย', isDarkMode),
                            DropdownButtonFormField<int>(
                              value: selectedUnitId == 0 && _units.isNotEmpty ? _units.first.unitId : (selectedUnitId != 0 ? selectedUnitId : null),
                              isExpanded: true,
                                decoration: _buildInputDecoration(
                                  prefixIcon: Icons.unfold_more_outlined,
                                  isDarkMode: isDarkMode,
                                ),
                              items: _units.map((u) => DropdownMenuItem(
                                value: u.unitId,
                                child: Text(u.unitName, style: TextStyle(fontSize: 14.sp)),
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedUnitId = val!),
                              hint: Text('เลือกหน่วย', style: TextStyle(fontSize: 14.sp)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  
                  // Storage Location
                  _buildLabel('ที่เก็บ', isDarkMode),
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      isExpanded: true,
                        decoration: _buildInputDecoration(
                          prefixIcon: Icons.place_outlined,
                          isDarkMode: isDarkMode,
                        ),
                      items: _locations.map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(_locationDisplayNames[loc] ?? loc, style: TextStyle(fontSize: 14.sp)),
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
                      icon: Icon(Icons.arrow_drop_down_circle_outlined, size: 20.scale),
                    ),
                  SizedBox(height: 20.h),
                  
                  // Expiry Date picker toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('ระบุวันหมดอายุ', isDarkMode),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: hasExpiryDate,
                          onChanged: (val) => setDialogState(() => hasExpiryDate = val),
                          activeColor: AppTheme.brandPurple,
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
                                  primary: AppTheme.brandPurple,
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.scale),
                          border: Border.all(
                            color: selectedDate == null && hasExpiryDate 
                                ? Colors.red.shade300 
                                : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                          ),
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: AppTheme.brandPurple, size: 20.scale),
                            SizedBox(width: 12.w),
                              Text(
                                selectedDate != null 
                                  ? DateFormat.yMMMd('th').format(selectedDate!)
                                  : 'เลือกวันที่',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: selectedDate != null 
                                      ? (isDarkMode ? Colors.white : Colors.black) 
                                      : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ),
                            const Spacer(),
                            Icon(Icons.edit_calendar_outlined, size: 18.scale, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (selectedDate == null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: Text('กรุณาระบุวันหมดอายุ', style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                      ),
                  ],
                  
                  SizedBox(height: 32.h),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
                          ),
                          child: Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
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
                            backgroundColor: AppTheme.brandPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
                            elevation: 0,
                          ),
                          child: Text(
                            item == null ? 'เพิ่มวัตถุดิบ' : 'บันทึกการแก้ไข',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
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
        );
      },
    );
  }

  Widget _buildLabel(String text, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? prefixIcon, bool isDarkMode = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.grey.shade400, fontSize: 14.sp),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDarkMode ? Colors.grey.shade400 : AppTheme.brandPurple, size: 20.scale) : null,
      filled: true,
      fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 70.h,
        title: Text('จัดการวัตถุดิบ 🧊', style: TextStyle(fontSize: 20.sp)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
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
        backgroundColor: AppTheme.brandPurple,
        child: Icon(Icons.add, color: Colors.white, size: 28.scale),
      ),
    );
  }

  Widget _buildStockList(String location) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    final items = _stockByLocation[location] ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64.scale, color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text(
              'ไม่มีวัตถุดิบใน ${_locationDisplayNames[location] ?? location}',
              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllStocks,
      child: ListView.builder(
        padding: EdgeInsets.all(16.scale),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isExpired = item.expireDate != null && DateTime.parse(item.expireDate!).isBefore(DateTime.now());

          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
            elevation: isDarkMode ? 0 : 2,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              leading: Container(
                padding: EdgeInsets.all(12.scale),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getEmojiForItem(item.itemName),
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),
              title: Text(
                item.itemName,
                style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16.sp),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จำนวน: ${item.quantity} ${item.unitName ?? ""}',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13.sp),
                  ),
                  if (item.expireDate != null && item.expireDate!.isNotEmpty)
                    Text(
                      'หมดอายุ: ${DateFormat('dd MMM yyyy').format(DateTime.parse(item.expireDate!))}',
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.grey,
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blue, size: 20.scale),
                    onPressed: () => _showEditDialog(item),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.scale),
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
