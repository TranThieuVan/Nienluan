import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final String name;
  final double price;

  MenuItemCard({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('${price.toStringAsFixed(0)} VND'),
      ),
    );
  }
}
