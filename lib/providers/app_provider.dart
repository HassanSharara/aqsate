import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../models/installment.dart';
import '../services/profit_calculator.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Customer> customers = [];
  List<Loan> allLoans = [];
  bool isLoading = false;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await loadCustomers();
    await loadAllLoans();
    isLoading = false;
    notifyListeners();
  }

  // ---------------- Customers ----------------

  Future<void> loadCustomers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    customers = maps.map((m) => Customer.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> addCustomer(Customer c) async {
    final db = await _dbHelper.database;
    final id = await db.insert('customers', c.toMap()..remove('id'));
    await loadCustomers();
    return id;
  }

  Future<void> updateCustomer(Customer c) async {
    final db = await _dbHelper.database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await loadCustomers();
    await loadAllLoans();
  }

  // ---------------- Loans ----------------

  Future<void> loadAllLoans() async {
    final db = await _dbHelper.database;
    final maps = await db.query('loans', orderBy: 'created_at DESC');
    allLoans = maps.map((m) => Loan.fromMap(m)).toList();
    notifyListeners();
  }

  List<Loan> loansForCustomer(int customerId) =>
      allLoans.where((l) => l.customerId == customerId).toList();

  Future<int> createLoan({
    required Loan loan,
    List<double>? manualProfitSchedule,
    double roundTo = 250,
  }) async {
    final db = await _dbHelper.database;
    final loanId = await db.insert('loans', loan.toMap()..remove('id'));

    final List<double> schedule = loan.distributionMode == ProfitDistributionMode.manual
        ? (manualProfitSchedule ??
            ProfitCalculator.generateEqualSchedule(
                totalProfit: loan.profitAmount, months: loan.months))
        : ProfitCalculator.generateAutoSchedule(
            totalProfit: loan.profitAmount, months: loan.months.clamp(0, 60),
      principalAmount: loan.principalAmount
    );


    final startDate = DateTime.parse(loan.startDate);
    final batch = db.batch();
    for (int i = 0; i < loan.months; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i + 1, startDate.day);
      final inst = Installment(
        loanId: loanId,
        monthIndex: i + 1,
        dueDate: dueDate.toIso8601String().split('T').first,
        scheduledProfit: schedule[i],
      );
      batch.insert('installments', inst.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);

    await loadAllLoans();
    return loanId;
  }

  Future<void> updateLoan(Loan loan, {List<double>? manualProfitSchedule}) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'loans',
        loan.toMap(),
        where: 'id = ?',
        whereArgs: [loan.id],
      );

      await txn.delete(
        'installments',
        where: 'loan_id = ?',
        whereArgs: [loan.id],
      );

      List<double> profitDistribution;
      if (loan.distributionMode == ProfitDistributionMode.manual && manualProfitSchedule != null) {
        profitDistribution = manualProfitSchedule;
      } else {
        profitDistribution = ProfitCalculator.generateAutoSchedule(
          totalProfit: loan.profitAmount,
          months: loan.months,
          principalAmount: loan.principalAmount,
        );
      }

      final double monthlyPrincipal = loan.principalAmount / loan.months;
      final DateTime start = DateTime.parse(loan.startDate);

      for (int i = 0; i < loan.months; i++) {
        final double installmentProfit = profitDistribution.length > i ? profitDistribution[i] : 0.0;
        final double totalMonthlyAmount = monthlyPrincipal + installmentProfit;
        final DateTime dueDate = DateTime(start.year, start.month + i, start.day);

        await txn.insert('installments', {
          'loan_id': loan.id,
          'month_index': i,
          'due_date': dueDate.toIso8601String().split('T').first,
          'scheduled_profit': installmentProfit,
          'payment_amount': totalMonthlyAmount,
          'payment_date': null,
          'notes': '',
        });
      }
    });

    await loadAllLoans();
  }
  Future<void> deleteLoan(int id) async {
    final db = await _dbHelper.database;
    await db.delete('loans', where: 'id = ?', whereArgs: [id]);
    await loadAllLoans();
  }

  /// إعادة توليد جدول الأقساط بالكامل (مثلاً بعد تعديل مبلغ/أشهر/وضع القرض)
  Future<void> regenerateSchedule(Loan loan, {List<double>? manualProfitSchedule, double roundTo = 250}) async {
    final db = await _dbHelper.database;
    await db.delete('installments', where: 'loan_id = ?', whereArgs: [loan.id]);

    final List<double> schedule = loan.distributionMode == ProfitDistributionMode.manual
        ? (manualProfitSchedule ??
            ProfitCalculator.generateEqualSchedule(
                totalProfit: loan.profitAmount, months: loan.months))
        : ProfitCalculator.generateAutoSchedule(
            totalProfit: loan.profitAmount, months: loan.months, roundTo: roundTo);

    final startDate = DateTime.parse(loan.startDate);
    final batch = db.batch();
    for (int i = 0; i < loan.months; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i + 1, startDate.day);
      final inst = Installment(
        loanId: loan.id!,
        monthIndex: i + 1,
        dueDate: dueDate.toIso8601String().split('T').first,
        scheduledProfit: schedule[i],
      );
      batch.insert('installments', inst.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
    notifyListeners();
  }

  // ---------------- Installments ----------------

  Future<List<Installment>> installmentsForLoan(int loanId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('installments',
        where: 'loan_id = ?', whereArgs: [loanId], orderBy: 'month_index ASC');
    return maps.map((m) => Installment.fromMap(m)).toList();
  }

  Future<void> recordPayment(Installment inst, {required double amount, String? date}) async {
    final db = await _dbHelper.database;
    await db.update(
      'installments',
      {
        'payment_amount': amount,
        'payment_date': date ?? DateTime.now().toIso8601String().split('T').first,
      },
      where: 'id = ?',
      whereArgs: [inst.id],
    );

    await _checkAndUpdateLoanStatus(inst.loanId);
    notifyListeners();
  }

  Future<void> updateInstallmentScheduledProfit(Installment inst, double value) async {
    final db = await _dbHelper.database;
    await db.update('installments', {'scheduled_profit': value},
        where: 'id = ?', whereArgs: [inst.id]);
    notifyListeners();
  }

  Future<void> _checkAndUpdateLoanStatus(int loanId) async {
    final db = await _dbHelper.database;
    final loanMaps = await db.query('loans', where: 'id = ?', whereArgs: [loanId]);
    if (loanMaps.isEmpty) return;
    final loan = Loan.fromMap(loanMaps.first);
    final installments = await installmentsForLoan(loanId);
    final rows = ProfitCalculator.calculateRows(
      principalAmount: loan.principalAmount,
      totalProfit: loan.profitAmount,
      installments: installments,
    );
    final bool completed = rows.isNotEmpty && rows.last.remainingTotal <= 0.01;
    final newStatus = completed ? LoanStatus.completed : LoanStatus.active;
    if (newStatus != loan.status) {
      await db.update('loans', {'status': newStatus.dbValue},
          where: 'id = ?', whereArgs: [loanId]);
      await loadAllLoans();
    }
  }

  // ---------------- Dashboard stats ----------------

  double get totalPrincipalOutstanding {
    double sum = 0;
    for (final l in allLoans) {
      sum += l.principalAmount; // تقريبي؛ الدقيق يُحسب لكل قرض عبر installments
    }
    return sum;
  }

  int get activeLoanCount => allLoans.where((l) => l.status == LoanStatus.active).length;
  int get completedLoanCount => allLoans.where((l) => l.status == LoanStatus.completed).length;
}
