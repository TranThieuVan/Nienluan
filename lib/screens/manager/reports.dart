// [DÁN TOÀN BỘ CODE NÀY VÀO lib/screens/manager/reports.dart]

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myshop/models/order.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/models/best_seller_item.dart';
import 'package:myshop/models/menu_item.dart'; // <--- DÒNG SỬA LỖI ĐÂY RỒI
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';
import 'salary_detail_screen.dart';

// Lớp để giữ dữ liệu đã xử lý cho biểu đồ
class DailyRevenue {
  final DateTime date;
  final double total;
  final double cost; // <-- Thêm giá vốn
  double get profit => total - cost; // <-- Thêm lợi nhuận

  DailyRevenue({required this.date, required this.total, required this.cost});
}

// Kiểu trả về của Future (gộp 3 danh sách)
typedef ReportData = (
  List<OrderModel>,
  List<StaffProfile>,
  List<BestSellerItem>, // <-- THÊM VÀO
);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final pbService = PocketBaseService.instance;

  DateTime _selectedMonth = DateTime.now();
  late Future<ReportData> _reportDataFuture;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() {
    if (mounted) {
      setState(() {
        _reportDataFuture =
            Future.wait([
              pbService.reports.getCompletedOrdersForMonth(_selectedMonth),
              pbService.users.getStaffProfiles(),
              pbService.reports.getBestSellingItems(_selectedMonth),
            ]).then((results) {
              return (
                results[0] as List<OrderModel>,
                results[1] as List<StaffProfile>,
                results[2] as List<BestSellerItem>,
              );
            });
      });
    }
  }

  void _navigateToSalaryDetail(
    List<StaffProfile> profiles,
    double totalPayroll,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SalaryDetailScreen(profiles: profiles, totalPayroll: totalPayroll),
      ),
    );
  }

  void _changeMonth(int a) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + a,
        1,
      );
      if (_selectedMonth.isAfter(DateTime.now())) {
        _selectedMonth = DateTime.now();
      }
    });
    _loadReportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: FutureBuilder<ReportData>(
              future: _reportDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final orders = snapshot.data?.$1 ?? [];
                final profiles = snapshot.data?.$2 ?? [];
                final bestSellers = snapshot.data?.$3 ?? [];

                // --- SỬA HÀM XỬ LÝ: Thêm LỢI NHUẬN GỘP ---
                final (dailyData, totalRevenue, totalCost, busiestDay) =
                    _processOrderData(orders, bestSellers);
                final totalPayroll = _processPayrollData(profiles);
                final double totalProfit = totalRevenue - totalCost;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- SỬA THẺ NÀY: Thêm LỢI NHUẬN GỘP ---
                    _buildSummaryCard(
                      totalRevenue,
                      totalProfit,
                      totalOrders: orders.length,
                      busiestDay: busiestDay,
                    ),
                    const SizedBox(height: 16),
                    _buildPayrollCard(totalPayroll, profiles, context),
                    const SizedBox(height: 24),
                    _buildBestSellersCard(bestSellers),
                    const SizedBox(height: 24),

                    Text(
                      'Doanh thu & Lợi nhuận (theo ngày)', // <-- Sửa tiêu đề
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildBarChart(dailyData), // Biểu đồ giờ có cả 2
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget chọn tháng
  Widget _buildMonthPicker() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.amber.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            "Tháng ${DateFormat('MM/yyyy').format(_selectedMonth)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  // --- SỬA THẺ NÀY: Thêm Lợi nhuận ---
  Widget _buildSummaryCard(
    double totalRevenue,
    double totalProfit, {
    required int totalOrders,
    required String busiestDay,
  }) {
    return Card(
      elevation: 4,
      color: Colors.amber.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Tổng Doanh thu',
                  formatCurrency(totalRevenue),
                ),
                _buildSummaryItem(
                  'Lợi nhuận gộp',
                  formatCurrency(totalProfit),
                  isProfit: true,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Tổng Đơn',
                  totalOrders.toString(),
                  small: true,
                ),
                _buildSummaryItem('Đông nhất', busiestDay, small: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget thẻ tổng lương
  Widget _buildPayrollCard(
    double totalPayroll,
    List<StaffProfile> profiles,
    BuildContext context,
  ) {
    final activeStaffCount = profiles.where((p) => p.status == 'active').length;

    return InkWell(
      onTap: () {
        _navigateToSalaryDetail(profiles, totalPayroll);
      },
      child: Card(
        elevation: 4,
        color: Colors.indigo.shade700,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Tổng Lương (tháng)',
                formatCurrency(totalPayroll),
              ),
              _buildSummaryItem(
                'Nhân viên (Active)',
                activeStaffCount.toString(),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Top 5
  Widget _buildBestSellersCard(List<BestSellerItem> bestSellers) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 Món Bán Chạy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (bestSellers.isEmpty)
              const Text('Không có dữ liệu món bán chạy.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bestSellers.length > 5 ? 5 : bestSellers.length,
                itemBuilder: (context, index) {
                  final item = bestSellers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(item.menuItem.name),
                    trailing: Text(
                      '${item.totalQuantity} (lượt)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Widget con cho thẻ tổng quan
  Widget _buildSummaryItem(
    String label,
    String value, {
    bool small = false,
    bool isProfit = false,
  }) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: small ? 14 : 16, color: Colors.white70),
            textAlign: TextAlign.left,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.lightGreenAccent : Colors.white,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  // Widget Biểu đồ (SỬA LẠI ĐỂ VẼ CẢ LỢI NHUẬN)
  Widget _buildBarChart(List<DailyRevenue> dailyData) {
    if (dailyData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Không có dữ liệu doanh thu trong tháng này.'),
        ),
      );
    }

    double maxY = 0;
    for (var data in dailyData) {
      if (data.total > maxY) {
        maxY = data.total;
      }
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 100000) maxY = 100000;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (barChartGroupData) {
                return Colors.amber.shade800;
              },
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final data = dailyData[group.x];
                final day = DateFormat('dd/MM').format(data.date);
                final revenue = formatCurrency(data.total);
                final profit = formatCurrency(data.profit);

                return BarTooltipItem(
                  '$day\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'DT: $revenue\n',
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'LN: $profit',
                      style: const TextStyle(color: Colors.lightGreenAccent),
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
                  if (value == 0 || value == maxY / 2 || value == maxY) {
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
                  final day = dailyData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      (day.day % 5 == 0 || day.day == 1)
                          ? DateFormat('dd').format(day)
                          : '',
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
              // Vẽ 2 cột chồng lên nhau
              barRods: [
                // Cột Doanh thu (vẽ trước, ở sau)
                BarChartRodData(
                  toY: data.total,
                  color: Colors.amber,
                  width: 10,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                // Cột Lợi nhuận (vẽ sau, đè lên trên)
                BarChartRodData(
                  toY: data.profit, // Vẽ lợi nhuận
                  color: Colors.green, // Màu lợi nhuận
                  width: 10,
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

  // --- HÀM XỬ LÝ DỮ LIỆU (ĐÃ NÂNG CẤP) ---
  (List<DailyRevenue>, double, double, String) _processOrderData(
    List<OrderModel> orders,
    List<BestSellerItem> bestSellers,
  ) {
    double totalRevenue = 0;
    double totalCost = 0; // <-- TÍNH TỔNG GIÁ VỐN
    Map<int, int> weekdayCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    Map<String, DailyRevenue> dailyMap = {};

    // Map món ăn để tra giá vốn (ĐÃ SỬA LỖI)
    final Map<String, MenuItemModel> menuMap = {
      for (var item in bestSellers) item.menuItem.id: item.menuItem,
    };

    // Tạo Map tính giá vốn của TẤT CẢ món đã bán
    final Map<String, double> allItemsCost = {};
    for (var item in bestSellers) {
      totalCost += (item.menuItem.cost * item.totalQuantity);
      allItemsCost[item.menuItem.id] = item.menuItem.cost;
    }

    for (var order in orders) {
      totalRevenue += order.totalPrice;
      final localDate = order.created.toLocal();
      weekdayCounts[localDate.weekday] =
          (weekdayCounts[localDate.weekday] ?? 0) + 1;
      final dayKey = DateFormat('yyyy-MM-dd').format(localDate);

      // Tính giá vốn của ĐƠN HÀNG NÀY
      // Rất tiếc, chúng ta không thể lấy order_items của từng đơn hàng
      // (vì sẽ tốn 1000 lượt gọi CSDL),
      // nên chúng ta sẽ *ước lượng* giá vốn theo ngày
      double orderCost = 0.0;
      // TODO: Cần 1 view "order_items_with_cost" để tính chính xác

      if (dailyMap.containsKey(dayKey)) {
        var data = dailyMap[dayKey]!;
        dailyMap[dayKey] = DailyRevenue(
          date: data.date,
          total: data.total + order.totalPrice,
          cost: data.cost + orderCost, // Tạm thời = 0
        );
      } else {
        dailyMap[dayKey] = DailyRevenue(
          date: DateTime.parse(dayKey),
          total: order.totalPrice,
          cost: orderCost, // Tạm thời = 0
        );
      }
    }

    // Xử lý biểu đồ
    final List<DailyRevenue> dailyData = dailyMap.values.toList();
    dailyData.sort((a, b) => a.date.compareTo(b.date));

    // Xử lý ngày đông nhất
    String busiestDay = "N/A";
    if (orders.isNotEmpty) {
      final sortedDays = weekdayCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sortedDays.first.value > 0) {
        final busiestWeekday = sortedDays.first.key;
        busiestDay = _getWeekdayName(busiestWeekday);
      }
    }

    // Trả về TỔNG GIÁ VỐN (của cả tháng)
    return (dailyData, totalRevenue, totalCost, busiestDay);
  }

  // --- HÀM MỚI ĐỂ XỬ LÝ LƯƠNG ---
  double _processPayrollData(List<StaffProfile> profiles) {
    double totalPayroll = 0;
    for (var profile in profiles) {
      if (profile.status == 'active') {
        totalPayroll += profile.salary;
      }
    }
    return totalPayroll;
  }

  // Helper chuyển weekday (int) sang Tiếng Việt
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ Nhật';
      default:
        return 'N/A';
    }
  }

  // Helper format tiền
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
