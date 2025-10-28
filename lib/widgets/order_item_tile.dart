import 'package:flutter/material.dart';

class OrderItemTile extends StatelessWidget {
  final String itemName;
  final int quantity;

  OrderItemTile({required this.itemName, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(itemName), trailing: Text('x$quantity'));
  }
}
