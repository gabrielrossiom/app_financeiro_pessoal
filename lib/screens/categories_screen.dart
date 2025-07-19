import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/providers.dart';
import '../models/models.dart' as models;
import '../utils/utils.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<models.Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<FinanceProvider>();
      final categories = await provider.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        onSave: (category) async {
          try {
            final provider = context.read<FinanceProvider>();
            await provider.addCategory(category);
            await _loadCategories();
            
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categoria adicionada com sucesso!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao adicionar categoria: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditCategoryDialog(models.Category category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (updatedCategory) async {
          try {
            final provider = context.read<FinanceProvider>();
            await provider.updateCategory(updatedCategory);
            await _loadCategories();
            
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categoria atualizada com sucesso!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao atualizar categoria: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(models.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir a categoria "${category.name}"?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<FinanceProvider>();
        await provider.deleteCategory(category.id);
        await _loadCategories();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoria excluída com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir categoria: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma categoria encontrada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque no + para adicionar uma categoria',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding inferior para o FAB
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(_categories[index], true);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(models.Category category, bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
          child: Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: category.monthlyBudget != null
            ? Text(
                'Orçamento: ${Formatters.formatCurrency(category.monthlyBudget!)}',
                style: TextStyle(color: Colors.grey[600]),
              )
            : null,
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditCategoryDialog(category);
                      break;
                    case 'delete':
                      _deleteCategory(category);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final models.Category? category;
  final Function(models.Category) onSave;

  const _CategoryDialog({
    this.category,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _selectedIcon = '📁';
  Color _selectedColor = Colors.blue;
  bool _isActive = true;

  final List<String> _availableIcons = [
    '📁', '🏠', '🍽️', '🚗', '📚', '🎮', '🏥', '👕', '🔧', '💰', '🎁', '🏢',
    '🍕', '☕', '🎬', '✈️', '🏖️', '🎵', '📱', '💻', '🎨', '🏃', '🧘', '📖',
    '🛒', '💊', '🎓', '🏦', '💳', '📊', '🎯', '⭐', '🔥', '💡', '🔑', '🎪',
    '🏈', '⚽', '🎾', '🏀', '🏓', '🎸', '🎹', '🎤', '🎭', '🎨', '📷', '🎥',
    '🌍', '🌙', '☀️', '🌈', '🌸', '🌺', '🌻', '🌹', '🍀', '🌴', '🌳', '🌵',
    '🍎', '🍌', '🍇', '🍓', '🍊', '🍋', '🥑', '🥕', '🥬', '🥩', '🍗', '🐟',
    '🥛', '🧀', '🍞', '🥐', '🍰', '🍪', '🍦', '🍺', '🍷', '🥤', '🧃', '☕',
    '🚌', '🚲', '🛵', '🚁', '🚢', '🚅', '🚇', '🚀', '🎠', '🎡', '🎢', '🎪',
    '🏛️', '🏰', '🏯', '🗼', '🗽', '⛪', '🕌', '🕍', '⛩️', '🕋', '⛺', '🏕️',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _budgetController.text = widget.category!.monthlyBudget?.toString() ?? '';
      _selectedIcon = widget.category!.icon;
      _selectedColor = Color(int.parse(widget.category!.color.replaceAll('#', '0xFF')));
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final color = '#${_selectedColor.value.toRadixString(16).substring(2)}';

    final category = models.Category(
      id: widget.category?.id,
      name: name,
      icon: _selectedIcon,
      color: color,
      monthlyBudget: budget > 0 ? budget : null,
      isActive: _isActive,
      createdAt: widget.category?.createdAt,
    );

    widget.onSave(category);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Escolher cor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Escolher ícone',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIcon = icon);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    
    return AlertDialog(
      title: Text(
        isEditing ? 'Editar Categoria' : 'Nova Categoria',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da categoria',
                  prefixIcon: Icon(Icons.label, size: 20),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Orçamento mensal
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Orçamento mensal *',
                  prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                  border: OutlineInputBorder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  '* Opcional',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Cor
              const Text('Cor da categoria', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 48, // Mesmo tamanho do TextFormField
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _showColorPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Toque para escolher a cor'),
                      const Spacer(),
                      const Icon(Icons.color_lens, size: 20),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Ícone
              const Text('Ícone da categoria', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 48, // Mesmo tamanho do TextFormField
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _showIconPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            _selectedIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Toque para escolher o ícone'),
                      const Spacer(),
                      const Icon(Icons.emoji_emotions, size: 20),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
} 