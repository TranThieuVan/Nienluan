import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final pb = PocketBase(
    dotenv.env['POCKETBASE_URL'] ?? 'http://127.0.0.1:8090',
  );

  // Login user với email/password
  Future<bool> login(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      print('Login success: ${pb.authStore.model?.id}');
      return true;
    } catch (e) {
      print('Login failed: $e');
      return false;
    }
  }

  // Logout user
  void logout() {
    pb.authStore.clear();
  }

  // Kiểm tra user đã login chưa
  bool get isLoggedIn => pb.authStore.isValid;
}
