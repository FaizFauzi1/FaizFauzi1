import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';

class InstallmentService {
  /// Calculates a default installment plan based on vendor settings or defaults.
  InstallmentPlan calculateMVPPlan({
    required String bookingId,
    required double totalAmount,
    VendorInstallmentSettings? settings,
  }) {
    final depositPercentage = settings?.depositPercentage ?? 30.0;
    final numberOfInstallments = settings?.maxInstallments ?? 5;
    
    final depositAmount = totalAmount * (depositPercentage / 100);
    final remainingBalance = totalAmount - depositAmount;
    
    return InstallmentPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID until saved
      bookingId: bookingId,
      totalAmount: totalAmount,
      depositAmount: depositAmount,
      remainingBalance: remainingBalance,
      numberOfInstallments: numberOfInstallments,
      status: InstallmentPlanStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates the schedule of payments for a plan.
  List<Map<String, dynamic>> generatePaymentSchedule(InstallmentPlan plan) {
    final List<Map<String, dynamic>> schedule = [];
    final monthlyAmount = plan.remainingBalance / plan.numberOfInstallments;
    final now = DateTime.now();

    for (int i = 1; i <= plan.numberOfInstallments; i++) {
      schedule.add({
        'amount': monthlyAmount,
        'dueDate': DateTime(now.year, now.month + i, now.day),
        'status': 'PENDING',
      });
    }

    return schedule;
  }

  /// Calculates an installment plan based on customized parameters.
  static Map<String, dynamic> calculatePlan({
    required double totalAmount,
    required double depositPercentage, // e.g., 30 for 30%
    required int months,
  }) {
    final depositAmount = totalAmount * (depositPercentage / 100);
    final remainingBalance = totalAmount - depositAmount;
    final monthlyAmount = remainingBalance / months;

    return {
      'totalAmount': totalAmount,
      'depositAmount': depositAmount,
      'remainingBalance': remainingBalance,
      'monthlyAmount': monthlyAmount,
      'numberOfInstallments': months,
    };
  }

  /// Generates the schedule of payments starting from a specific date.
  static List<Map<String, dynamic>> generateSchedule({
    required double monthlyAmount,
    required int months,
    required DateTime startDate,
  }) {
    final List<Map<String, dynamic>> schedule = [];
    
    for (int i = 1; i <= months; i++) {
      // Calculate next month's date
      final dueDate = DateTime(
        startDate.year,
        startDate.month + i,
        startDate.day,
      );
      
      schedule.add({
        'amount': monthlyAmount,
        'dueDate': dueDate,
        'status': 'pending',
      });
    }
    
    return schedule;
  }
}
