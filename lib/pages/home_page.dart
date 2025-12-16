import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import '../presentation/widgets/budget_card.dart';
import '../data/models/budget_model.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  List<Map<String, dynamic>> _transactions = [];
  List<Budget> _budgets = [];
  bool _isLoading = false;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetTitleController = TextEditingController();
  final _budgetAmountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getUser();
    _fetchTransactions();
    _fetchBudgetsAfterUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _budgetTitleController.dispose();
    _budgetAmountController.dispose();
    super.dispose();
  }

  void _getUser() {
    setState(() {
      _user = supabase.auth.currentUser;
    });
  }

  Future<void> _fetchBudgetsAfterUser() async {
    // Wait a bit to ensure user is set
    await Future.delayed(const Duration(milliseconds: 100));
    if (_user == null) {
      _user = supabase.auth.currentUser;
    }
    await _fetchBudgets();
  }

  Future<void> _pickImageForTransaction() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<String?> _uploadTransactionImage() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('notes-images').uploadBinary(fileName, bytes);

      final publicUrl = supabase.storage
          .from('notes-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      return null;
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchBudgets() async {
    if (_user == null) {
      print('DEBUG: User is null, skipping budget fetch');
      return;
    }

    try {
      print('DEBUG: Fetching budgets for user: ${_user!.id}');
      final data = await supabase
          .from('budgets')
          .select()
          .eq('user_id', _user!.id)
          .order('created_at', ascending: false);

      print('DEBUG: Budgets fetched: ${data.length} budgets');
      setState(() {
        _budgets = (data as List).map((e) => Budget.fromJson(e)).toList();
      });
    } catch (e) {
      // Table might not exist yet, show error for debugging
      print('DEBUG: Error fetching budgets: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Budget info: $e')));
      }
    }
  }

  Future<void> _createTransaction() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and amount are required.')),
      );
      return;
    }

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadTransactionImage();
      }

      await supabase.from('transactions').insert({
        'title': _titleController.text,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'image_url': imageUrl,
        'user_id': _user?.id,
      });

      _titleController.clear();
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );
      }

      _fetchTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateTransaction(
    int id,
    String title,
    double amount,
    String description,
  ) async {
    try {
      await supabase
          .from('transactions')
          .update({
            'title': title,
            'amount': amount,
            'description': description,
          })
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully!')),
        );
      }

      _fetchTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await supabase.from('transactions').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully!')),
        );
      }

      _fetchTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddDialog() {
    setState(() {
      _selectedImage = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _pickImageForTransaction();
                  setState(() {});
                },
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedImage == null ? 'Pick Image' : 'Change Image',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createTransaction,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    _titleController.text = transaction['title'] ?? '';
    _amountController.text = transaction['amount'].toString();
    _descriptionController.text = transaction['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _titleController.clear();
              _amountController.clear();
              _descriptionController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateTransaction(
                transaction['id'],
                _titleController.text,
                double.parse(_amountController.text),
                _descriptionController.text,
              );
              Navigator.pop(context);
              _titleController.clear();
              _amountController.clear();
              _descriptionController.clear();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    _budgetTitleController.clear();
    _budgetAmountController.clear();
    String selectedPeriod = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _budgetTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _budgetAmountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedPeriod = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_budgetTitleController.text.isEmpty ||
                    _budgetAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final now = DateTime.now();
                DateTime startDate = now;
                DateTime endDate;

                if (selectedPeriod == 'daily') {
                  endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                } else if (selectedPeriod == 'weekly') {
                  endDate = now.add(const Duration(days: 7));
                } else {
                  endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                }

                try {
                  await supabase.from('budgets').insert({
                    'title': _budgetTitleController.text,
                    'amount': double.parse(_budgetAmountController.text),
                    'period': selectedPeriod,
                    'start_date': startDate.toIso8601String(),
                    'end_date': endDate.toIso8601String(),
                    'user_id': _user?.id,
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget added successfully!'),
                      ),
                    );
                  }

                  await _fetchBudgets();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
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
    final totalExpense = _transactions.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num),
    );
    final formattedTotalExpense = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalExpense);

    // Calculate spent amount for current month's budget
    final now = DateTime.now();
    final monthlySpent = _transactions
        .where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return createdAt.year == now.year && createdAt.month == now.month;
        })
        .fold<double>(
          0,
          (sum, item) => sum + (item['amount'] as num).toDouble(),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendSense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchTransactions();
                await _fetchBudgets();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Expenses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedTotalExpense,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Budget Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _budgets.isEmpty
                          ? BudgetCard(
                              title: 'Monthly',
                              amount: 100000,
                              spent: monthlySpent,
                              period: 'monthly',
                              onManage: () {
                                // TODO: Implement manage budgets page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Manage budgets coming soon!',
                                    ),
                                  ),
                                );
                              },
                              onAddBudget: _showAddBudgetDialog,
                            )
                          : BudgetCard(
                              title: _budgets.first.title,
                              amount: _budgets.first.amount,
                              spent: monthlySpent,
                              period: _budgets.first.period,
                              onManage: () {
                                // TODO: Implement manage budgets page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Manage budgets coming soon!',
                                    ),
                                  ),
                                );
                              },
                              onAddBudget: _showAddBudgetDialog,
                            ),
                    ),
                  ),
                  _transactions.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 50),
                              child: Text(
                                'No transactions yet.\nAdd a new one!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final transaction = _transactions[index];
                            final imageUrl = transaction['image_url'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const SizedBox(
                                                height: 200,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                        errorBuilder: (context, error, trace) {
                                          return const SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      transaction['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      transaction['description'] ?? '',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'id_ID',
                                            symbol: 'Rp ',
                                            decimalDigits: 0,
                                          ).format(transaction['amount']),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: () =>
                                              _showEditDialog(transaction),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _deleteTransaction(
                                            transaction['id'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }, childCount: _transactions.length),
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Add Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
