// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per il MLDataCollector

@ProviderFor(mlDataCollector)
final mlDataCollectorProvider = MlDataCollectorProvider._();

/// Provider per il MLDataCollector

final class MlDataCollectorProvider
    extends
        $FunctionalProvider<MLDataCollector, MLDataCollector, MLDataCollector>
    with $Provider<MLDataCollector> {
  /// Provider per il MLDataCollector
  MlDataCollectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mlDataCollectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mlDataCollectorHash();

  @$internal
  @override
  $ProviderElement<MLDataCollector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MLDataCollector create(Ref ref) {
    return mlDataCollector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MLDataCollector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MLDataCollector>(value),
    );
  }
}

String _$mlDataCollectorHash() => r'b3f136dc0f650dc31ca9562158e91dbcb6ef4e4b';

/// Provider per i dati delle zone

@ProviderFor(zoneInjectionData)
final zoneInjectionDataProvider = ZoneInjectionDataProvider._();

/// Provider per i dati delle zone

final class ZoneInjectionDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ZoneInjectionData>>,
          List<ZoneInjectionData>,
          FutureOr<List<ZoneInjectionData>>
        >
    with
        $FutureModifier<List<ZoneInjectionData>>,
        $FutureProvider<List<ZoneInjectionData>> {
  /// Provider per i dati delle zone
  ZoneInjectionDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zoneInjectionDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zoneInjectionDataHash();

  @$internal
  @override
  $FutureProviderElement<List<ZoneInjectionData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ZoneInjectionData>> create(Ref ref) {
    return zoneInjectionData(ref);
  }
}

String _$zoneInjectionDataHash() => r'75d9ee81b1fef9858178e0ac16d845068453afdf';

/// Provider per i pattern temporali

@ProviderFor(timePatternData)
final timePatternDataProvider = TimePatternDataProvider._();

/// Provider per i pattern temporali

final class TimePatternDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<TimePatternData>,
          TimePatternData,
          FutureOr<TimePatternData>
        >
    with $FutureModifier<TimePatternData>, $FutureProvider<TimePatternData> {
  /// Provider per i pattern temporali
  TimePatternDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timePatternDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timePatternDataHash();

  @$internal
  @override
  $FutureProviderElement<TimePatternData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TimePatternData> create(Ref ref) {
    return timePatternData(ref);
  }
}

String _$timePatternDataHash() => r'69c3d7fe8b0c48dfe8332f56a5cb54a0ca11c238';

/// Provider per i dati di aderenza

@ProviderFor(adherenceData)
final adherenceDataProvider = AdherenceDataProvider._();

/// Provider per i dati di aderenza

final class AdherenceDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceData>,
          AdherenceData,
          FutureOr<AdherenceData>
        >
    with $FutureModifier<AdherenceData>, $FutureProvider<AdherenceData> {
  /// Provider per i dati di aderenza
  AdherenceDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceDataHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceData> create(Ref ref) {
    return adherenceData(ref);
  }
}

String _$adherenceDataHash() => r'57a4e18f4c2d6d15c944ba49906cdec26620d320';

/// Provider per i pattern di skip

@ProviderFor(skipPatternData)
final skipPatternDataProvider = SkipPatternDataProvider._();

/// Provider per i pattern di skip

final class SkipPatternDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkipPatternData>,
          SkipPatternData,
          FutureOr<SkipPatternData>
        >
    with $FutureModifier<SkipPatternData>, $FutureProvider<SkipPatternData> {
  /// Provider per i pattern di skip
  SkipPatternDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skipPatternDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skipPatternDataHash();

  @$internal
  @override
  $FutureProviderElement<SkipPatternData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkipPatternData> create(Ref ref) {
    return skipPatternData(ref);
  }
}

String _$skipPatternDataHash() => r'077578adcd7014d7ca2e8016ed12af61b0279949';

/// Provider per le predizioni di zona

@ProviderFor(zonePredictions)
final zonePredictionsProvider = ZonePredictionsProvider._();

/// Provider per le predizioni di zona

final class ZonePredictionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ZonePrediction>>,
          List<ZonePrediction>,
          FutureOr<List<ZonePrediction>>
        >
    with
        $FutureModifier<List<ZonePrediction>>,
        $FutureProvider<List<ZonePrediction>> {
  /// Provider per le predizioni di zona
  ZonePredictionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zonePredictionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zonePredictionsHash();

  @$internal
  @override
  $FutureProviderElement<List<ZonePrediction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ZonePrediction>> create(Ref ref) {
    return zonePredictions(ref);
  }
}

String _$zonePredictionsHash() => r'e23fbde1867a9458d30f9891171031d103ec7adc';

/// Provider per la raccomandazione temporale

@ProviderFor(timeRecommendation)
final timeRecommendationProvider = TimeRecommendationProvider._();

/// Provider per la raccomandazione temporale

final class TimeRecommendationProvider
    extends
        $FunctionalProvider<
          AsyncValue<TimeRecommendation>,
          TimeRecommendation,
          FutureOr<TimeRecommendation>
        >
    with
        $FutureModifier<TimeRecommendation>,
        $FutureProvider<TimeRecommendation> {
  /// Provider per la raccomandazione temporale
  TimeRecommendationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timeRecommendationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timeRecommendationHash();

  @$internal
  @override
  $FutureProviderElement<TimeRecommendation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TimeRecommendation> create(Ref ref) {
    return timeRecommendation(ref);
  }
}

String _$timeRecommendationHash() =>
    r'0f23575c76b6635374c832c6fb8b372b0f2cde83';

/// Provider per lo score di aderenza

@ProviderFor(adherenceScore)
final adherenceScoreProvider = AdherenceScoreProvider._();

/// Provider per lo score di aderenza

final class AdherenceScoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceScore>,
          AdherenceScore,
          FutureOr<AdherenceScore>
        >
    with $FutureModifier<AdherenceScore>, $FutureProvider<AdherenceScore> {
  /// Provider per lo score di aderenza
  AdherenceScoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceScoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceScoreHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceScore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceScore> create(Ref ref) {
    return adherenceScore(ref);
  }
}

String _$adherenceScoreHash() => r'071b9b2de20a3493a109645bec70abcea8a68856';

/// Provider principale che combina tutte le predizioni in un suggerimento smart
/// Usa il pattern di rotazione configurato dall'utente

@ProviderFor(smartSuggestion)
final smartSuggestionProvider = SmartSuggestionProvider._();

/// Provider principale che combina tutte le predizioni in un suggerimento smart
/// Usa il pattern di rotazione configurato dall'utente

final class SmartSuggestionProvider
    extends
        $FunctionalProvider<
          AsyncValue<SmartSuggestion>,
          SmartSuggestion,
          FutureOr<SmartSuggestion>
        >
    with $FutureModifier<SmartSuggestion>, $FutureProvider<SmartSuggestion> {
  /// Provider principale che combina tutte le predizioni in un suggerimento smart
  /// Usa il pattern di rotazione configurato dall'utente
  SmartSuggestionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartSuggestionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartSuggestionHash();

  @$internal
  @override
  $FutureProviderElement<SmartSuggestion> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SmartSuggestion> create(Ref ref) {
    return smartSuggestion(ref);
  }
}

String _$smartSuggestionHash() => r'bb8a7f7bb53a65ca3fc795daff47ef28ff1bd14d';
