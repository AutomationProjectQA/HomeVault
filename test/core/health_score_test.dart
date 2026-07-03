import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/features/dashboard/health_score.dart';

void main() {
  test('perfect home scores 100 / Excellent', () {
    final score = computeHealthScore(
        criticalOverdue: 0, mediumOverdue: 0, expiringWarranties30d: 0);
    expect(score, 100);
    expect(const HealthScore(100, 0).band, 'Excellent');
  });

  test('each factor penalises with its cap', () {
    expect(
        computeHealthScore(
            criticalOverdue: 1, mediumOverdue: 0, expiringWarranties30d: 0),
        85);
    expect(
        computeHealthScore(
            criticalOverdue: 10, mediumOverdue: 0, expiringWarranties30d: 0),
        55); // capped at 45
    expect(
        computeHealthScore(
            criticalOverdue: 0, mediumOverdue: 2, expiringWarranties30d: 1),
        85);
  });

  test('worst case clamps to 15 and bands are correct', () {
    final worst = computeHealthScore(
        criticalOverdue: 99, mediumOverdue: 99, expiringWarranties30d: 99);
    expect(worst, 15); // 100 - 45 - 25 - 15
    expect(HealthScore(worst, 5).band, 'At risk');
    expect(const HealthScore(72, 1).band, 'Good');
    expect(const HealthScore(55, 3).band, 'Needs attention');
  });
}
