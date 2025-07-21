import 'package:flutter/material.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Configurações',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Em desenvolvimento...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.category),
              label: Text('Gerenciar Categorias'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 