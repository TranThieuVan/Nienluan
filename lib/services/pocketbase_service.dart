import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PocketBaseService {
  final pb = PocketBase(
    dotenv.env['POCKETBASE_URL'] ?? 'http://127.0.0.1:8091',
  );

  Future<void> login(String email, String password) async {
    try {
      await pb.collection('_pb_users_auth_').authWithPassword(email, password);
      // user info bây giờ lưu trong pb.authStore.model
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  String getRole() {
    // Lấy role từ user hiện tại
    return pb.authStore.model?.getStringValue('role') ?? '';
  }

  void logout() {
    pb.authStore.clear();
  }
}
