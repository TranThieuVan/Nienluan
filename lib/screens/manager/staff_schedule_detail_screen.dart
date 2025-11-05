import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myshop/models/schedule_exception.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/widgets/manager/add_exception_dialog.dart';

class StaffScheduleDetailScreen extends StatefulWidget {
  final StaffProfile profile;

  const StaffScheduleDetailScreen({super.key, required this.profile});

  @override
  State<StaffScheduleDetailScreen> createState() =>
      _StaffScheduleDetailScreenState();
}

class _StaffScheduleDetailScreenState extends State<StaffScheduleDetailScreen> {
  final pbService = PocketBaseService.instance;
  late Future<List<ScheduleExceptionModel>> _exceptionsFuture;

  // Mặc định xem 30 ngày tới
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadExceptions();
  }

  Future<void> _loadExceptions() async {
    if (mounted) {
      setState(() {
        _exceptionsFuture = pbService.schedules.getScheduleExceptions(
          staffProfileId: widget.profile.id,
          startDate: _startDate,
          endDate: _endDate,
        );
      });
    }
  }

  // Hàm xử lý Thêm
  Future<void> _handleCreateException({
    required DateTime date,
    required ScheduleExceptionType type,
    String? shift,
  }) async {
    try {
      await pbService.schedules.createScheduleException(
        staffProfileId: widget.profile.id,
        date: date,
        type: type,
        shift: shift,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm ngoại lệ'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadExceptions(); // Tải lại
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
      throw e; // Ném lỗi để dialog không đóng
    }
  }

  // Hàm xử lý Xóa
  Future<void> _handleDeleteException(String exceptionId) async {
    try {
      await pbService.schedules.deleteScheduleException(exceptionId);
      _loadExceptions(); // Tải lại
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm hiển thị Dialog Thêm
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddExceptionDialog(
          onSave: _handleCreateException,
          initialDate: DateTime.now(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ngoại lệ lịch: ${widget.profile.name}')),
      body: RefreshIndicator(
        onRefresh: _loadExceptions,
        child: FutureBuilder<List<ScheduleExceptionModel>>(
          future: _exceptionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            final exceptions = snapshot.data ?? [];
            if (exceptions.isEmpty) {
              return Stack(
                children: [
                  ListView(), // Cho RefreshIndicator
                  Center(
                    child: Text(
                      'Không có ngoại lệ nào trong 30 ngày tới.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: exceptions.length,
              itemBuilder: (context, index) {
                final ex = exceptions[index];
                final isAbsent = ex.type == ScheduleExceptionType.absent;
                return ListTile(
                  leading: Icon(
                    isAbsent ? Icons.beach_access : Icons.add_alarm,
                    color: isAbsent ? Colors.orange : Colors.blue,
                  ),
                  title: Text(
                    isAbsent ? 'Nghỉ' : 'Làm thêm: ${ex.shift ?? 'N/A'}',
                  ),
                  subtitle: Text(
                    DateFormat('EEEE, dd/MM/yyyy').format(ex.date),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleDeleteException(ex.id),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
