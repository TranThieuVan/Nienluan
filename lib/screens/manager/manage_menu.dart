import 'package:flutter/material.dart';

class ManageMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý món ăn")),
      body: Center(child: Text("CRUD món ăn")),
    );
  }
}
