import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final double? monthlyBudget;
  final bool isActive;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.color,
    this.monthlyBudget,
    this.isActive = true,
    this.isCustom = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Categorias padrão do sistema
  static List<Category> get defaultCategories => [
    Category(
      name: 'Moradia',
      icon: '🏠',
      color: '#FF6B6B',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Alimentação',
      icon: '🍽️',
      color: '#4ECDC4',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Transporte',
      icon: '🚗',
      color: '#45B7D1',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Educação',
      icon: '📚',
      color: '#96CEB4',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Lazer',
      icon: '🎮',
      color: '#FFEAA7',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Saúde',
      icon: '🏥',
      color: '#DDA0DD',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Vestuário',
      icon: '👕',
      color: '#FFB6C1',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Serviços',
      icon: '🔧',
      color: '#98D8C8',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Salário',
      icon: '💰',
      color: '#32CD32',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Benefício',
      icon: '🎁',
      color: '#FFD700',
      monthlyBudget: 0,
    ),
    Category(
      name: 'Aluguel',
      icon: '🏢',
      color: '#87CEEB',
      monthlyBudget: 0,
    ),
  ];

  // Método para copiar com alterações
  Category copyWith({
    String? name,
    String? icon,
    String? color,
    double? monthlyBudget,
    bool? isActive,
    bool? isCustom,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Conversão para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'monthlyBudget': monthlyBudget,
      'isActive': isActive ? 1 : 0,
      'isCustom': isCustom ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Criação a partir de Map (do banco de dados)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      monthlyBudget: map['monthlyBudget'],
      isActive: map['isActive'] == 1,
      isCustom: map['isCustom'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
} 