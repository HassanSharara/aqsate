import '../models/installment.dart';

class ProfitCalculator {
  static List<double> generateAutoSchedule({
    required double totalProfit,
    required int months,
    double? principalAmount,
    double roundTo = 5000,
  }) {
    if (months <= 0) return [];
    if (months == 1) return [totalProfit.roundToDouble()];
    if (months == 2) {
      final double half = totalProfit / 2;
      final double roundedHalf = roundTo > 0 ? (half / roundTo).round() * roundTo : half;
      return [roundedHalf, (totalProfit - roundedHalf).roundToDouble()];
    }

    final double actualPrincipal = principalAmount ?? (totalProfit * 3);
    final double expectedInstallment = (actualPrincipal / 1000000.0) * 100000.0;
    final double startProfit = expectedInstallment * 0.5;

    // الحد الأدنى للفائدة هو 5% من القسط المتوقع (مثلاً 5,000 لكل 100,000 قسط)
    double minProfit = expectedInstallment * 0.05;

    // التحقق من ألا يتجاوز مجموع الحدود الدنيا إجمالي الأرباح المطلوبة
    if (2 * startProfit + (months - 2) * minProfit > totalProfit) {
      minProfit = (totalProfit - (2 * startProfit)) / (months - 2);
      if (minProfit < 250) minProfit = 250; // حد أدنى مطلق جداً
    }

    // البحث الثنائي (Bisection Search) لإيجاد قيمة step (الخطوة التناقصية) الدقيقة
    double low = 0;
    double high = startProfit;
    for (int iter = 0; iter < 30; iter++) {
      double mid = (low + high) / 2;
      double sum = 0;
      for (int i = 0; i < months; i++) {
        if (i == 0 || i == 1) {
          sum += startProfit;
        } else {
          double val = startProfit - (i - 1) * mid;
          if (val < minProfit) val = minProfit;
          sum += val;
        }
      }
      if (sum > totalProfit) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final double finalStep = low;

    final List<double> rounded = [];
    double runningSum = 0;

    for (int i = 0; i < months - 1; i++) {
      double rawValue;
      if (i == 0 || i == 1) {
        rawValue = startProfit;
      } else {
        rawValue = startProfit - ((i - 1) * finalStep);
      }
      if (rawValue < minProfit) rawValue = minProfit;

      double v = roundTo > 0 ? (rawValue / roundTo).round() * roundTo : rawValue;
      if (v < minProfit) v = minProfit;

      rounded.add(v);
      runningSum += v;
    }

    double lastValue = totalProfit - runningSum;
    rounded.add(lastValue.roundToDouble());

    // ضبط القسط الأخير ليكون متناسقاً وتنازلياً ولا يحتوي على أصفار
    double unit = roundTo > 0 ? roundTo : 250.0;

    // حالة 1: القسط الأخير أقل من الحد الأدنى -> نسحب من الأشهر السابقة ونضيف للأخير
    while (rounded[months - 1] < minProfit) {
      bool adjusted = false;
      for (int j = 0; j < months - 1; j++) {
        double nextVal = (j == months - 2) ? (rounded[j + 1] + unit) : rounded[j + 1];
        if (rounded[j] - unit >= minProfit && rounded[j] - unit >= nextVal) {
          rounded[j] -= unit;
          rounded[months - 1] += unit;
          adjusted = true;
          break;
        }
      }
      if (!adjusted) break;
    }

    // حالة 2: القسط الأخير أكبر من القسط الذي قبله -> نسحب من الأخير ونوزع على الأشهر السابقة
    while (rounded[months - 1] > rounded[months - 2]) {
      bool adjusted = false;
      for (int j = months - 2; j >= 0; j--) {
        if (j == 0 || rounded[j - 1] >= rounded[j] + unit) {
          rounded[j] += unit;
          rounded[months - 1] -= unit;
          adjusted = true;
          break;
        }
      }
      if (!adjusted) break;
    }

    return rounded;
  }

  static List<double> generateEqualSchedule({
    required double totalProfit,
    required int months,
  })
  {
    if (months <= 0) return [];
    if (months == 1) return [totalProfit.roundToDouble()];

    final double each = totalProfit / months;
    final double roundedEach = (each / 5000).round() * 5000.0;

    final List<double> rounded = [];
    double runningSum = 0;

    for (int i = 0; i < months - 1; i++) {
      rounded.add(roundedEach);
      runningSum += roundedEach;
    }

    final double lastValue = totalProfit - runningSum;
    rounded.add(lastValue < 0 ? 0 : lastValue.roundToDouble());

    return rounded;
  }

  static List<InstallmentRow> calculateRows({
    required double principalAmount,
    required double totalProfit,
    required List<Installment> installments,
  }) {
    final List<Installment> sorted = List.of(installments)
      ..sort((a, b) => a.monthIndex.compareTo(b.monthIndex));

    final int monthsCount = sorted.length;
    // القسط الشهري المفترض لأصل المبلغ
    final double expectedMonthlyPrincipal = monthsCount > 0 ? principalAmount / monthsCount : 0;

    double runningPrincipalPaid = 0;
    double runningProfitPaid = 0;
    double runningTotalPaid = 0; // الدفوعات التراكمية الفعلية حتى الشهر الحالي

    double runningExpectedPrincipalPaid = 0;
    double runningExpectedProfitPaid = 0;

    final List<InstallmentRow> rows = [];

    for (final inst in sorted) {
      double payment = inst.paymentAmount;
      double profitPortion = 0;
      double principalPortion = 0;

      // إذا كان هناك سداد مسجل لهذا الشهر
      if (payment > 0) {
        profitPortion = payment <= inst.scheduledProfit ? payment : inst.scheduledProfit;
        principalPortion = payment - profitPortion;
      }

      runningPrincipalPaid += principalPortion;
      runningProfitPaid += profitPortion;
      runningTotalPaid += payment;

      // حساب التراكمي المفترض
      runningExpectedPrincipalPaid += expectedMonthlyPrincipal;
      runningExpectedProfitPaid += inst.scheduledProfit;

      // حساب المتبقي الحقيقي بناءً على إجمالي الدفوعات التراكمية حتى هذا الشهر
      double remainingPrincipal = (principalAmount - runningPrincipalPaid).clamp(0.0, principalAmount);
      double remainingProfit = (totalProfit - runningProfitPaid).clamp(0.0, totalProfit);
      double remainingTotal = ((principalAmount + totalProfit) - runningTotalPaid).clamp(0.0, principalAmount + totalProfit);

      // في حال تصفير المتبقي الكلي، تتصفر الأجزاء المتبقية تلقائياً
      if (remainingTotal <= 0.01) {
        remainingPrincipal = 0;
        remainingProfit = 0;
        remainingTotal = 0;
      } else {
        // توزيع المتبقي الكلي على الأصل والربح بالتناسب
        if (remainingPrincipal + remainingProfit > remainingTotal) {
          remainingPrincipal = remainingTotal >= remainingPrincipal ? remainingPrincipal : remainingTotal;
          remainingProfit = (remainingTotal - remainingPrincipal).clamp(0.0, totalProfit);
        }
      }

      // حسابات القسط والمتبقي المفترض
      double expectedInstallment = expectedMonthlyPrincipal + inst.scheduledProfit;
      double expectedRemainingPrincipal = (principalAmount - runningExpectedPrincipalPaid).clamp(0.0, principalAmount);
      double expectedRemainingTotal = ((principalAmount + totalProfit) - (runningExpectedPrincipalPaid + runningExpectedProfitPaid)).clamp(0.0, principalAmount + totalProfit);

      rows.add(InstallmentRow(
        installment: inst,
        profitPortion: profitPortion,
        principalPortion: principalPortion,
        remainingPrincipal: remainingPrincipal,
        remainingProfit: remainingProfit,
        remainingTotal: remainingTotal,
        expectedInstallment: expectedInstallment,
        expectedRemainingPrincipal: expectedRemainingPrincipal,
        expectedRemainingTotal: expectedRemainingTotal,
      ));
    }

    return rows;
  }
}