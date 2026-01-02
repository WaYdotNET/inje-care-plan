// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BodyZonesTable extends BodyZones
    with TableInfo<$BodyZonesTable, BodyZone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyZonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 4,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberOfPointsMeta = const VerificationMeta(
    'numberOfPoints',
  );
  @override
  late final GeneratedColumn<int> numberOfPoints = GeneratedColumn<int>(
    'number_of_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    numberOfPoints,
    isEnabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyZone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('number_of_points')) {
      context.handle(
        _numberOfPointsMeta,
        numberOfPoints.isAcceptableOrUnknown(
          data['number_of_points']!,
          _numberOfPointsMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyZone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyZone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      numberOfPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_points'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BodyZonesTable createAlias(String alias) {
    return $BodyZonesTable(attachedDatabase, alias);
  }
}

class BodyZone extends DataClass implements Insertable<BodyZone> {
  final int id;
  final String code;
  final String name;
  final int numberOfPoints;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BodyZone({
    required this.id,
    required this.code,
    required this.name,
    required this.numberOfPoints,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['number_of_points'] = Variable<int>(numberOfPoints);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BodyZonesCompanion toCompanion(bool nullToAbsent) {
    return BodyZonesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      numberOfPoints: Value(numberOfPoints),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BodyZone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyZone(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      numberOfPoints: serializer.fromJson<int>(json['numberOfPoints']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'numberOfPoints': serializer.toJson<int>(numberOfPoints),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BodyZone copyWith({
    int? id,
    String? code,
    String? name,
    int? numberOfPoints,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BodyZone(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    numberOfPoints: numberOfPoints ?? this.numberOfPoints,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BodyZone copyWithCompanion(BodyZonesCompanion data) {
    return BodyZone(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      numberOfPoints: data.numberOfPoints.present
          ? data.numberOfPoints.value
          : this.numberOfPoints,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyZone(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('numberOfPoints: $numberOfPoints, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    numberOfPoints,
    isEnabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyZone &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.numberOfPoints == this.numberOfPoints &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BodyZonesCompanion extends UpdateCompanion<BodyZone> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<int> numberOfPoints;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BodyZonesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.numberOfPoints = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BodyZonesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.numberOfPoints = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : code = Value(code),
       name = Value(name);
  static Insertable<BodyZone> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<int>? numberOfPoints,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (numberOfPoints != null) 'number_of_points': numberOfPoints,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BodyZonesCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<int>? numberOfPoints,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BodyZonesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      numberOfPoints: numberOfPoints ?? this.numberOfPoints,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (numberOfPoints.present) {
      map['number_of_points'] = Variable<int>(numberOfPoints.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyZonesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('numberOfPoints: $numberOfPoints, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TherapyPlansTable extends TherapyPlans
    with TableInfo<$TherapyPlansTable, TherapyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TherapyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _injectionsPerWeekMeta = const VerificationMeta(
    'injectionsPerWeek',
  );
  @override
  late final GeneratedColumn<int> injectionsPerWeek = GeneratedColumn<int>(
    'injections_per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _weekDaysMeta = const VerificationMeta(
    'weekDays',
  );
  @override
  late final GeneratedColumn<String> weekDays = GeneratedColumn<String>(
    'week_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1,3,5'),
  );
  static const VerificationMeta _preferredTimeMeta = const VerificationMeta(
    'preferredTime',
  );
  @override
  late final GeneratedColumn<String> preferredTime = GeneratedColumn<String>(
    'preferred_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('20:00'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    injectionsPerWeek,
    weekDays,
    preferredTime,
    startDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'therapy_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<TherapyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('injections_per_week')) {
      context.handle(
        _injectionsPerWeekMeta,
        injectionsPerWeek.isAcceptableOrUnknown(
          data['injections_per_week']!,
          _injectionsPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('week_days')) {
      context.handle(
        _weekDaysMeta,
        weekDays.isAcceptableOrUnknown(data['week_days']!, _weekDaysMeta),
      );
    }
    if (data.containsKey('preferred_time')) {
      context.handle(
        _preferredTimeMeta,
        preferredTime.isAcceptableOrUnknown(
          data['preferred_time']!,
          _preferredTimeMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TherapyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TherapyPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      injectionsPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}injections_per_week'],
      )!,
      weekDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_days'],
      )!,
      preferredTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_time'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TherapyPlansTable createAlias(String alias) {
    return $TherapyPlansTable(attachedDatabase, alias);
  }
}

class TherapyPlan extends DataClass implements Insertable<TherapyPlan> {
  final int id;
  final int injectionsPerWeek;
  final String weekDays;
  final String preferredTime;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TherapyPlan({
    required this.id,
    required this.injectionsPerWeek,
    required this.weekDays,
    required this.preferredTime,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['injections_per_week'] = Variable<int>(injectionsPerWeek);
    map['week_days'] = Variable<String>(weekDays);
    map['preferred_time'] = Variable<String>(preferredTime);
    map['start_date'] = Variable<DateTime>(startDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TherapyPlansCompanion toCompanion(bool nullToAbsent) {
    return TherapyPlansCompanion(
      id: Value(id),
      injectionsPerWeek: Value(injectionsPerWeek),
      weekDays: Value(weekDays),
      preferredTime: Value(preferredTime),
      startDate: Value(startDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TherapyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TherapyPlan(
      id: serializer.fromJson<int>(json['id']),
      injectionsPerWeek: serializer.fromJson<int>(json['injectionsPerWeek']),
      weekDays: serializer.fromJson<String>(json['weekDays']),
      preferredTime: serializer.fromJson<String>(json['preferredTime']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'injectionsPerWeek': serializer.toJson<int>(injectionsPerWeek),
      'weekDays': serializer.toJson<String>(weekDays),
      'preferredTime': serializer.toJson<String>(preferredTime),
      'startDate': serializer.toJson<DateTime>(startDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TherapyPlan copyWith({
    int? id,
    int? injectionsPerWeek,
    String? weekDays,
    String? preferredTime,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TherapyPlan(
    id: id ?? this.id,
    injectionsPerWeek: injectionsPerWeek ?? this.injectionsPerWeek,
    weekDays: weekDays ?? this.weekDays,
    preferredTime: preferredTime ?? this.preferredTime,
    startDate: startDate ?? this.startDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TherapyPlan copyWithCompanion(TherapyPlansCompanion data) {
    return TherapyPlan(
      id: data.id.present ? data.id.value : this.id,
      injectionsPerWeek: data.injectionsPerWeek.present
          ? data.injectionsPerWeek.value
          : this.injectionsPerWeek,
      weekDays: data.weekDays.present ? data.weekDays.value : this.weekDays,
      preferredTime: data.preferredTime.present
          ? data.preferredTime.value
          : this.preferredTime,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TherapyPlan(')
          ..write('id: $id, ')
          ..write('injectionsPerWeek: $injectionsPerWeek, ')
          ..write('weekDays: $weekDays, ')
          ..write('preferredTime: $preferredTime, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    injectionsPerWeek,
    weekDays,
    preferredTime,
    startDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TherapyPlan &&
          other.id == this.id &&
          other.injectionsPerWeek == this.injectionsPerWeek &&
          other.weekDays == this.weekDays &&
          other.preferredTime == this.preferredTime &&
          other.startDate == this.startDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TherapyPlansCompanion extends UpdateCompanion<TherapyPlan> {
  final Value<int> id;
  final Value<int> injectionsPerWeek;
  final Value<String> weekDays;
  final Value<String> preferredTime;
  final Value<DateTime> startDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TherapyPlansCompanion({
    this.id = const Value.absent(),
    this.injectionsPerWeek = const Value.absent(),
    this.weekDays = const Value.absent(),
    this.preferredTime = const Value.absent(),
    this.startDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TherapyPlansCompanion.insert({
    this.id = const Value.absent(),
    this.injectionsPerWeek = const Value.absent(),
    this.weekDays = const Value.absent(),
    this.preferredTime = const Value.absent(),
    required DateTime startDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : startDate = Value(startDate);
  static Insertable<TherapyPlan> custom({
    Expression<int>? id,
    Expression<int>? injectionsPerWeek,
    Expression<String>? weekDays,
    Expression<String>? preferredTime,
    Expression<DateTime>? startDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (injectionsPerWeek != null) 'injections_per_week': injectionsPerWeek,
      if (weekDays != null) 'week_days': weekDays,
      if (preferredTime != null) 'preferred_time': preferredTime,
      if (startDate != null) 'start_date': startDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TherapyPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? injectionsPerWeek,
    Value<String>? weekDays,
    Value<String>? preferredTime,
    Value<DateTime>? startDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TherapyPlansCompanion(
      id: id ?? this.id,
      injectionsPerWeek: injectionsPerWeek ?? this.injectionsPerWeek,
      weekDays: weekDays ?? this.weekDays,
      preferredTime: preferredTime ?? this.preferredTime,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (injectionsPerWeek.present) {
      map['injections_per_week'] = Variable<int>(injectionsPerWeek.value);
    }
    if (weekDays.present) {
      map['week_days'] = Variable<String>(weekDays.value);
    }
    if (preferredTime.present) {
      map['preferred_time'] = Variable<String>(preferredTime.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TherapyPlansCompanion(')
          ..write('id: $id, ')
          ..write('injectionsPerWeek: $injectionsPerWeek, ')
          ..write('weekDays: $weekDays, ')
          ..write('preferredTime: $preferredTime, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InjectionsTable extends Injections
    with TableInfo<$InjectionsTable, Injection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InjectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<int> zoneId = GeneratedColumn<int>(
    'zone_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES body_zones (id)',
    ),
  );
  static const VerificationMeta _pointNumberMeta = const VerificationMeta(
    'pointNumber',
  );
  @override
  late final GeneratedColumn<int> pointNumber = GeneratedColumn<int>(
    'point_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointCodeMeta = const VerificationMeta(
    'pointCode',
  );
  @override
  late final GeneratedColumn<String> pointCode = GeneratedColumn<String>(
    'point_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointLabelMeta = const VerificationMeta(
    'pointLabel',
  );
  @override
  late final GeneratedColumn<String> pointLabel = GeneratedColumn<String>(
    'point_label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sideEffectsMeta = const VerificationMeta(
    'sideEffects',
  );
  @override
  late final GeneratedColumn<String> sideEffects = GeneratedColumn<String>(
    'side_effects',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _calendarEventIdMeta = const VerificationMeta(
    'calendarEventId',
  );
  @override
  late final GeneratedColumn<String> calendarEventId = GeneratedColumn<String>(
    'calendar_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    zoneId,
    pointNumber,
    pointCode,
    pointLabel,
    scheduledAt,
    completedAt,
    status,
    notes,
    sideEffects,
    calendarEventId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'injections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Injection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneIdMeta);
    }
    if (data.containsKey('point_number')) {
      context.handle(
        _pointNumberMeta,
        pointNumber.isAcceptableOrUnknown(
          data['point_number']!,
          _pointNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointNumberMeta);
    }
    if (data.containsKey('point_code')) {
      context.handle(
        _pointCodeMeta,
        pointCode.isAcceptableOrUnknown(data['point_code']!, _pointCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_pointCodeMeta);
    }
    if (data.containsKey('point_label')) {
      context.handle(
        _pointLabelMeta,
        pointLabel.isAcceptableOrUnknown(data['point_label']!, _pointLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_pointLabelMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('side_effects')) {
      context.handle(
        _sideEffectsMeta,
        sideEffects.isAcceptableOrUnknown(
          data['side_effects']!,
          _sideEffectsMeta,
        ),
      );
    }
    if (data.containsKey('calendar_event_id')) {
      context.handle(
        _calendarEventIdMeta,
        calendarEventId.isAcceptableOrUnknown(
          data['calendar_event_id']!,
          _calendarEventIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Injection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Injection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone_id'],
      )!,
      pointNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_number'],
      )!,
      pointCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_code'],
      )!,
      pointLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_label'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      sideEffects: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side_effects'],
      )!,
      calendarEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_event_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InjectionsTable createAlias(String alias) {
    return $InjectionsTable(attachedDatabase, alias);
  }
}

class Injection extends DataClass implements Insertable<Injection> {
  final int id;
  final int zoneId;
  final int pointNumber;
  final String pointCode;
  final String pointLabel;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String status;
  final String notes;
  final String sideEffects;
  final String calendarEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Injection({
    required this.id,
    required this.zoneId,
    required this.pointNumber,
    required this.pointCode,
    required this.pointLabel,
    required this.scheduledAt,
    this.completedAt,
    required this.status,
    required this.notes,
    required this.sideEffects,
    required this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['zone_id'] = Variable<int>(zoneId);
    map['point_number'] = Variable<int>(pointNumber);
    map['point_code'] = Variable<String>(pointCode);
    map['point_label'] = Variable<String>(pointLabel);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['status'] = Variable<String>(status);
    map['notes'] = Variable<String>(notes);
    map['side_effects'] = Variable<String>(sideEffects);
    map['calendar_event_id'] = Variable<String>(calendarEventId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InjectionsCompanion toCompanion(bool nullToAbsent) {
    return InjectionsCompanion(
      id: Value(id),
      zoneId: Value(zoneId),
      pointNumber: Value(pointNumber),
      pointCode: Value(pointCode),
      pointLabel: Value(pointLabel),
      scheduledAt: Value(scheduledAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
      notes: Value(notes),
      sideEffects: Value(sideEffects),
      calendarEventId: Value(calendarEventId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Injection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Injection(
      id: serializer.fromJson<int>(json['id']),
      zoneId: serializer.fromJson<int>(json['zoneId']),
      pointNumber: serializer.fromJson<int>(json['pointNumber']),
      pointCode: serializer.fromJson<String>(json['pointCode']),
      pointLabel: serializer.fromJson<String>(json['pointLabel']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String>(json['notes']),
      sideEffects: serializer.fromJson<String>(json['sideEffects']),
      calendarEventId: serializer.fromJson<String>(json['calendarEventId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'zoneId': serializer.toJson<int>(zoneId),
      'pointNumber': serializer.toJson<int>(pointNumber),
      'pointCode': serializer.toJson<String>(pointCode),
      'pointLabel': serializer.toJson<String>(pointLabel),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String>(notes),
      'sideEffects': serializer.toJson<String>(sideEffects),
      'calendarEventId': serializer.toJson<String>(calendarEventId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Injection copyWith({
    int? id,
    int? zoneId,
    int? pointNumber,
    String? pointCode,
    String? pointLabel,
    DateTime? scheduledAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? status,
    String? notes,
    String? sideEffects,
    String? calendarEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Injection(
    id: id ?? this.id,
    zoneId: zoneId ?? this.zoneId,
    pointNumber: pointNumber ?? this.pointNumber,
    pointCode: pointCode ?? this.pointCode,
    pointLabel: pointLabel ?? this.pointLabel,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    sideEffects: sideEffects ?? this.sideEffects,
    calendarEventId: calendarEventId ?? this.calendarEventId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Injection copyWithCompanion(InjectionsCompanion data) {
    return Injection(
      id: data.id.present ? data.id.value : this.id,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      pointNumber: data.pointNumber.present
          ? data.pointNumber.value
          : this.pointNumber,
      pointCode: data.pointCode.present ? data.pointCode.value : this.pointCode,
      pointLabel: data.pointLabel.present
          ? data.pointLabel.value
          : this.pointLabel,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      sideEffects: data.sideEffects.present
          ? data.sideEffects.value
          : this.sideEffects,
      calendarEventId: data.calendarEventId.present
          ? data.calendarEventId.value
          : this.calendarEventId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Injection(')
          ..write('id: $id, ')
          ..write('zoneId: $zoneId, ')
          ..write('pointNumber: $pointNumber, ')
          ..write('pointCode: $pointCode, ')
          ..write('pointLabel: $pointLabel, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('sideEffects: $sideEffects, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    zoneId,
    pointNumber,
    pointCode,
    pointLabel,
    scheduledAt,
    completedAt,
    status,
    notes,
    sideEffects,
    calendarEventId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Injection &&
          other.id == this.id &&
          other.zoneId == this.zoneId &&
          other.pointNumber == this.pointNumber &&
          other.pointCode == this.pointCode &&
          other.pointLabel == this.pointLabel &&
          other.scheduledAt == this.scheduledAt &&
          other.completedAt == this.completedAt &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.sideEffects == this.sideEffects &&
          other.calendarEventId == this.calendarEventId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InjectionsCompanion extends UpdateCompanion<Injection> {
  final Value<int> id;
  final Value<int> zoneId;
  final Value<int> pointNumber;
  final Value<String> pointCode;
  final Value<String> pointLabel;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> completedAt;
  final Value<String> status;
  final Value<String> notes;
  final Value<String> sideEffects;
  final Value<String> calendarEventId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const InjectionsCompanion({
    this.id = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.pointNumber = const Value.absent(),
    this.pointCode = const Value.absent(),
    this.pointLabel = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.sideEffects = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InjectionsCompanion.insert({
    this.id = const Value.absent(),
    required int zoneId,
    required int pointNumber,
    required String pointCode,
    required String pointLabel,
    required DateTime scheduledAt,
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.sideEffects = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : zoneId = Value(zoneId),
       pointNumber = Value(pointNumber),
       pointCode = Value(pointCode),
       pointLabel = Value(pointLabel),
       scheduledAt = Value(scheduledAt);
  static Insertable<Injection> custom({
    Expression<int>? id,
    Expression<int>? zoneId,
    Expression<int>? pointNumber,
    Expression<String>? pointCode,
    Expression<String>? pointLabel,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? completedAt,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? sideEffects,
    Expression<String>? calendarEventId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zoneId != null) 'zone_id': zoneId,
      if (pointNumber != null) 'point_number': pointNumber,
      if (pointCode != null) 'point_code': pointCode,
      if (pointLabel != null) 'point_label': pointLabel,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (sideEffects != null) 'side_effects': sideEffects,
      if (calendarEventId != null) 'calendar_event_id': calendarEventId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InjectionsCompanion copyWith({
    Value<int>? id,
    Value<int>? zoneId,
    Value<int>? pointNumber,
    Value<String>? pointCode,
    Value<String>? pointLabel,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? completedAt,
    Value<String>? status,
    Value<String>? notes,
    Value<String>? sideEffects,
    Value<String>? calendarEventId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return InjectionsCompanion(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      pointNumber: pointNumber ?? this.pointNumber,
      pointCode: pointCode ?? this.pointCode,
      pointLabel: pointLabel ?? this.pointLabel,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sideEffects: sideEffects ?? this.sideEffects,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<int>(zoneId.value);
    }
    if (pointNumber.present) {
      map['point_number'] = Variable<int>(pointNumber.value);
    }
    if (pointCode.present) {
      map['point_code'] = Variable<String>(pointCode.value);
    }
    if (pointLabel.present) {
      map['point_label'] = Variable<String>(pointLabel.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sideEffects.present) {
      map['side_effects'] = Variable<String>(sideEffects.value);
    }
    if (calendarEventId.present) {
      map['calendar_event_id'] = Variable<String>(calendarEventId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InjectionsCompanion(')
          ..write('id: $id, ')
          ..write('zoneId: $zoneId, ')
          ..write('pointNumber: $pointNumber, ')
          ..write('pointCode: $pointCode, ')
          ..write('pointLabel: $pointLabel, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('sideEffects: $sideEffects, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BlacklistedPointsTable extends BlacklistedPoints
    with TableInfo<$BlacklistedPointsTable, BlacklistedPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlacklistedPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pointCodeMeta = const VerificationMeta(
    'pointCode',
  );
  @override
  late final GeneratedColumn<String> pointCode = GeneratedColumn<String>(
    'point_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _pointLabelMeta = const VerificationMeta(
    'pointLabel',
  );
  @override
  late final GeneratedColumn<String> pointLabel = GeneratedColumn<String>(
    'point_label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<int> zoneId = GeneratedColumn<int>(
    'zone_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES body_zones (id)',
    ),
  );
  static const VerificationMeta _pointNumberMeta = const VerificationMeta(
    'pointNumber',
  );
  @override
  late final GeneratedColumn<int> pointNumber = GeneratedColumn<int>(
    'point_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _blacklistedAtMeta = const VerificationMeta(
    'blacklistedAt',
  );
  @override
  late final GeneratedColumn<DateTime> blacklistedAt =
      GeneratedColumn<DateTime>(
        'blacklisted_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pointCode,
    pointLabel,
    zoneId,
    pointNumber,
    reason,
    notes,
    blacklistedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blacklisted_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlacklistedPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('point_code')) {
      context.handle(
        _pointCodeMeta,
        pointCode.isAcceptableOrUnknown(data['point_code']!, _pointCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_pointCodeMeta);
    }
    if (data.containsKey('point_label')) {
      context.handle(
        _pointLabelMeta,
        pointLabel.isAcceptableOrUnknown(data['point_label']!, _pointLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_pointLabelMeta);
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneIdMeta);
    }
    if (data.containsKey('point_number')) {
      context.handle(
        _pointNumberMeta,
        pointNumber.isAcceptableOrUnknown(
          data['point_number']!,
          _pointNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointNumberMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('blacklisted_at')) {
      context.handle(
        _blacklistedAtMeta,
        blacklistedAt.isAcceptableOrUnknown(
          data['blacklisted_at']!,
          _blacklistedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlacklistedPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlacklistedPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pointCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_code'],
      )!,
      pointLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_label'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone_id'],
      )!,
      pointNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_number'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      blacklistedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}blacklisted_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BlacklistedPointsTable createAlias(String alias) {
    return $BlacklistedPointsTable(attachedDatabase, alias);
  }
}

class BlacklistedPoint extends DataClass
    implements Insertable<BlacklistedPoint> {
  final int id;
  final String pointCode;
  final String pointLabel;
  final int zoneId;
  final int pointNumber;
  final String reason;
  final String notes;
  final DateTime blacklistedAt;
  final DateTime createdAt;
  const BlacklistedPoint({
    required this.id,
    required this.pointCode,
    required this.pointLabel,
    required this.zoneId,
    required this.pointNumber,
    required this.reason,
    required this.notes,
    required this.blacklistedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['point_code'] = Variable<String>(pointCode);
    map['point_label'] = Variable<String>(pointLabel);
    map['zone_id'] = Variable<int>(zoneId);
    map['point_number'] = Variable<int>(pointNumber);
    map['reason'] = Variable<String>(reason);
    map['notes'] = Variable<String>(notes);
    map['blacklisted_at'] = Variable<DateTime>(blacklistedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BlacklistedPointsCompanion toCompanion(bool nullToAbsent) {
    return BlacklistedPointsCompanion(
      id: Value(id),
      pointCode: Value(pointCode),
      pointLabel: Value(pointLabel),
      zoneId: Value(zoneId),
      pointNumber: Value(pointNumber),
      reason: Value(reason),
      notes: Value(notes),
      blacklistedAt: Value(blacklistedAt),
      createdAt: Value(createdAt),
    );
  }

  factory BlacklistedPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlacklistedPoint(
      id: serializer.fromJson<int>(json['id']),
      pointCode: serializer.fromJson<String>(json['pointCode']),
      pointLabel: serializer.fromJson<String>(json['pointLabel']),
      zoneId: serializer.fromJson<int>(json['zoneId']),
      pointNumber: serializer.fromJson<int>(json['pointNumber']),
      reason: serializer.fromJson<String>(json['reason']),
      notes: serializer.fromJson<String>(json['notes']),
      blacklistedAt: serializer.fromJson<DateTime>(json['blacklistedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pointCode': serializer.toJson<String>(pointCode),
      'pointLabel': serializer.toJson<String>(pointLabel),
      'zoneId': serializer.toJson<int>(zoneId),
      'pointNumber': serializer.toJson<int>(pointNumber),
      'reason': serializer.toJson<String>(reason),
      'notes': serializer.toJson<String>(notes),
      'blacklistedAt': serializer.toJson<DateTime>(blacklistedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BlacklistedPoint copyWith({
    int? id,
    String? pointCode,
    String? pointLabel,
    int? zoneId,
    int? pointNumber,
    String? reason,
    String? notes,
    DateTime? blacklistedAt,
    DateTime? createdAt,
  }) => BlacklistedPoint(
    id: id ?? this.id,
    pointCode: pointCode ?? this.pointCode,
    pointLabel: pointLabel ?? this.pointLabel,
    zoneId: zoneId ?? this.zoneId,
    pointNumber: pointNumber ?? this.pointNumber,
    reason: reason ?? this.reason,
    notes: notes ?? this.notes,
    blacklistedAt: blacklistedAt ?? this.blacklistedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  BlacklistedPoint copyWithCompanion(BlacklistedPointsCompanion data) {
    return BlacklistedPoint(
      id: data.id.present ? data.id.value : this.id,
      pointCode: data.pointCode.present ? data.pointCode.value : this.pointCode,
      pointLabel: data.pointLabel.present
          ? data.pointLabel.value
          : this.pointLabel,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      pointNumber: data.pointNumber.present
          ? data.pointNumber.value
          : this.pointNumber,
      reason: data.reason.present ? data.reason.value : this.reason,
      notes: data.notes.present ? data.notes.value : this.notes,
      blacklistedAt: data.blacklistedAt.present
          ? data.blacklistedAt.value
          : this.blacklistedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlacklistedPoint(')
          ..write('id: $id, ')
          ..write('pointCode: $pointCode, ')
          ..write('pointLabel: $pointLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pointNumber: $pointNumber, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('blacklistedAt: $blacklistedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pointCode,
    pointLabel,
    zoneId,
    pointNumber,
    reason,
    notes,
    blacklistedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlacklistedPoint &&
          other.id == this.id &&
          other.pointCode == this.pointCode &&
          other.pointLabel == this.pointLabel &&
          other.zoneId == this.zoneId &&
          other.pointNumber == this.pointNumber &&
          other.reason == this.reason &&
          other.notes == this.notes &&
          other.blacklistedAt == this.blacklistedAt &&
          other.createdAt == this.createdAt);
}

class BlacklistedPointsCompanion extends UpdateCompanion<BlacklistedPoint> {
  final Value<int> id;
  final Value<String> pointCode;
  final Value<String> pointLabel;
  final Value<int> zoneId;
  final Value<int> pointNumber;
  final Value<String> reason;
  final Value<String> notes;
  final Value<DateTime> blacklistedAt;
  final Value<DateTime> createdAt;
  const BlacklistedPointsCompanion({
    this.id = const Value.absent(),
    this.pointCode = const Value.absent(),
    this.pointLabel = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.pointNumber = const Value.absent(),
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
    this.blacklistedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BlacklistedPointsCompanion.insert({
    this.id = const Value.absent(),
    required String pointCode,
    required String pointLabel,
    required int zoneId,
    required int pointNumber,
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
    this.blacklistedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : pointCode = Value(pointCode),
       pointLabel = Value(pointLabel),
       zoneId = Value(zoneId),
       pointNumber = Value(pointNumber);
  static Insertable<BlacklistedPoint> custom({
    Expression<int>? id,
    Expression<String>? pointCode,
    Expression<String>? pointLabel,
    Expression<int>? zoneId,
    Expression<int>? pointNumber,
    Expression<String>? reason,
    Expression<String>? notes,
    Expression<DateTime>? blacklistedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pointCode != null) 'point_code': pointCode,
      if (pointLabel != null) 'point_label': pointLabel,
      if (zoneId != null) 'zone_id': zoneId,
      if (pointNumber != null) 'point_number': pointNumber,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (blacklistedAt != null) 'blacklisted_at': blacklistedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BlacklistedPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? pointCode,
    Value<String>? pointLabel,
    Value<int>? zoneId,
    Value<int>? pointNumber,
    Value<String>? reason,
    Value<String>? notes,
    Value<DateTime>? blacklistedAt,
    Value<DateTime>? createdAt,
  }) {
    return BlacklistedPointsCompanion(
      id: id ?? this.id,
      pointCode: pointCode ?? this.pointCode,
      pointLabel: pointLabel ?? this.pointLabel,
      zoneId: zoneId ?? this.zoneId,
      pointNumber: pointNumber ?? this.pointNumber,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      blacklistedAt: blacklistedAt ?? this.blacklistedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pointCode.present) {
      map['point_code'] = Variable<String>(pointCode.value);
    }
    if (pointLabel.present) {
      map['point_label'] = Variable<String>(pointLabel.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<int>(zoneId.value);
    }
    if (pointNumber.present) {
      map['point_number'] = Variable<int>(pointNumber.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (blacklistedAt.present) {
      map['blacklisted_at'] = Variable<DateTime>(blacklistedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlacklistedPointsCompanion(')
          ..write('id: $id, ')
          ..write('pointCode: $pointCode, ')
          ..write('pointLabel: $pointLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pointNumber: $pointNumber, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('blacklistedAt: $blacklistedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.id,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => AppSetting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _biometricEnabledMeta = const VerificationMeta(
    'biometricEnabled',
  );
  @override
  late final GeneratedColumn<bool> biometricEnabled = GeneratedColumn<bool>(
    'biometric_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometric_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _calendarSyncEnabledMeta =
      const VerificationMeta('calendarSyncEnabled');
  @override
  late final GeneratedColumn<bool> calendarSyncEnabled = GeneratedColumn<bool>(
    'calendar_sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("calendar_sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    email,
    photoUrl,
    biometricEnabled,
    notificationsEnabled,
    calendarSyncEnabled,
    themeMode,
    lastBackupAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('biometric_enabled')) {
      context.handle(
        _biometricEnabledMeta,
        biometricEnabled.isAcceptableOrUnknown(
          data['biometric_enabled']!,
          _biometricEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('calendar_sync_enabled')) {
      context.handle(
        _calendarSyncEnabledMeta,
        calendarSyncEnabled.isAcceptableOrUnknown(
          data['calendar_sync_enabled']!,
          _calendarSyncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      )!,
      biometricEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometric_enabled'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      calendarSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}calendar_sync_enabled'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_backup_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final bool calendarSyncEnabled;
  final String themeMode;
  final DateTime? lastBackupAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.biometricEnabled,
    required this.notificationsEnabled,
    required this.calendarSyncEnabled,
    required this.themeMode,
    this.lastBackupAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['email'] = Variable<String>(email);
    map['photo_url'] = Variable<String>(photoUrl);
    map['biometric_enabled'] = Variable<bool>(biometricEnabled);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['calendar_sync_enabled'] = Variable<bool>(calendarSyncEnabled);
    map['theme_mode'] = Variable<String>(themeMode);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      email: Value(email),
      photoUrl: Value(photoUrl),
      biometricEnabled: Value(biometricEnabled),
      notificationsEnabled: Value(notificationsEnabled),
      calendarSyncEnabled: Value(calendarSyncEnabled),
      themeMode: Value(themeMode),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      email: serializer.fromJson<String>(json['email']),
      photoUrl: serializer.fromJson<String>(json['photoUrl']),
      biometricEnabled: serializer.fromJson<bool>(json['biometricEnabled']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      calendarSyncEnabled: serializer.fromJson<bool>(
        json['calendarSyncEnabled'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'email': serializer.toJson<String>(email),
      'photoUrl': serializer.toJson<String>(photoUrl),
      'biometricEnabled': serializer.toJson<bool>(biometricEnabled),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'calendarSyncEnabled': serializer.toJson<bool>(calendarSyncEnabled),
      'themeMode': serializer.toJson<String>(themeMode),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfile copyWith({
    int? id,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    bool? calendarSyncEnabled,
    String? themeMode,
    Value<DateTime?> lastBackupAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
    themeMode: themeMode ?? this.themeMode,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      biometricEnabled: data.biometricEnabled.present
          ? data.biometricEnabled.value
          : this.biometricEnabled,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      calendarSyncEnabled: data.calendarSyncEnabled.present
          ? data.calendarSyncEnabled.value
          : this.calendarSyncEnabled,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('calendarSyncEnabled: $calendarSyncEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    photoUrl,
    biometricEnabled,
    notificationsEnabled,
    calendarSyncEnabled,
    themeMode,
    lastBackupAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.photoUrl == this.photoUrl &&
          other.biometricEnabled == this.biometricEnabled &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.calendarSyncEnabled == this.calendarSyncEnabled &&
          other.themeMode == this.themeMode &&
          other.lastBackupAt == this.lastBackupAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> email;
  final Value<String> photoUrl;
  final Value<bool> biometricEnabled;
  final Value<bool> notificationsEnabled;
  final Value<bool> calendarSyncEnabled;
  final Value<String> themeMode;
  final Value<DateTime?> lastBackupAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.calendarSyncEnabled = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.calendarSyncEnabled = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? photoUrl,
    Expression<bool>? biometricEnabled,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? calendarSyncEnabled,
    Expression<String>? themeMode,
    Expression<DateTime>? lastBackupAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (calendarSyncEnabled != null)
        'calendar_sync_enabled': calendarSyncEnabled,
      if (themeMode != null) 'theme_mode': themeMode,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? email,
    Value<String>? photoUrl,
    Value<bool>? biometricEnabled,
    Value<bool>? notificationsEnabled,
    Value<bool>? calendarSyncEnabled,
    Value<String>? themeMode,
    Value<DateTime?>? lastBackupAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      themeMode: themeMode ?? this.themeMode,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (biometricEnabled.present) {
      map['biometric_enabled'] = Variable<bool>(biometricEnabled.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (calendarSyncEnabled.present) {
      map['calendar_sync_enabled'] = Variable<bool>(calendarSyncEnabled.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('calendarSyncEnabled: $calendarSyncEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BodyZonesTable bodyZones = $BodyZonesTable(this);
  late final $TherapyPlansTable therapyPlans = $TherapyPlansTable(this);
  late final $InjectionsTable injections = $InjectionsTable(this);
  late final $BlacklistedPointsTable blacklistedPoints =
      $BlacklistedPointsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bodyZones,
    therapyPlans,
    injections,
    blacklistedPoints,
    appSettings,
    userProfiles,
  ];
}

typedef $$BodyZonesTableCreateCompanionBuilder =
    BodyZonesCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      Value<int> numberOfPoints,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BodyZonesTableUpdateCompanionBuilder =
    BodyZonesCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<int> numberOfPoints,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BodyZonesTableReferences
    extends BaseReferences<_$AppDatabase, $BodyZonesTable, BodyZone> {
  $$BodyZonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InjectionsTable, List<Injection>>
  _injectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.injections,
    aliasName: $_aliasNameGenerator(db.bodyZones.id, db.injections.zoneId),
  );

  $$InjectionsTableProcessedTableManager get injectionsRefs {
    final manager = $$InjectionsTableTableManager(
      $_db,
      $_db.injections,
    ).filter((f) => f.zoneId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_injectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BlacklistedPointsTable, List<BlacklistedPoint>>
  _blacklistedPointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.blacklistedPoints,
        aliasName: $_aliasNameGenerator(
          db.bodyZones.id,
          db.blacklistedPoints.zoneId,
        ),
      );

  $$BlacklistedPointsTableProcessedTableManager get blacklistedPointsRefs {
    final manager = $$BlacklistedPointsTableTableManager(
      $_db,
      $_db.blacklistedPoints,
    ).filter((f) => f.zoneId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _blacklistedPointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BodyZonesTableFilterComposer
    extends Composer<_$AppDatabase, $BodyZonesTable> {
  $$BodyZonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfPoints => $composableBuilder(
    column: $table.numberOfPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> injectionsRefs(
    Expression<bool> Function($$InjectionsTableFilterComposer f) f,
  ) {
    final $$InjectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.injections,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InjectionsTableFilterComposer(
            $db: $db,
            $table: $db.injections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> blacklistedPointsRefs(
    Expression<bool> Function($$BlacklistedPointsTableFilterComposer f) f,
  ) {
    final $$BlacklistedPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blacklistedPoints,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlacklistedPointsTableFilterComposer(
            $db: $db,
            $table: $db.blacklistedPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BodyZonesTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyZonesTable> {
  $$BodyZonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfPoints => $composableBuilder(
    column: $table.numberOfPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyZonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyZonesTable> {
  $$BodyZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get numberOfPoints => $composableBuilder(
    column: $table.numberOfPoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> injectionsRefs<T extends Object>(
    Expression<T> Function($$InjectionsTableAnnotationComposer a) f,
  ) {
    final $$InjectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.injections,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InjectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.injections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> blacklistedPointsRefs<T extends Object>(
    Expression<T> Function($$BlacklistedPointsTableAnnotationComposer a) f,
  ) {
    final $$BlacklistedPointsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.blacklistedPoints,
          getReferencedColumn: (t) => t.zoneId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BlacklistedPointsTableAnnotationComposer(
                $db: $db,
                $table: $db.blacklistedPoints,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BodyZonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyZonesTable,
          BodyZone,
          $$BodyZonesTableFilterComposer,
          $$BodyZonesTableOrderingComposer,
          $$BodyZonesTableAnnotationComposer,
          $$BodyZonesTableCreateCompanionBuilder,
          $$BodyZonesTableUpdateCompanionBuilder,
          (BodyZone, $$BodyZonesTableReferences),
          BodyZone,
          PrefetchHooks Function({
            bool injectionsRefs,
            bool blacklistedPointsRefs,
          })
        > {
  $$BodyZonesTableTableManager(_$AppDatabase db, $BodyZonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> numberOfPoints = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyZonesCompanion(
                id: id,
                code: code,
                name: name,
                numberOfPoints: numberOfPoints,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                Value<int> numberOfPoints = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyZonesCompanion.insert(
                id: id,
                code: code,
                name: name,
                numberOfPoints: numberOfPoints,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BodyZonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({injectionsRefs = false, blacklistedPointsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (injectionsRefs) db.injections,
                    if (blacklistedPointsRefs) db.blacklistedPoints,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (injectionsRefs)
                        await $_getPrefetchedData<
                          BodyZone,
                          $BodyZonesTable,
                          Injection
                        >(
                          currentTable: table,
                          referencedTable: $$BodyZonesTableReferences
                              ._injectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BodyZonesTableReferences(
                                db,
                                table,
                                p0,
                              ).injectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.zoneId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (blacklistedPointsRefs)
                        await $_getPrefetchedData<
                          BodyZone,
                          $BodyZonesTable,
                          BlacklistedPoint
                        >(
                          currentTable: table,
                          referencedTable: $$BodyZonesTableReferences
                              ._blacklistedPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BodyZonesTableReferences(
                                db,
                                table,
                                p0,
                              ).blacklistedPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.zoneId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BodyZonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyZonesTable,
      BodyZone,
      $$BodyZonesTableFilterComposer,
      $$BodyZonesTableOrderingComposer,
      $$BodyZonesTableAnnotationComposer,
      $$BodyZonesTableCreateCompanionBuilder,
      $$BodyZonesTableUpdateCompanionBuilder,
      (BodyZone, $$BodyZonesTableReferences),
      BodyZone,
      PrefetchHooks Function({bool injectionsRefs, bool blacklistedPointsRefs})
    >;
typedef $$TherapyPlansTableCreateCompanionBuilder =
    TherapyPlansCompanion Function({
      Value<int> id,
      Value<int> injectionsPerWeek,
      Value<String> weekDays,
      Value<String> preferredTime,
      required DateTime startDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TherapyPlansTableUpdateCompanionBuilder =
    TherapyPlansCompanion Function({
      Value<int> id,
      Value<int> injectionsPerWeek,
      Value<String> weekDays,
      Value<String> preferredTime,
      Value<DateTime> startDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$TherapyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $TherapyPlansTable> {
  $$TherapyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get injectionsPerWeek => $composableBuilder(
    column: $table.injectionsPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekDays => $composableBuilder(
    column: $table.weekDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredTime => $composableBuilder(
    column: $table.preferredTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TherapyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $TherapyPlansTable> {
  $$TherapyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get injectionsPerWeek => $composableBuilder(
    column: $table.injectionsPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekDays => $composableBuilder(
    column: $table.weekDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredTime => $composableBuilder(
    column: $table.preferredTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TherapyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $TherapyPlansTable> {
  $$TherapyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get injectionsPerWeek => $composableBuilder(
    column: $table.injectionsPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weekDays =>
      $composableBuilder(column: $table.weekDays, builder: (column) => column);

  GeneratedColumn<String> get preferredTime => $composableBuilder(
    column: $table.preferredTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TherapyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TherapyPlansTable,
          TherapyPlan,
          $$TherapyPlansTableFilterComposer,
          $$TherapyPlansTableOrderingComposer,
          $$TherapyPlansTableAnnotationComposer,
          $$TherapyPlansTableCreateCompanionBuilder,
          $$TherapyPlansTableUpdateCompanionBuilder,
          (
            TherapyPlan,
            BaseReferences<_$AppDatabase, $TherapyPlansTable, TherapyPlan>,
          ),
          TherapyPlan,
          PrefetchHooks Function()
        > {
  $$TherapyPlansTableTableManager(_$AppDatabase db, $TherapyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TherapyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TherapyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TherapyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> injectionsPerWeek = const Value.absent(),
                Value<String> weekDays = const Value.absent(),
                Value<String> preferredTime = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TherapyPlansCompanion(
                id: id,
                injectionsPerWeek: injectionsPerWeek,
                weekDays: weekDays,
                preferredTime: preferredTime,
                startDate: startDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> injectionsPerWeek = const Value.absent(),
                Value<String> weekDays = const Value.absent(),
                Value<String> preferredTime = const Value.absent(),
                required DateTime startDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TherapyPlansCompanion.insert(
                id: id,
                injectionsPerWeek: injectionsPerWeek,
                weekDays: weekDays,
                preferredTime: preferredTime,
                startDate: startDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TherapyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TherapyPlansTable,
      TherapyPlan,
      $$TherapyPlansTableFilterComposer,
      $$TherapyPlansTableOrderingComposer,
      $$TherapyPlansTableAnnotationComposer,
      $$TherapyPlansTableCreateCompanionBuilder,
      $$TherapyPlansTableUpdateCompanionBuilder,
      (
        TherapyPlan,
        BaseReferences<_$AppDatabase, $TherapyPlansTable, TherapyPlan>,
      ),
      TherapyPlan,
      PrefetchHooks Function()
    >;
typedef $$InjectionsTableCreateCompanionBuilder =
    InjectionsCompanion Function({
      Value<int> id,
      required int zoneId,
      required int pointNumber,
      required String pointCode,
      required String pointLabel,
      required DateTime scheduledAt,
      Value<DateTime?> completedAt,
      Value<String> status,
      Value<String> notes,
      Value<String> sideEffects,
      Value<String> calendarEventId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$InjectionsTableUpdateCompanionBuilder =
    InjectionsCompanion Function({
      Value<int> id,
      Value<int> zoneId,
      Value<int> pointNumber,
      Value<String> pointCode,
      Value<String> pointLabel,
      Value<DateTime> scheduledAt,
      Value<DateTime?> completedAt,
      Value<String> status,
      Value<String> notes,
      Value<String> sideEffects,
      Value<String> calendarEventId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$InjectionsTableReferences
    extends BaseReferences<_$AppDatabase, $InjectionsTable, Injection> {
  $$InjectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BodyZonesTable _zoneIdTable(_$AppDatabase db) => db.bodyZones
      .createAlias($_aliasNameGenerator(db.injections.zoneId, db.bodyZones.id));

  $$BodyZonesTableProcessedTableManager get zoneId {
    final $_column = $_itemColumn<int>('zone_id')!;

    final manager = $$BodyZonesTableTableManager(
      $_db,
      $_db.bodyZones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_zoneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InjectionsTableFilterComposer
    extends Composer<_$AppDatabase, $InjectionsTable> {
  $$InjectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointCode => $composableBuilder(
    column: $table.pointCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sideEffects => $composableBuilder(
    column: $table.sideEffects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BodyZonesTableFilterComposer get zoneId {
    final $$BodyZonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableFilterComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InjectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InjectionsTable> {
  $$InjectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointCode => $composableBuilder(
    column: $table.pointCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sideEffects => $composableBuilder(
    column: $table.sideEffects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BodyZonesTableOrderingComposer get zoneId {
    final $$BodyZonesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableOrderingComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InjectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InjectionsTable> {
  $$InjectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pointCode =>
      $composableBuilder(column: $table.pointCode, builder: (column) => column);

  GeneratedColumn<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sideEffects => $composableBuilder(
    column: $table.sideEffects,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BodyZonesTableAnnotationComposer get zoneId {
    final $$BodyZonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableAnnotationComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InjectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InjectionsTable,
          Injection,
          $$InjectionsTableFilterComposer,
          $$InjectionsTableOrderingComposer,
          $$InjectionsTableAnnotationComposer,
          $$InjectionsTableCreateCompanionBuilder,
          $$InjectionsTableUpdateCompanionBuilder,
          (Injection, $$InjectionsTableReferences),
          Injection,
          PrefetchHooks Function({bool zoneId})
        > {
  $$InjectionsTableTableManager(_$AppDatabase db, $InjectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InjectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InjectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InjectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> zoneId = const Value.absent(),
                Value<int> pointNumber = const Value.absent(),
                Value<String> pointCode = const Value.absent(),
                Value<String> pointLabel = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> sideEffects = const Value.absent(),
                Value<String> calendarEventId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InjectionsCompanion(
                id: id,
                zoneId: zoneId,
                pointNumber: pointNumber,
                pointCode: pointCode,
                pointLabel: pointLabel,
                scheduledAt: scheduledAt,
                completedAt: completedAt,
                status: status,
                notes: notes,
                sideEffects: sideEffects,
                calendarEventId: calendarEventId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int zoneId,
                required int pointNumber,
                required String pointCode,
                required String pointLabel,
                required DateTime scheduledAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> sideEffects = const Value.absent(),
                Value<String> calendarEventId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InjectionsCompanion.insert(
                id: id,
                zoneId: zoneId,
                pointNumber: pointNumber,
                pointCode: pointCode,
                pointLabel: pointLabel,
                scheduledAt: scheduledAt,
                completedAt: completedAt,
                status: status,
                notes: notes,
                sideEffects: sideEffects,
                calendarEventId: calendarEventId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InjectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({zoneId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (zoneId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.zoneId,
                                referencedTable: $$InjectionsTableReferences
                                    ._zoneIdTable(db),
                                referencedColumn: $$InjectionsTableReferences
                                    ._zoneIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InjectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InjectionsTable,
      Injection,
      $$InjectionsTableFilterComposer,
      $$InjectionsTableOrderingComposer,
      $$InjectionsTableAnnotationComposer,
      $$InjectionsTableCreateCompanionBuilder,
      $$InjectionsTableUpdateCompanionBuilder,
      (Injection, $$InjectionsTableReferences),
      Injection,
      PrefetchHooks Function({bool zoneId})
    >;
typedef $$BlacklistedPointsTableCreateCompanionBuilder =
    BlacklistedPointsCompanion Function({
      Value<int> id,
      required String pointCode,
      required String pointLabel,
      required int zoneId,
      required int pointNumber,
      Value<String> reason,
      Value<String> notes,
      Value<DateTime> blacklistedAt,
      Value<DateTime> createdAt,
    });
typedef $$BlacklistedPointsTableUpdateCompanionBuilder =
    BlacklistedPointsCompanion Function({
      Value<int> id,
      Value<String> pointCode,
      Value<String> pointLabel,
      Value<int> zoneId,
      Value<int> pointNumber,
      Value<String> reason,
      Value<String> notes,
      Value<DateTime> blacklistedAt,
      Value<DateTime> createdAt,
    });

final class $$BlacklistedPointsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BlacklistedPointsTable,
          BlacklistedPoint
        > {
  $$BlacklistedPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BodyZonesTable _zoneIdTable(_$AppDatabase db) =>
      db.bodyZones.createAlias(
        $_aliasNameGenerator(db.blacklistedPoints.zoneId, db.bodyZones.id),
      );

  $$BodyZonesTableProcessedTableManager get zoneId {
    final $_column = $_itemColumn<int>('zone_id')!;

    final manager = $$BodyZonesTableTableManager(
      $_db,
      $_db.bodyZones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_zoneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BlacklistedPointsTableFilterComposer
    extends Composer<_$AppDatabase, $BlacklistedPointsTable> {
  $$BlacklistedPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointCode => $composableBuilder(
    column: $table.pointCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get blacklistedAt => $composableBuilder(
    column: $table.blacklistedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BodyZonesTableFilterComposer get zoneId {
    final $$BodyZonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableFilterComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlacklistedPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlacklistedPointsTable> {
  $$BlacklistedPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointCode => $composableBuilder(
    column: $table.pointCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get blacklistedAt => $composableBuilder(
    column: $table.blacklistedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BodyZonesTableOrderingComposer get zoneId {
    final $$BodyZonesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableOrderingComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlacklistedPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlacklistedPointsTable> {
  $$BlacklistedPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pointCode =>
      $composableBuilder(column: $table.pointCode, builder: (column) => column);

  GeneratedColumn<String> get pointLabel => $composableBuilder(
    column: $table.pointLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointNumber => $composableBuilder(
    column: $table.pointNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get blacklistedAt => $composableBuilder(
    column: $table.blacklistedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BodyZonesTableAnnotationComposer get zoneId {
    final $$BodyZonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.bodyZones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyZonesTableAnnotationComposer(
            $db: $db,
            $table: $db.bodyZones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlacklistedPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlacklistedPointsTable,
          BlacklistedPoint,
          $$BlacklistedPointsTableFilterComposer,
          $$BlacklistedPointsTableOrderingComposer,
          $$BlacklistedPointsTableAnnotationComposer,
          $$BlacklistedPointsTableCreateCompanionBuilder,
          $$BlacklistedPointsTableUpdateCompanionBuilder,
          (BlacklistedPoint, $$BlacklistedPointsTableReferences),
          BlacklistedPoint,
          PrefetchHooks Function({bool zoneId})
        > {
  $$BlacklistedPointsTableTableManager(
    _$AppDatabase db,
    $BlacklistedPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlacklistedPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlacklistedPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlacklistedPointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pointCode = const Value.absent(),
                Value<String> pointLabel = const Value.absent(),
                Value<int> zoneId = const Value.absent(),
                Value<int> pointNumber = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> blacklistedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlacklistedPointsCompanion(
                id: id,
                pointCode: pointCode,
                pointLabel: pointLabel,
                zoneId: zoneId,
                pointNumber: pointNumber,
                reason: reason,
                notes: notes,
                blacklistedAt: blacklistedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String pointCode,
                required String pointLabel,
                required int zoneId,
                required int pointNumber,
                Value<String> reason = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> blacklistedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlacklistedPointsCompanion.insert(
                id: id,
                pointCode: pointCode,
                pointLabel: pointLabel,
                zoneId: zoneId,
                pointNumber: pointNumber,
                reason: reason,
                notes: notes,
                blacklistedAt: blacklistedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BlacklistedPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({zoneId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (zoneId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.zoneId,
                                referencedTable:
                                    $$BlacklistedPointsTableReferences
                                        ._zoneIdTable(db),
                                referencedColumn:
                                    $$BlacklistedPointsTableReferences
                                        ._zoneIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BlacklistedPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlacklistedPointsTable,
      BlacklistedPoint,
      $$BlacklistedPointsTableFilterComposer,
      $$BlacklistedPointsTableOrderingComposer,
      $$BlacklistedPointsTableAnnotationComposer,
      $$BlacklistedPointsTableCreateCompanionBuilder,
      $$BlacklistedPointsTableUpdateCompanionBuilder,
      (BlacklistedPoint, $$BlacklistedPointsTableReferences),
      BlacklistedPoint,
      PrefetchHooks Function({bool zoneId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String> email,
      Value<String> photoUrl,
      Value<bool> biometricEnabled,
      Value<bool> notificationsEnabled,
      Value<bool> calendarSyncEnabled,
      Value<String> themeMode,
      Value<DateTime?> lastBackupAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String> email,
      Value<String> photoUrl,
      Value<bool> biometricEnabled,
      Value<bool> notificationsEnabled,
      Value<bool> calendarSyncEnabled,
      Value<String> themeMode,
      Value<DateTime?> lastBackupAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get calendarSyncEnabled => $composableBuilder(
    column: $table.calendarSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get calendarSyncEnabled => $composableBuilder(
    column: $table.calendarSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get calendarSyncEnabled => $composableBuilder(
    column: $table.calendarSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> calendarSyncEnabled = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                displayName: displayName,
                email: email,
                photoUrl: photoUrl,
                biometricEnabled: biometricEnabled,
                notificationsEnabled: notificationsEnabled,
                calendarSyncEnabled: calendarSyncEnabled,
                themeMode: themeMode,
                lastBackupAt: lastBackupAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> calendarSyncEnabled = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                email: email,
                photoUrl: photoUrl,
                biometricEnabled: biometricEnabled,
                notificationsEnabled: notificationsEnabled,
                calendarSyncEnabled: calendarSyncEnabled,
                themeMode: themeMode,
                lastBackupAt: lastBackupAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BodyZonesTableTableManager get bodyZones =>
      $$BodyZonesTableTableManager(_db, _db.bodyZones);
  $$TherapyPlansTableTableManager get therapyPlans =>
      $$TherapyPlansTableTableManager(_db, _db.therapyPlans);
  $$InjectionsTableTableManager get injections =>
      $$InjectionsTableTableManager(_db, _db.injections);
  $$BlacklistedPointsTableTableManager get blacklistedPoints =>
      $$BlacklistedPointsTableTableManager(_db, _db.blacklistedPoints);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
}
