import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injecare_plan/core/database/app_database.dart';
import 'package:injecare_plan/core/database/database_provider.dart';
import 'package:injecare_plan/features/injection/injection_provider.dart';
import 'package:injecare_plan/features/injection/widgets/body_silhouette_editor.dart';
import '../../helpers/test_database.dart';

void main() {
  test('bodyMapPointsProvider aggrega i punti di tutte le zone abilitate',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    // Forza apertura + seed (onCreate) prima di leggere gli stream.
    await db.customStatement('SELECT 1');

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // Tieni vivi gli stream finché leggiamo il provider aggregato.
    container.listen(bodyMapPointsProvider(
      (scheduledAt: DateTime(2026, 6, 23, 20), ignoreInjectionId: null),
    ), (_, __) {});

    final points = await container.read(bodyMapPointsProvider(
      (scheduledAt: DateTime(2026, 6, 23, 20), ignoreInjectionId: null),
    ).future);

    expect(points, isNotEmpty);
    final glute = points.firstWhere(
      (p) => p.zoneName.toLowerCase().contains('glute'),
    );
    expect(glute.bodyView, BodyView.back);
    expect(points.every((p) => !p.isBlacklisted), isTrue);
  });

  test('bodyMapPointsProvider espone il nome custom del punto', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // Assegna un nome custom al punto 1 di una zona abilitata.
    final zones = await db.getAllZones();
    final zone = zones.firstWhere((z) => z.isEnabled, orElse: () => zones.first);
    await db.upsertPointConfig(PointConfigsCompanion.insert(
      zoneId: zone.id,
      pointNumber: 1,
      customName: const Value('Spalla'),
    ));

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.listen(bodyMapPointsProvider(
      (scheduledAt: DateTime(2026, 6, 23, 20), ignoreInjectionId: null),
    ), (_, __) {});

    final points = await container.read(bodyMapPointsProvider(
      (scheduledAt: DateTime(2026, 6, 23, 20), ignoreInjectionId: null),
    ).future);

    final p = points.firstWhere(
      (p) => p.zoneId == zone.id && p.pointNumber == 1,
    );
    expect(p.customName, 'Spalla');
    // Il label leggibile usa il nome custom invece del numero.
    expect(p.label, endsWith('· Spalla'));
  });
}
