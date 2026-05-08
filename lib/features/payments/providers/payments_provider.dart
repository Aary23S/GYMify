import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dummy_data/dummy_payments.dart';

class PaymentStats {
  final double todayTotal;
  final double monthTotal;
  final double yearTotal;
  final int pendingCount;
  final int todayTransactions;
  final int monthTransactions;

  PaymentStats({
    required this.todayTotal,
    required this.monthTotal,
    required this.yearTotal,
    required this.pendingCount,
    required this.todayTransactions,
    required this.monthTransactions,
  });
}

class PaymentsState {
  final List<PaymentRecord> payments;
  final List<PendingRenewal> pendingRenewals;
  final PaymentStats stats;
  final String? selectedMode;
  final bool isRecordingPayment;

  PaymentsState({
    required this.payments,
    required this.pendingRenewals,
    required this.stats,
    this.selectedMode,
    this.isRecordingPayment = false,
  });

  PaymentsState copyWith({
    List<PaymentRecord>? payments,
    List<PendingRenewal>? pendingRenewals,
    PaymentStats? stats,
    String? selectedMode,
    bool? isRecordingPayment,
    bool clearMode = false,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      pendingRenewals: pendingRenewals ?? this.pendingRenewals,
      stats: stats ?? this.stats,
      selectedMode: clearMode ? null : (selectedMode ?? this.selectedMode),
      isRecordingPayment: isRecordingPayment ?? this.isRecordingPayment,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  PaymentsNotifier() : super(_initialState());

  static PaymentsState _initialState() {
    return PaymentsState(
      payments: dummyPayments,
      pendingRenewals: dummyPendingRenewals,
      stats: _calculateStats(dummyPayments, dummyPendingRenewals),
    );
  }

  static PaymentStats _calculateStats(List<PaymentRecord> payments, List<PendingRenewal> pending) {
    final now = DateTime.now();
    double todayTotal = 0;
    double monthTotal = 0;
    double yearTotal = 0;
    int todayTransactions = 0;
    int monthTransactions = 0;

    for (var p in payments) {
      if (p.paymentDate.year == now.year &&
          p.paymentDate.month == now.month &&
          p.paymentDate.day == now.day) {
        todayTotal += p.amount;
        todayTransactions++;
      }
      if (p.paymentDate.year == now.year && p.paymentDate.month == now.month) {
        monthTotal += p.amount;
        monthTransactions++;
      }
      if (p.paymentDate.year == now.year) {
        yearTotal += p.amount;
      }
    }

    return PaymentStats(
      todayTotal: todayTotal,
      monthTotal: monthTotal,
      yearTotal: yearTotal,
      pendingCount: pending.length,
      todayTransactions: todayTransactions,
      monthTransactions: monthTransactions,
    );
  }

  Future<void> recordPayment(PaymentRecord record) async {
    state = state.copyWith(isRecordingPayment: true);
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final updatedPayments = [record, ...state.payments];
    final updatedPending = state.pendingRenewals.where((p) => p.memberId != record.memberId).toList();
    
    state = state.copyWith(
      payments: updatedPayments,
      pendingRenewals: updatedPending,
      stats: _calculateStats(updatedPayments, updatedPending),
      isRecordingPayment: false,
    );
  }

  void setModeFilter(String? mode) {
    if (mode == null) {
      state = state.copyWith(clearMode: true);
    } else {
      state = state.copyWith(selectedMode: mode);
    }
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  return PaymentsNotifier();
});
