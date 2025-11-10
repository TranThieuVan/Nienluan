// [FILE MỚI: lib/screens/manager/employee_detail_screen.dart]

import 'package:flutter/material.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/widgets/manager/edit_employee_dialog.dart';
import 'package:myshop/services/pocketbase_service.dart'; // Cần cho hàm callback
import 'package:myshop/models/staff_role.dart'; // Cần cho hàm callback

class EmployeeDetailScreen extends StatefulWidget {
  final StaffProfile profile;
  // Callback để khi sửa xong, màn hình trước (management) có thể tải lại
  final VoidCallback onProfileUpdated;
  // Callback cho hàm Sửa
  final UpdateStaffDetailsCallback onUpdateDetails;

  const EmployeeDetailScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    required this.onUpdateDetails,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late StaffProfile _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  // Hàm hiển thị Dialog Sửa
  void _showEditEmployeeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EditEmployeeDialog(
          profile: _currentProfile,
          onUpdate:
              ({
                required String profileId,
                required String name,
                required StaffRole role,
                required double salary,
                required String status,
                String? userId,
                String? newEmail,
                String? newPassword,
              }) async {
                // 1. Gọi hàm update service
                await widget.onUpdateDetails(
                  profileId: profileId,
                  name: name,
                  role: role,
                  salary: salary,
                  status: status,
                  userId: userId,
                  newEmail: newEmail,
                  newPassword: newPassword,
                );

                // 2. Tải lại thông tin mới từ DB
                final pbService = PocketBaseService.instance;
                final updatedProfile = await pbService.users
                    .getStaffProfileForUser(
                      _currentProfile.userId ?? profileId,
                    );

                // 3. Cập nhật UI của màn hình này
                setState(() {
                  _currentProfile = updatedProfile;
                });

                // 4. Báo cho màn hình management tải lại
                widget.onProfileUpdated();
              },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProfile.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [_buildHeader(), _buildInfoCard(), _buildScheduleCard()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEditEmployeeDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Chỉnh sửa'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.indigo.shade200,
            child: Text(
              _currentProfile.name.isNotEmpty ? _currentProfile.name[0] : '?',
              style: const TextStyle(fontSize: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentProfile.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentProfile.role.display,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.badge,
              label: 'Trạng thái',
              value: _currentProfile.status,
            ),
            _InfoRow(
              icon: Icons.email,
              label: 'Email đăng nhập',
              value: _currentProfile.email,
            ),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Lương',
              value: '${_currentProfile.salary.toStringAsFixed(0)} VND',
            ),
            _InfoRow(
              icon: Icons.perm_identity,
              label: 'Profile ID',
              value: _currentProfile.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch cố định',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.work_history,
              label: 'Hình thức',
              value: _currentProfile.workType,
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày làm',
              value: _currentProfile.defaultDays.join(', '),
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Ca làm',
              value: _currentProfile.defaultShifts.join(', '),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget helper
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade300, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
