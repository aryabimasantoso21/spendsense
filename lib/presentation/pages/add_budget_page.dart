import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/category_model.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final SupabaseService _supabase = SupabaseService.instance;

  String _selectedPeriod = 'Monthly';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _supabase.getCategories();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter budget name')));
      return;
    }

    if (_amountController.text.isEmpty || _amountController.text == '0') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    try {
      await _supabase.addBudget(
        title: _nameController.text,
        amount: double.parse(_amountController.text),
        period: _selectedPeriod.toLowerCase(),
        categoryId: _selectedCategoryId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;
    final cardColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : AppColors.surfaceVariant;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add Budget',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('img/logo.png', height: 32),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  _buildFormField(
                    label: "Budget's Name",
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Budget's name",
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Amount Field
                  _buildFormField(
                    label: 'Amount',
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Rp 0',
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Category Field
                  _buildFormField(
                    label: 'Category',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: Text(
                          'Select Category',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                        style: TextStyle(color: textColor, fontSize: 16),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: secondaryTextColor,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories
                              .where((cat) => cat.type == 'expense')
                              .map((category) {
                                return DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              })
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Period Field
                  _buildFormField(
                    label: 'Period',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        isExpanded: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: secondaryTextColor,
                        ),
                        items: ['Daily', 'Weekly', 'Monthly'].map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Save Button
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          child,
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[800] : AppColors.border,
          ),
        ],
      ),
    );
  }
}
