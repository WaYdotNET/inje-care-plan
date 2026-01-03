// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per il periodo selezionato

@ProviderFor(StatsPeriodNotifier)
final statsPeriodProvider = StatsPeriodNotifierProvider._();

/// Provider per il periodo selezionato
final class StatsPeriodNotifierProvider
    extends $NotifierProvider<StatsPeriodNotifier, StatsPeriod> {
  /// Provider per il periodo selezionato
  StatsPeriodNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsPeriodNotifierHash();

  @$internal
  @override
  StatsPeriodNotifier create() => StatsPeriodNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsPeriod>(value),
    );
  }
}

String _$statsPeriodNotifierHash() =>
    r'186c1ae85a8977fa0cddc22383ff722b219c16d6';

/// Provider per il periodo selezionato

abstract class _$StatsPeriodNotifier extends $Notifier<StatsPeriod> {
  StatsPeriod build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StatsPeriod, StatsPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StatsPeriod, StatsPeriod>,
              StatsPeriod,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider principale per le statistiche

@ProviderFor(injectionStats)
final injectionStatsProvider = InjectionStatsProvider._();

/// Provider principale per le statistiche

final class InjectionStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<InjectionStats>,
          InjectionStats,
          FutureOr<InjectionStats>
        >
    with $FutureModifier<InjectionStats>, $FutureProvider<InjectionStats> {
  /// Provider principale per le statistiche
  InjectionStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'injectionStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$injectionStatsHash();

  @$internal
  @override
  $FutureProviderElement<InjectionStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InjectionStats> create(Ref ref) {
    return injectionStats(ref);
  }
}

String _$injectionStatsHash() => r'2595d43fc747f124b3b92bf93ff70e27f5d69b5a';

/// Provider per le statistiche della zona specifica

@ProviderFor(zoneStats)
final zoneStatsProvider = ZoneStatsFamily._();

/// Provider per le statistiche della zona specifica

final class ZoneStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ZoneUsage?>,
          ZoneUsage?,
          FutureOr<ZoneUsage?>
        >
    with $FutureModifier<ZoneUsage?>, $FutureProvider<ZoneUsage?> {
  /// Provider per le statistiche della zona specifica
  ZoneStatsProvider._({
    required ZoneStatsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'zoneStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$zoneStatsHash();

  @override
  String toString() {
    return r'zoneStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ZoneUsage?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ZoneUsage?> create(Ref ref) {
    final argument = this.argument as int;
    return zoneStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ZoneStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$zoneStatsHash() => r'9c331a7b4c7d546e02fe8e03765eb158f8e0ea48';

/// Provider per le statistiche della zona specifica

final class ZoneStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ZoneUsage?>, int> {
  ZoneStatsFamily._()
    : super(
        retry: null,
        name: r'zoneStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider per le statistiche della zona specifica

  ZoneStatsProvider call(int zoneId) =>
      ZoneStatsProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'zoneStatsProvider';
}
