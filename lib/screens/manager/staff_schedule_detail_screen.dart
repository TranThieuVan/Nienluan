// [CODE MỚI HOÀN TOÀN CHO lib/screens/manager/staff_schedule_detail_screen.dart]

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:myshop/models/schedule_exception.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/widgets/manager/add_exception_dialog.dart';

// Định nghĩa các hằng số cho form
const List<String> _allWorkDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const List<String> _allShifts = ['Ca sáng', 'Ca chiều', 'Ca tối'];
const List<String> _allWorkTypes = ['full_time', 'part_time'];

class StaffScheduleDetailScreen extends StatefulWidget {
  final StaffProfile profile;

  const StaffScheduleDetailScreen({super.key, required this.profile});

  @override
  State<StaffScheduleDetailScreen> createState() =>
      _StaffScheduleDetailScreenState();
}

class _StaffScheduleDetailScreenState extends State<StaffScheduleDetailScreen>
    with SingleTickerProviderStateMixin {
  final pbService = PocketBaseService.instance;

  // State cho Tab Ngoại lệ
  late Future<List<ScheduleExceptionModel>> _exceptionsFuture;
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // State cho Tab Lịch Cố Định
  final _formKey = GlobalKey<FormState>();
  late String _selectedWorkType;
  late List<String> _selectedDays;
  late List<String> _selectedShifts;
  bool _isSavingSchedule = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Tab Ngoại Lệ
    _loadExceptions();

    // Khởi tạo Tab Lịch Cố Định
    _selectedWorkType = widget.profile.workType;
    _selectedDays = List<String>.from(widget.profile.defaultDays);
    _selectedShifts = List<String>.from(widget.profile.defaultShifts);
  }

  // --- LOGIC CHO TAB NGOẠI LỆ ---
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
      if (mounted) _showSnackbar('Đã thêm ngoại lệ', Colors.green);
      _loadExceptions();
    } catch (e) {
      if (mounted) _showSnackbar('Lỗi: $e', Colors.red);
      throw e;
    }
  }

  Future<void> _handleDeleteException(String exceptionId) async {
    try {
      await pbService.schedules.deleteScheduleException(exceptionId);
      _loadExceptions();
    } catch (e) {
      if (mounted) _showSnackbar('Lỗi khi xóa: $e', Colors.red);
    }
  }

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

  // --- LOGIC CHO TAB LỊCH CỐ ĐỊNH ---
  Future<void> _saveDefaultSchedule() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSavingSchedule = true;
      });
      try {
        await pbService.users.updateStaffDefaultSchedule(
          profileId: widget.profile.id,
          workType: _selectedWorkType,
          defaultDays: _selectedDays,
          defaultShifts: _selectedShifts,
        );
        if (mounted) _showSnackbar('Đã lưu lịch cố định!', Colors.green);
      } catch (e) {
        if (mounted) _showSnackbar('Lỗi lưu lịch: $e', Colors.red);
      } finally {
        if (mounted)
          setState(() {
            _isSavingSchedule = false;
          });
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lịch: ${widget.profile.name}'),
          backgroundColor: Colors.teal.shade600,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lịch Cố Định', icon: Icon(Icons.event_repeat)),
              Tab(text: 'Ngoại Lệ (Nghỉ/Thêm)', icon: Icon(Icons.event_busy)),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellow,
          ),
        ),
        body: TabBarView(
          children: [_buildDefaultScheduleTab(), _buildExceptionsTab()],
        ),
      ),
    );
  }

  // --- WIDGET CHO TAB 1: LỊCH CỐ ĐỊNH ---
  Widget _buildDefaultScheduleTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DropdownButtonFormField<String>(
            value: _allWorkTypes.contains(_selectedWorkType)
                ? _selectedWorkType
                : _allWorkTypes.first,
            decoration: const InputDecoration(
              labelText: 'Loại hình làm việc',
              border: OutlineInputBorder(),
            ),
            items: _allWorkTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type == 'full_time' ? 'Toàn thời gian' : 'Bán thời gian',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedWorkType = value);
            },
          ),
          const SizedBox(height: 16),
          MultiSelectChipField<String>(
            items: _allWorkDays
                .map((day) => MultiSelectItem(day, day))
                .toList(),
            title: const Text("Ngày làm việc cố định"),
            headerColor: Colors.teal.withOpacity(0.1),
            selectedChipColor: Colors.teal,
            selectedTextStyle: const TextStyle(color: Colors.white),
            initialValue: _selectedDays,
            onTap: (values) {
              _selectedDays = values;
            },
          ),
          const SizedBox(height: 16),
          MultiSelectChipField<String>(
            items: _allShifts
                .map((shift) => MultiSelectItem(shift, shift))
                .toList(),
            title: const Text("Ca làm việc cố định"),
            headerColor: Colors.teal.withOpacity(0.1),
            selectedChipColor: Colors.teal,
            selectedTextStyle: const TextStyle(color: Colors.white),
            initialValue: _selectedShifts,
            onTap: (values) {
              _selectedShifts = values;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: _isSavingSchedule
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSavingSchedule ? 'Đang lưu...' : 'Lưu Lịch Cố Định'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSavingSchedule ? null : _saveDefaultSchedule,
          ),
        ],
      ),
    );
  }

  // --- WIDGET CHO TAB 2: NGOẠI LỆ ---
  Widget _buildExceptionsTab() {
    return Scaffold(
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
                  ListView(),
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
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
