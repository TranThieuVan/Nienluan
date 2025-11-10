// [DÁN TOÀN BỘ CODE NÀY VÀO lib/screens/manager/reports.dart]

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myshop/models/order.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';

// Lớp để giữ dữ liệu đã xử lý cho biểu đồ
class DailyRevenue {
  final DateTime date;
  final double total;
  DailyRevenue({required this.date, required this.total});
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final pbService = PocketBaseService.instance;

  // 1. Quản lý state cho việc chọn ngày
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)), // Mặc định 7 ngày
    end: DateTime.now(),
  );

  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu lần đầu
    _loadReportData();
  }

  // 2. Hàm gọi service
  void _loadReportData() {
    if (mounted) {
      setState(() {
        _ordersFuture = pbService.reports.getCompletedOrders(
          _selectedDateRange.start,
          _selectedDateRange.end,
        );
      });
    }
  }

  // 3. Hàm hiển thị bộ chọn ngày
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      // Tải lại dữ liệu với ngày mới
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Doanh thu'),
        backgroundColor: Colors.amber.shade700, // Đổi màu cho hợp Giao diện
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BỘ CHỌN NGÀY ---
          _buildDateRangePicker(),

          // --- BIỂU ĐỒ VÀ TỔNG QUAN ---
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];

                // --- Xử lý dữ liệu để vẽ biểu đồ ---
                final (dailyData, totalRevenue) = _processData(orders);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- Thẻ tổng quan ---
                    _buildSummaryCard(totalRevenue, orders.length),
                    const SizedBox(height: 24),

                    // --- Biểu đồ ---
                    Text(
                      'Doanh thu chi tiết (theo ngày)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildBarChart(dailyData),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget chọn ngày
  Widget _buildDateRangePicker() {
    final f = DateFormat('dd/MM/yyyy');
    final start = f.format(_selectedDateRange.start);
    final end = f.format(_selectedDateRange.end);

    return InkWell(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.amber.shade50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.amber),
            const SizedBox(width: 16),
            Text(
              '$start - $end',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  // Widget thẻ tổng quan
  Widget _buildSummaryCard(double totalRevenue, int totalOrders) {
    return Card(
      elevation: 4,
      color: Colors.amber.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Tổng Doanh thu',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  formatCurrency(totalRevenue),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Text(
                  'Tổng đơn hàng',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  totalOrders.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Biểu đồ
  Widget _buildBarChart(List<DailyRevenue> dailyData) {
    if (dailyData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Không có dữ liệu trong khoảng thời gian này.'),
        ),
      );
    }

    // Tìm giá trị Y (doanh thu) cao nhất để set trần cho biểu đồ
    double maxY = 0;
    for (var data in dailyData) {
      if (data.total > maxY) {
        maxY = data.total;
      }
    }
    // Làm tròn lên và + 20%
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 100000) maxY = 100000; // Đặt trần tối thiểu

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // ===================================
              // === DÒNG SỬA LỖI LÀ DÒNG NÀY ===
              getTooltipColor: (barChartGroupData) {
                return Colors.amber.shade800;
              },
              // === HẾT DÒNG SỬA LỖI ===
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final data = dailyData[group.x];
                final day = DateFormat('dd/MM').format(data.date);
                final revenue = formatCurrency(data.total);
                return BarTooltipItem(
                  '$day\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: revenue,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  // Chỉ hiển thị 1 vài mốc
                  if (value == 0 || value == maxY / 2 || value == maxY) {
                    // Hiển thị dạng "100k", "1tr"
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _formatShortCurrency(value),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Hiển thị ngày (dd/MM) ở trục X
                  final day = dailyData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(day),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.total,
                  color: Colors.amber,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- HÀM XỬ LÝ DỮ LIỆU ---
  (List<DailyRevenue>, double) _processData(List<OrderModel> orders) {
    // 1. Cộng tổng doanh thu
    double totalRevenue = 0;
    for (var order in orders) {
      totalRevenue += order.totalPrice;
    }

    // 2. Nhóm doanh thu theo ngày
    Map<String, double> dailyMap = {};
    for (var order in orders) {
      // Chuyển về Local time và format
      final dayKey = DateFormat('yyyy-MM-dd').format(order.created.toLocal());

      if (dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = dailyMap[dayKey]! + order.totalPrice;
      } else {
        dailyMap[dayKey] = order.totalPrice;
      }
    }

    // 3. Chuyển Map thành List<DailyRevenue> đã sắp xếp
    final List<DailyRevenue> dailyData = dailyMap.entries.map((entry) {
      return DailyRevenue(date: DateTime.parse(entry.key), total: entry.value);
    }).toList();

    dailyData.sort((a, b) => a.date.compareTo(b.date));

    return (dailyData, totalRevenue);
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}tr';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
