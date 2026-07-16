import '../models/installment.dart';

class ProfitCalculator {
  /// يولّد جدول أرباح تلقائي متناقص (على غرار Rule of 78):
  /// الأشهر الأولى تأخذ حصة أكبر من الربح، وتتناقص تدريجياً كل شهر
  /// حتى تصل لأصغر حصة في آخر شهر، مع ضمان أن مجموع الحصص = إجمالي الربح تماماً.
  ///
  /// [roundTo] لتقريب كل حصة شهرية لأقرب قيمة (مثلاً 250 أو 500 دينار) لتكون
  /// الأرقام "مرتبة" بصرياً، مع تصحيح الفرق في الشهر الأخير.
  static List<double> generateAutoSchedule({
    required double totalProfit,
    required int months,
    double roundTo = 250,
  }) {
    if (months <= 0) return [];
    if (months == 1) return [totalProfit];

    // أوزان متناقصة: الشهر الأول وزنه = months، وآخر شهر وزنه = 1
    final int sumWeights = (months * (months + 1)) ~/ 2;
    final List<double> raw = List.generate(months, (i) {
      final int weight = months - i; // يتناقص من months إلى 1
      return totalProfit * weight / sumWeights;
    });

    // تقريب كل القيم عدا الأخيرة، ثم تصحيح الأخيرة لتحافظ على المجموع الدقيق
    final List<double> rounded = [];
    double runningSum = 0;
    for (int i = 0; i < months - 1; i++) {
      double v = roundTo > 0 ? (raw[i] / roundTo).round() * roundTo : raw[i];
      if (v < 0) v = 0;
      rounded.add(v);
      runningSum += v;
    }
    final double lastValue = totalProfit - runningSum;
    rounded.add(lastValue < 0 ? 0 : lastValue);

    return rounded;
  }

  /// توزيع يدوي مبدئي (متساوٍ) كنقطة انطلاق يعدلها المستخدم لاحقاً يدوياً
  static List<double> generateEqualSchedule({
    required double totalProfit,
    required int months,
  }) {
    if (months <= 0) return [];
    final double each = totalProfit / months;
    return List.generate(months, (_) => each);
  }

  /// يحسب صفوف الجدول الكاملة (الخانات الست) بالاعتماد على:
  /// - المبلغ الأصلي، إجمالي الأرباح
  /// - جدول الأقساط (كل شهر لديه scheduledProfit و paymentAmount المسجل)
  ///
  /// منطق التقسيم لكل دفعة شهرية:
  ///   جزء الربح المحتسب = أقل قيمة بين (مبلغ التسديد) و (ربح هذا الشهر المجدول)
  ///   جزء أصل المبلغ = مبلغ التسديد - جزء الربح
  static List<InstallmentRow> calculateRows({
    required double principalAmount,
    required double totalProfit,
    required List<Installment> installments,
  }) {
    final List<Installment> sorted = List.of(installments)
      ..sort((a, b) => a.monthIndex.compareTo(b.monthIndex));

    double runningPrincipalPaid = 0;
    double runningProfitPaid = 0;
    final List<InstallmentRow> rows = [];

    for (final inst in sorted) {
      final double payment = inst.paymentAmount;
      final double profitPortion =
          payment <= inst.scheduledProfit ? payment : inst.scheduledProfit;
      final double principalPortion = payment - profitPortion;

      runningPrincipalPaid += principalPortion;
      runningProfitPaid += profitPortion;

      final double remainingPrincipal =
          (principalAmount - runningPrincipalPaid).clamp(0, principalAmount).toDouble();
      final double remainingProfit =
          (totalProfit - runningProfitPaid).clamp(0, totalProfit).toDouble();
      final double remainingTotal = remainingPrincipal + remainingProfit;

      rows.add(InstallmentRow(
        installment: inst,
        profitPortion: profitPortion,
        principalPortion: principalPortion,
        remainingPrincipal: remainingPrincipal,
        remainingProfit: remainingProfit,
        remainingTotal: remainingTotal,
      ));
    }

    return rows;
  }
}
