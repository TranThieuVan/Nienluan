import 'package:flutter/material.dart';

class TableCard extends StatelessWidget {
  final String tableName;
  final int capacity;

  TableCard({required this.tableName, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(tableName),
        subtitle: Text('Sức chứa: $capacity người'),
      ),
    );
  }
}
