// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EsmaNamesTable extends EsmaNames
    with TableInfo<$EsmaNamesTable, EsmaName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EsmaNamesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, order, name, arabic, meaning];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'esma_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<EsmaName> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EsmaName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EsmaName(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
    );
  }

  @override
  $EsmaNamesTable createAlias(String alias) {
    return $EsmaNamesTable(attachedDatabase, alias);
  }
}

class EsmaName extends DataClass implements Insertable<EsmaName> {
  final int id;
  final int order;
  final String name;
  final String arabic;
  final String meaning;
  const EsmaName({
    required this.id,
    required this.order,
    required this.name,
    required this.arabic,
    required this.meaning,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order'] = Variable<int>(order);
    map['name'] = Variable<String>(name);
    map['arabic'] = Variable<String>(arabic);
    map['meaning'] = Variable<String>(meaning);
    return map;
  }

  EsmaNamesCompanion toCompanion(bool nullToAbsent) {
    return EsmaNamesCompanion(
      id: Value(id),
      order: Value(order),
      name: Value(name),
      arabic: Value(arabic),
      meaning: Value(meaning),
    );
  }

  factory EsmaName.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EsmaName(
      id: serializer.fromJson<int>(json['id']),
      order: serializer.fromJson<int>(json['order']),
      name: serializer.fromJson<String>(json['name']),
      arabic: serializer.fromJson<String>(json['arabic']),
      meaning: serializer.fromJson<String>(json['meaning']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'order': serializer.toJson<int>(order),
      'name': serializer.toJson<String>(name),
      'arabic': serializer.toJson<String>(arabic),
      'meaning': serializer.toJson<String>(meaning),
    };
  }

  EsmaName copyWith({
    int? id,
    int? order,
    String? name,
    String? arabic,
    String? meaning,
  }) => EsmaName(
    id: id ?? this.id,
    order: order ?? this.order,
    name: name ?? this.name,
    arabic: arabic ?? this.arabic,
    meaning: meaning ?? this.meaning,
  );
  EsmaName copyWithCompanion(EsmaNamesCompanion data) {
    return EsmaName(
      id: data.id.present ? data.id.value : this.id,
      order: data.order.present ? data.order.value : this.order,
      name: data.name.present ? data.name.value : this.name,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EsmaName(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('name: $name, ')
          ..write('arabic: $arabic, ')
          ..write('meaning: $meaning')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, order, name, arabic, meaning);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EsmaName &&
          other.id == this.id &&
          other.order == this.order &&
          other.name == this.name &&
          other.arabic == this.arabic &&
          other.meaning == this.meaning);
}

class EsmaNamesCompanion extends UpdateCompanion<EsmaName> {
  final Value<int> id;
  final Value<int> order;
  final Value<String> name;
  final Value<String> arabic;
  final Value<String> meaning;
  const EsmaNamesCompanion({
    this.id = const Value.absent(),
    this.order = const Value.absent(),
    this.name = const Value.absent(),
    this.arabic = const Value.absent(),
    this.meaning = const Value.absent(),
  });
  EsmaNamesCompanion.insert({
    this.id = const Value.absent(),
    required int order,
    required String name,
    required String arabic,
    required String meaning,
  }) : order = Value(order),
       name = Value(name),
       arabic = Value(arabic),
       meaning = Value(meaning);
  static Insertable<EsmaName> custom({
    Expression<int>? id,
    Expression<int>? order,
    Expression<String>? name,
    Expression<String>? arabic,
    Expression<String>? meaning,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (order != null) 'order': order,
      if (name != null) 'name': name,
      if (arabic != null) 'arabic': arabic,
      if (meaning != null) 'meaning': meaning,
    });
  }

  EsmaNamesCompanion copyWith({
    Value<int>? id,
    Value<int>? order,
    Value<String>? name,
    Value<String>? arabic,
    Value<String>? meaning,
  }) {
    return EsmaNamesCompanion(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      arabic: arabic ?? this.arabic,
      meaning: meaning ?? this.meaning,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EsmaNamesCompanion(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('name: $name, ')
          ..write('arabic: $arabic, ')
          ..write('meaning: $meaning')
          ..write(')'))
        .toString();
  }
}

class $DuasTable extends Duas with TableInfo<$DuasTable, Dua> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuasTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latinMeta = const VerificationMeta('latin');
  @override
  late final GeneratedColumn<String> latin = GeneratedColumn<String>(
    'latin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    category,
    arabic,
    latin,
    body,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dua> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('latin')) {
      context.handle(
        _latinMeta,
        latin.isAcceptableOrUnknown(data['latin']!, _latinMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dua map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dua(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      latin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latin'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DuasTable createAlias(String alias) {
    return $DuasTable(attachedDatabase, alias);
  }
}

class Dua extends DataClass implements Insertable<Dua> {
  final int id;
  final String title;
  final String category;
  final String arabic;
  final String latin;
  final String body;
  final String source;
  const Dua({
    required this.id,
    required this.title,
    required this.category,
    required this.arabic,
    required this.latin,
    required this.body,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['arabic'] = Variable<String>(arabic);
    map['latin'] = Variable<String>(latin);
    map['body'] = Variable<String>(body);
    map['source'] = Variable<String>(source);
    return map;
  }

  DuasCompanion toCompanion(bool nullToAbsent) {
    return DuasCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      arabic: Value(arabic),
      latin: Value(latin),
      body: Value(body),
      source: Value(source),
    );
  }

  factory Dua.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dua(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      arabic: serializer.fromJson<String>(json['arabic']),
      latin: serializer.fromJson<String>(json['latin']),
      body: serializer.fromJson<String>(json['body']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'arabic': serializer.toJson<String>(arabic),
      'latin': serializer.toJson<String>(latin),
      'body': serializer.toJson<String>(body),
      'source': serializer.toJson<String>(source),
    };
  }

  Dua copyWith({
    int? id,
    String? title,
    String? category,
    String? arabic,
    String? latin,
    String? body,
    String? source,
  }) => Dua(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    arabic: arabic ?? this.arabic,
    latin: latin ?? this.latin,
    body: body ?? this.body,
    source: source ?? this.source,
  );
  Dua copyWithCompanion(DuasCompanion data) {
    return Dua(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      latin: data.latin.present ? data.latin.value : this.latin,
      body: data.body.present ? data.body.value : this.body,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dua(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('arabic: $arabic, ')
          ..write('latin: $latin, ')
          ..write('body: $body, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, category, arabic, latin, body, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dua &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.arabic == this.arabic &&
          other.latin == this.latin &&
          other.body == this.body &&
          other.source == this.source);
}

class DuasCompanion extends UpdateCompanion<Dua> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> arabic;
  final Value<String> latin;
  final Value<String> body;
  final Value<String> source;
  const DuasCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.arabic = const Value.absent(),
    this.latin = const Value.absent(),
    this.body = const Value.absent(),
    this.source = const Value.absent(),
  });
  DuasCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String category,
    required String arabic,
    this.latin = const Value.absent(),
    required String body,
    this.source = const Value.absent(),
  }) : title = Value(title),
       category = Value(category),
       arabic = Value(arabic),
       body = Value(body);
  static Insertable<Dua> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? arabic,
    Expression<String>? latin,
    Expression<String>? body,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (arabic != null) 'arabic': arabic,
      if (latin != null) 'latin': latin,
      if (body != null) 'body': body,
      if (source != null) 'source': source,
    });
  }

  DuasCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? category,
    Value<String>? arabic,
    Value<String>? latin,
    Value<String>? body,
    Value<String>? source,
  }) {
    return DuasCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      arabic: arabic ?? this.arabic,
      latin: latin ?? this.latin,
      body: body ?? this.body,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (latin.present) {
      map['latin'] = Variable<String>(latin.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuasCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('arabic: $arabic, ')
          ..write('latin: $latin, ')
          ..write('body: $body, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameTrMeta = const VerificationMeta('nameTr');
  @override
  late final GeneratedColumn<String> nameTr = GeneratedColumn<String>(
    'name_tr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArabicMeta = const VerificationMeta(
    'nameArabic',
  );
  @override
  late final GeneratedColumn<String> nameArabic = GeneratedColumn<String>(
    'name_arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationMeta = const VerificationMeta(
    'revelation',
  );
  @override
  late final GeneratedColumn<String> revelation = GeneratedColumn<String>(
    'revelation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juzStartMeta = const VerificationMeta(
    'juzStart',
  );
  @override
  late final GeneratedColumn<int> juzStart = GeneratedColumn<int>(
    'juz_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    number,
    nameTr,
    nameArabic,
    meaning,
    ayahCount,
    revelation,
    juzStart,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('name_tr')) {
      context.handle(
        _nameTrMeta,
        nameTr.isAcceptableOrUnknown(data['name_tr']!, _nameTrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameTrMeta);
    }
    if (data.containsKey('name_arabic')) {
      context.handle(
        _nameArabicMeta,
        nameArabic.isAcceptableOrUnknown(data['name_arabic']!, _nameArabicMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArabicMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('revelation')) {
      context.handle(
        _revelationMeta,
        revelation.isAcceptableOrUnknown(data['revelation']!, _revelationMeta),
      );
    } else if (isInserting) {
      context.missing(_revelationMeta);
    }
    if (data.containsKey('juz_start')) {
      context.handle(
        _juzStartMeta,
        juzStart.isAcceptableOrUnknown(data['juz_start']!, _juzStartMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      nameTr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_tr'],
      )!,
      nameArabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_arabic'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      revelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation'],
      )!,
      juzStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz_start'],
      )!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int number;
  final String nameTr;
  final String nameArabic;
  final String meaning;
  final int ayahCount;
  final String revelation;
  final int juzStart;
  const Surah({
    required this.number,
    required this.nameTr,
    required this.nameArabic,
    required this.meaning,
    required this.ayahCount,
    required this.revelation,
    required this.juzStart,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['name_tr'] = Variable<String>(nameTr);
    map['name_arabic'] = Variable<String>(nameArabic);
    map['meaning'] = Variable<String>(meaning);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['revelation'] = Variable<String>(revelation);
    map['juz_start'] = Variable<int>(juzStart);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      number: Value(number),
      nameTr: Value(nameTr),
      nameArabic: Value(nameArabic),
      meaning: Value(meaning),
      ayahCount: Value(ayahCount),
      revelation: Value(revelation),
      juzStart: Value(juzStart),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      number: serializer.fromJson<int>(json['number']),
      nameTr: serializer.fromJson<String>(json['nameTr']),
      nameArabic: serializer.fromJson<String>(json['nameArabic']),
      meaning: serializer.fromJson<String>(json['meaning']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      revelation: serializer.fromJson<String>(json['revelation']),
      juzStart: serializer.fromJson<int>(json['juzStart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'nameTr': serializer.toJson<String>(nameTr),
      'nameArabic': serializer.toJson<String>(nameArabic),
      'meaning': serializer.toJson<String>(meaning),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'revelation': serializer.toJson<String>(revelation),
      'juzStart': serializer.toJson<int>(juzStart),
    };
  }

  Surah copyWith({
    int? number,
    String? nameTr,
    String? nameArabic,
    String? meaning,
    int? ayahCount,
    String? revelation,
    int? juzStart,
  }) => Surah(
    number: number ?? this.number,
    nameTr: nameTr ?? this.nameTr,
    nameArabic: nameArabic ?? this.nameArabic,
    meaning: meaning ?? this.meaning,
    ayahCount: ayahCount ?? this.ayahCount,
    revelation: revelation ?? this.revelation,
    juzStart: juzStart ?? this.juzStart,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      number: data.number.present ? data.number.value : this.number,
      nameTr: data.nameTr.present ? data.nameTr.value : this.nameTr,
      nameArabic: data.nameArabic.present
          ? data.nameArabic.value
          : this.nameArabic,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      revelation: data.revelation.present
          ? data.revelation.value
          : this.revelation,
      juzStart: data.juzStart.present ? data.juzStart.value : this.juzStart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('number: $number, ')
          ..write('nameTr: $nameTr, ')
          ..write('nameArabic: $nameArabic, ')
          ..write('meaning: $meaning, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelation: $revelation, ')
          ..write('juzStart: $juzStart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    number,
    nameTr,
    nameArabic,
    meaning,
    ayahCount,
    revelation,
    juzStart,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.number == this.number &&
          other.nameTr == this.nameTr &&
          other.nameArabic == this.nameArabic &&
          other.meaning == this.meaning &&
          other.ayahCount == this.ayahCount &&
          other.revelation == this.revelation &&
          other.juzStart == this.juzStart);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> number;
  final Value<String> nameTr;
  final Value<String> nameArabic;
  final Value<String> meaning;
  final Value<int> ayahCount;
  final Value<String> revelation;
  final Value<int> juzStart;
  const SurahsCompanion({
    this.number = const Value.absent(),
    this.nameTr = const Value.absent(),
    this.nameArabic = const Value.absent(),
    this.meaning = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.revelation = const Value.absent(),
    this.juzStart = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.number = const Value.absent(),
    required String nameTr,
    required String nameArabic,
    required String meaning,
    required int ayahCount,
    required String revelation,
    this.juzStart = const Value.absent(),
  }) : nameTr = Value(nameTr),
       nameArabic = Value(nameArabic),
       meaning = Value(meaning),
       ayahCount = Value(ayahCount),
       revelation = Value(revelation);
  static Insertable<Surah> custom({
    Expression<int>? number,
    Expression<String>? nameTr,
    Expression<String>? nameArabic,
    Expression<String>? meaning,
    Expression<int>? ayahCount,
    Expression<String>? revelation,
    Expression<int>? juzStart,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (nameTr != null) 'name_tr': nameTr,
      if (nameArabic != null) 'name_arabic': nameArabic,
      if (meaning != null) 'meaning': meaning,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (revelation != null) 'revelation': revelation,
      if (juzStart != null) 'juz_start': juzStart,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? number,
    Value<String>? nameTr,
    Value<String>? nameArabic,
    Value<String>? meaning,
    Value<int>? ayahCount,
    Value<String>? revelation,
    Value<int>? juzStart,
  }) {
    return SurahsCompanion(
      number: number ?? this.number,
      nameTr: nameTr ?? this.nameTr,
      nameArabic: nameArabic ?? this.nameArabic,
      meaning: meaning ?? this.meaning,
      ayahCount: ayahCount ?? this.ayahCount,
      revelation: revelation ?? this.revelation,
      juzStart: juzStart ?? this.juzStart,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (nameTr.present) {
      map['name_tr'] = Variable<String>(nameTr.value);
    }
    if (nameArabic.present) {
      map['name_arabic'] = Variable<String>(nameArabic.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (revelation.present) {
      map['revelation'] = Variable<String>(revelation.value);
    }
    if (juzStart.present) {
      map['juz_start'] = Variable<int>(juzStart.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('number: $number, ')
          ..write('nameTr: $nameTr, ')
          ..write('nameArabic: $nameArabic, ')
          ..write('meaning: $meaning, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelation: $revelation, ')
          ..write('juzStart: $juzStart')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _surahNumberMeta = const VerificationMeta(
    'surahNumber',
  );
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
    'surah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberInSurahMeta = const VerificationMeta(
    'numberInSurah',
  );
  @override
  late final GeneratedColumn<int> numberInSurah = GeneratedColumn<int>(
    'number_in_surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
    'meal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tafsirMeta = const VerificationMeta('tafsir');
  @override
  late final GeneratedColumn<String> tafsir = GeneratedColumn<String>(
    'tafsir',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surahNumber,
    numberInSurah,
    arabic,
    meal,
    tafsir,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_number')) {
      context.handle(
        _surahNumberMeta,
        surahNumber.isAcceptableOrUnknown(
          data['surah_number']!,
          _surahNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surahNumberMeta);
    }
    if (data.containsKey('number_in_surah')) {
      context.handle(
        _numberInSurahMeta,
        numberInSurah.isAcceptableOrUnknown(
          data['number_in_surah']!,
          _numberInSurahMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numberInSurahMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('tafsir')) {
      context.handle(
        _tafsirMeta,
        tafsir.isAcceptableOrUnknown(data['tafsir']!, _tafsirMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_number'],
      )!,
      numberInSurah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_in_surah'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
      tafsir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tafsir'],
      ),
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  final int id;
  final int surahNumber;
  final int numberInSurah;
  final String arabic;
  final String meal;
  final String? tafsir;
  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.numberInSurah,
    required this.arabic,
    required this.meal,
    this.tafsir,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_number'] = Variable<int>(surahNumber);
    map['number_in_surah'] = Variable<int>(numberInSurah);
    map['arabic'] = Variable<String>(arabic);
    map['meal'] = Variable<String>(meal);
    if (!nullToAbsent || tafsir != null) {
      map['tafsir'] = Variable<String>(tafsir);
    }
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surahNumber: Value(surahNumber),
      numberInSurah: Value(numberInSurah),
      arabic: Value(arabic),
      meal: Value(meal),
      tafsir: tafsir == null && nullToAbsent
          ? const Value.absent()
          : Value(tafsir),
    );
  }

  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      id: serializer.fromJson<int>(json['id']),
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      numberInSurah: serializer.fromJson<int>(json['numberInSurah']),
      arabic: serializer.fromJson<String>(json['arabic']),
      meal: serializer.fromJson<String>(json['meal']),
      tafsir: serializer.fromJson<String?>(json['tafsir']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahNumber': serializer.toJson<int>(surahNumber),
      'numberInSurah': serializer.toJson<int>(numberInSurah),
      'arabic': serializer.toJson<String>(arabic),
      'meal': serializer.toJson<String>(meal),
      'tafsir': serializer.toJson<String?>(tafsir),
    };
  }

  Ayah copyWith({
    int? id,
    int? surahNumber,
    int? numberInSurah,
    String? arabic,
    String? meal,
    Value<String?> tafsir = const Value.absent(),
  }) => Ayah(
    id: id ?? this.id,
    surahNumber: surahNumber ?? this.surahNumber,
    numberInSurah: numberInSurah ?? this.numberInSurah,
    arabic: arabic ?? this.arabic,
    meal: meal ?? this.meal,
    tafsir: tafsir.present ? tafsir.value : this.tafsir,
  );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      id: data.id.present ? data.id.value : this.id,
      surahNumber: data.surahNumber.present
          ? data.surahNumber.value
          : this.surahNumber,
      numberInSurah: data.numberInSurah.present
          ? data.numberInSurah.value
          : this.numberInSurah,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      meal: data.meal.present ? data.meal.value : this.meal,
      tafsir: data.tafsir.present ? data.tafsir.value : this.tafsir,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('id: $id, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('numberInSurah: $numberInSurah, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal, ')
          ..write('tafsir: $tafsir')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, surahNumber, numberInSurah, arabic, meal, tafsir);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.id == this.id &&
          other.surahNumber == this.surahNumber &&
          other.numberInSurah == this.numberInSurah &&
          other.arabic == this.arabic &&
          other.meal == this.meal &&
          other.tafsir == this.tafsir);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> id;
  final Value<int> surahNumber;
  final Value<int> numberInSurah;
  final Value<String> arabic;
  final Value<String> meal;
  final Value<String?> tafsir;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.numberInSurah = const Value.absent(),
    this.arabic = const Value.absent(),
    this.meal = const Value.absent(),
    this.tafsir = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surahNumber,
    required int numberInSurah,
    required String arabic,
    required String meal,
    this.tafsir = const Value.absent(),
  }) : surahNumber = Value(surahNumber),
       numberInSurah = Value(numberInSurah),
       arabic = Value(arabic),
       meal = Value(meal);
  static Insertable<Ayah> custom({
    Expression<int>? id,
    Expression<int>? surahNumber,
    Expression<int>? numberInSurah,
    Expression<String>? arabic,
    Expression<String>? meal,
    Expression<String>? tafsir,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (numberInSurah != null) 'number_in_surah': numberInSurah,
      if (arabic != null) 'arabic': arabic,
      if (meal != null) 'meal': meal,
      if (tafsir != null) 'tafsir': tafsir,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? id,
    Value<int>? surahNumber,
    Value<int>? numberInSurah,
    Value<String>? arabic,
    Value<String>? meal,
    Value<String?>? tafsir,
  }) {
    return AyahsCompanion(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      arabic: arabic ?? this.arabic,
      meal: meal ?? this.meal,
      tafsir: tafsir ?? this.tafsir,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (numberInSurah.present) {
      map['number_in_surah'] = Variable<int>(numberInSurah.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    if (tafsir.present) {
      map['tafsir'] = Variable<String>(tafsir.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('numberInSurah: $numberInSurah, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal, ')
          ..write('tafsir: $tafsir')
          ..write(')'))
        .toString();
  }
}

class $TopicalAyahsTable extends TopicalAyahs
    with TableInfo<$TopicalAyahsTable, TopicalAyah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicalAyahsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
    'meal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, topic, reference, arabic, meal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topical_ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicalAyah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopicalAyah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicalAyah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
    );
  }

  @override
  $TopicalAyahsTable createAlias(String alias) {
    return $TopicalAyahsTable(attachedDatabase, alias);
  }
}

class TopicalAyah extends DataClass implements Insertable<TopicalAyah> {
  final int id;
  final String topic;
  final String reference;
  final String arabic;
  final String meal;
  const TopicalAyah({
    required this.id,
    required this.topic,
    required this.reference,
    required this.arabic,
    required this.meal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic'] = Variable<String>(topic);
    map['reference'] = Variable<String>(reference);
    map['arabic'] = Variable<String>(arabic);
    map['meal'] = Variable<String>(meal);
    return map;
  }

  TopicalAyahsCompanion toCompanion(bool nullToAbsent) {
    return TopicalAyahsCompanion(
      id: Value(id),
      topic: Value(topic),
      reference: Value(reference),
      arabic: Value(arabic),
      meal: Value(meal),
    );
  }

  factory TopicalAyah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicalAyah(
      id: serializer.fromJson<int>(json['id']),
      topic: serializer.fromJson<String>(json['topic']),
      reference: serializer.fromJson<String>(json['reference']),
      arabic: serializer.fromJson<String>(json['arabic']),
      meal: serializer.fromJson<String>(json['meal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topic': serializer.toJson<String>(topic),
      'reference': serializer.toJson<String>(reference),
      'arabic': serializer.toJson<String>(arabic),
      'meal': serializer.toJson<String>(meal),
    };
  }

  TopicalAyah copyWith({
    int? id,
    String? topic,
    String? reference,
    String? arabic,
    String? meal,
  }) => TopicalAyah(
    id: id ?? this.id,
    topic: topic ?? this.topic,
    reference: reference ?? this.reference,
    arabic: arabic ?? this.arabic,
    meal: meal ?? this.meal,
  );
  TopicalAyah copyWithCompanion(TopicalAyahsCompanion data) {
    return TopicalAyah(
      id: data.id.present ? data.id.value : this.id,
      topic: data.topic.present ? data.topic.value : this.topic,
      reference: data.reference.present ? data.reference.value : this.reference,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      meal: data.meal.present ? data.meal.value : this.meal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicalAyah(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('reference: $reference, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, topic, reference, arabic, meal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicalAyah &&
          other.id == this.id &&
          other.topic == this.topic &&
          other.reference == this.reference &&
          other.arabic == this.arabic &&
          other.meal == this.meal);
}

class TopicalAyahsCompanion extends UpdateCompanion<TopicalAyah> {
  final Value<int> id;
  final Value<String> topic;
  final Value<String> reference;
  final Value<String> arabic;
  final Value<String> meal;
  const TopicalAyahsCompanion({
    this.id = const Value.absent(),
    this.topic = const Value.absent(),
    this.reference = const Value.absent(),
    this.arabic = const Value.absent(),
    this.meal = const Value.absent(),
  });
  TopicalAyahsCompanion.insert({
    this.id = const Value.absent(),
    required String topic,
    required String reference,
    required String arabic,
    required String meal,
  }) : topic = Value(topic),
       reference = Value(reference),
       arabic = Value(arabic),
       meal = Value(meal);
  static Insertable<TopicalAyah> custom({
    Expression<int>? id,
    Expression<String>? topic,
    Expression<String>? reference,
    Expression<String>? arabic,
    Expression<String>? meal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topic != null) 'topic': topic,
      if (reference != null) 'reference': reference,
      if (arabic != null) 'arabic': arabic,
      if (meal != null) 'meal': meal,
    });
  }

  TopicalAyahsCompanion copyWith({
    Value<int>? id,
    Value<String>? topic,
    Value<String>? reference,
    Value<String>? arabic,
    Value<String>? meal,
  }) {
    return TopicalAyahsCompanion(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      reference: reference ?? this.reference,
      arabic: arabic ?? this.arabic,
      meal: meal ?? this.meal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicalAyahsCompanion(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('reference: $reference, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, Story> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readMinutesMeta = const VerificationMeta(
    'readMinutes',
  );
  @override
  late final GeneratedColumn<int> readMinutes = GeneratedColumn<int>(
    'read_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    order,
    title,
    category,
    readMinutes,
    summary,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Story> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('read_minutes')) {
      context.handle(
        _readMinutesMeta,
        readMinutes.isAcceptableOrUnknown(
          data['read_minutes']!,
          _readMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readMinutesMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Story map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Story(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      readMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_minutes'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class Story extends DataClass implements Insertable<Story> {
  final int id;
  final int order;
  final String title;
  final String category;
  final int readMinutes;
  final String summary;
  final String body;
  const Story({
    required this.id,
    required this.order,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.summary,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order'] = Variable<int>(order);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['read_minutes'] = Variable<int>(readMinutes);
    map['summary'] = Variable<String>(summary);
    map['body'] = Variable<String>(body);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      order: Value(order),
      title: Value(title),
      category: Value(category),
      readMinutes: Value(readMinutes),
      summary: Value(summary),
      body: Value(body),
    );
  }

  factory Story.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Story(
      id: serializer.fromJson<int>(json['id']),
      order: serializer.fromJson<int>(json['order']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      readMinutes: serializer.fromJson<int>(json['readMinutes']),
      summary: serializer.fromJson<String>(json['summary']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'order': serializer.toJson<int>(order),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'readMinutes': serializer.toJson<int>(readMinutes),
      'summary': serializer.toJson<String>(summary),
      'body': serializer.toJson<String>(body),
    };
  }

  Story copyWith({
    int? id,
    int? order,
    String? title,
    String? category,
    int? readMinutes,
    String? summary,
    String? body,
  }) => Story(
    id: id ?? this.id,
    order: order ?? this.order,
    title: title ?? this.title,
    category: category ?? this.category,
    readMinutes: readMinutes ?? this.readMinutes,
    summary: summary ?? this.summary,
    body: body ?? this.body,
  );
  Story copyWithCompanion(StoriesCompanion data) {
    return Story(
      id: data.id.present ? data.id.value : this.id,
      order: data.order.present ? data.order.value : this.order,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      readMinutes: data.readMinutes.present
          ? data.readMinutes.value
          : this.readMinutes,
      summary: data.summary.present ? data.summary.value : this.summary,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Story(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('readMinutes: $readMinutes, ')
          ..write('summary: $summary, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, order, title, category, readMinutes, summary, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Story &&
          other.id == this.id &&
          other.order == this.order &&
          other.title == this.title &&
          other.category == this.category &&
          other.readMinutes == this.readMinutes &&
          other.summary == this.summary &&
          other.body == this.body);
}

class StoriesCompanion extends UpdateCompanion<Story> {
  final Value<int> id;
  final Value<int> order;
  final Value<String> title;
  final Value<String> category;
  final Value<int> readMinutes;
  final Value<String> summary;
  final Value<String> body;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.order = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.readMinutes = const Value.absent(),
    this.summary = const Value.absent(),
    this.body = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    required int order,
    required String title,
    required String category,
    required int readMinutes,
    required String summary,
    required String body,
  }) : order = Value(order),
       title = Value(title),
       category = Value(category),
       readMinutes = Value(readMinutes),
       summary = Value(summary),
       body = Value(body);
  static Insertable<Story> custom({
    Expression<int>? id,
    Expression<int>? order,
    Expression<String>? title,
    Expression<String>? category,
    Expression<int>? readMinutes,
    Expression<String>? summary,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (order != null) 'order': order,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (readMinutes != null) 'read_minutes': readMinutes,
      if (summary != null) 'summary': summary,
      if (body != null) 'body': body,
    });
  }

  StoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? order,
    Value<String>? title,
    Value<String>? category,
    Value<int>? readMinutes,
    Value<String>? summary,
    Value<String>? body,
  }) {
    return StoriesCompanion(
      id: id ?? this.id,
      order: order ?? this.order,
      title: title ?? this.title,
      category: category ?? this.category,
      readMinutes: readMinutes ?? this.readMinutes,
      summary: summary ?? this.summary,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (readMinutes.present) {
      map['read_minutes'] = Variable<int>(readMinutes.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('readMinutes: $readMinutes, ')
          ..write('summary: $summary, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $MiraclesTable extends Miracles with TableInfo<$MiraclesTable, Miracle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MiraclesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, category, title, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'miracles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Miracle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Miracle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Miracle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $MiraclesTable createAlias(String alias) {
    return $MiraclesTable(attachedDatabase, alias);
  }
}

class Miracle extends DataClass implements Insertable<Miracle> {
  final int id;
  final String category;
  final String title;
  final String body;
  const Miracle({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  MiraclesCompanion toCompanion(bool nullToAbsent) {
    return MiraclesCompanion(
      id: Value(id),
      category: Value(category),
      title: Value(title),
      body: Value(body),
    );
  }

  factory Miracle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Miracle(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  Miracle copyWith({int? id, String? category, String? title, String? body}) =>
      Miracle(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        body: body ?? this.body,
      );
  Miracle copyWithCompanion(MiraclesCompanion data) {
    return Miracle(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Miracle(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, title, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Miracle &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.body == this.body);
}

class MiraclesCompanion extends UpdateCompanion<Miracle> {
  final Value<int> id;
  final Value<String> category;
  final Value<String> title;
  final Value<String> body;
  const MiraclesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
  });
  MiraclesCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required String title,
    required String body,
  }) : category = Value(category),
       title = Value(title),
       body = Value(body);
  static Insertable<Miracle> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
    });
  }

  MiraclesCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<String>? title,
    Value<String>? body,
  }) {
    return MiraclesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MiraclesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $TajweedLessonsTable extends TajweedLessons
    with TableInfo<$TajweedLessonsTable, TajweedLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TajweedLessonsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<String> rule = GeneratedColumn<String>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, order, title, rule, example, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tajweed_lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<TajweedLesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(
        _ruleMeta,
        rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    } else if (isInserting) {
      context.missing(_exampleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TajweedLesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TajweedLesson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      rule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $TajweedLessonsTable createAlias(String alias) {
    return $TajweedLessonsTable(attachedDatabase, alias);
  }
}

class TajweedLesson extends DataClass implements Insertable<TajweedLesson> {
  final int id;
  final int order;
  final String title;
  final String rule;
  final String example;
  final String body;
  const TajweedLesson({
    required this.id,
    required this.order,
    required this.title,
    required this.rule,
    required this.example,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order'] = Variable<int>(order);
    map['title'] = Variable<String>(title);
    map['rule'] = Variable<String>(rule);
    map['example'] = Variable<String>(example);
    map['body'] = Variable<String>(body);
    return map;
  }

  TajweedLessonsCompanion toCompanion(bool nullToAbsent) {
    return TajweedLessonsCompanion(
      id: Value(id),
      order: Value(order),
      title: Value(title),
      rule: Value(rule),
      example: Value(example),
      body: Value(body),
    );
  }

  factory TajweedLesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TajweedLesson(
      id: serializer.fromJson<int>(json['id']),
      order: serializer.fromJson<int>(json['order']),
      title: serializer.fromJson<String>(json['title']),
      rule: serializer.fromJson<String>(json['rule']),
      example: serializer.fromJson<String>(json['example']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'order': serializer.toJson<int>(order),
      'title': serializer.toJson<String>(title),
      'rule': serializer.toJson<String>(rule),
      'example': serializer.toJson<String>(example),
      'body': serializer.toJson<String>(body),
    };
  }

  TajweedLesson copyWith({
    int? id,
    int? order,
    String? title,
    String? rule,
    String? example,
    String? body,
  }) => TajweedLesson(
    id: id ?? this.id,
    order: order ?? this.order,
    title: title ?? this.title,
    rule: rule ?? this.rule,
    example: example ?? this.example,
    body: body ?? this.body,
  );
  TajweedLesson copyWithCompanion(TajweedLessonsCompanion data) {
    return TajweedLesson(
      id: data.id.present ? data.id.value : this.id,
      order: data.order.present ? data.order.value : this.order,
      title: data.title.present ? data.title.value : this.title,
      rule: data.rule.present ? data.rule.value : this.rule,
      example: data.example.present ? data.example.value : this.example,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TajweedLesson(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('title: $title, ')
          ..write('rule: $rule, ')
          ..write('example: $example, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, order, title, rule, example, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TajweedLesson &&
          other.id == this.id &&
          other.order == this.order &&
          other.title == this.title &&
          other.rule == this.rule &&
          other.example == this.example &&
          other.body == this.body);
}

class TajweedLessonsCompanion extends UpdateCompanion<TajweedLesson> {
  final Value<int> id;
  final Value<int> order;
  final Value<String> title;
  final Value<String> rule;
  final Value<String> example;
  final Value<String> body;
  const TajweedLessonsCompanion({
    this.id = const Value.absent(),
    this.order = const Value.absent(),
    this.title = const Value.absent(),
    this.rule = const Value.absent(),
    this.example = const Value.absent(),
    this.body = const Value.absent(),
  });
  TajweedLessonsCompanion.insert({
    this.id = const Value.absent(),
    required int order,
    required String title,
    required String rule,
    required String example,
    required String body,
  }) : order = Value(order),
       title = Value(title),
       rule = Value(rule),
       example = Value(example),
       body = Value(body);
  static Insertable<TajweedLesson> custom({
    Expression<int>? id,
    Expression<int>? order,
    Expression<String>? title,
    Expression<String>? rule,
    Expression<String>? example,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (order != null) 'order': order,
      if (title != null) 'title': title,
      if (rule != null) 'rule': rule,
      if (example != null) 'example': example,
      if (body != null) 'body': body,
    });
  }

  TajweedLessonsCompanion copyWith({
    Value<int>? id,
    Value<int>? order,
    Value<String>? title,
    Value<String>? rule,
    Value<String>? example,
    Value<String>? body,
  }) {
    return TajweedLessonsCompanion(
      id: id ?? this.id,
      order: order ?? this.order,
      title: title ?? this.title,
      rule: rule ?? this.rule,
      example: example ?? this.example,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rule.present) {
      map['rule'] = Variable<String>(rule.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TajweedLessonsCompanion(')
          ..write('id: $id, ')
          ..write('order: $order, ')
          ..write('title: $title, ')
          ..write('rule: $rule, ')
          ..write('example: $example, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $DreamSymbolsTable extends DreamSymbols
    with TableInfo<$DreamSymbolsTable, DreamSymbol> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamSymbolsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, term, category, meaning, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dream_symbols';
  @override
  VerificationContext validateIntegrity(
    Insertable<DreamSymbol> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DreamSymbol map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DreamSymbol(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DreamSymbolsTable createAlias(String alias) {
    return $DreamSymbolsTable(attachedDatabase, alias);
  }
}

class DreamSymbol extends DataClass implements Insertable<DreamSymbol> {
  final int id;
  final String term;
  final String category;
  final String meaning;
  final String source;
  const DreamSymbol({
    required this.id,
    required this.term,
    required this.category,
    required this.meaning,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['term'] = Variable<String>(term);
    map['category'] = Variable<String>(category);
    map['meaning'] = Variable<String>(meaning);
    map['source'] = Variable<String>(source);
    return map;
  }

  DreamSymbolsCompanion toCompanion(bool nullToAbsent) {
    return DreamSymbolsCompanion(
      id: Value(id),
      term: Value(term),
      category: Value(category),
      meaning: Value(meaning),
      source: Value(source),
    );
  }

  factory DreamSymbol.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DreamSymbol(
      id: serializer.fromJson<int>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      category: serializer.fromJson<String>(json['category']),
      meaning: serializer.fromJson<String>(json['meaning']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'term': serializer.toJson<String>(term),
      'category': serializer.toJson<String>(category),
      'meaning': serializer.toJson<String>(meaning),
      'source': serializer.toJson<String>(source),
    };
  }

  DreamSymbol copyWith({
    int? id,
    String? term,
    String? category,
    String? meaning,
    String? source,
  }) => DreamSymbol(
    id: id ?? this.id,
    term: term ?? this.term,
    category: category ?? this.category,
    meaning: meaning ?? this.meaning,
    source: source ?? this.source,
  );
  DreamSymbol copyWithCompanion(DreamSymbolsCompanion data) {
    return DreamSymbol(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      category: data.category.present ? data.category.value : this.category,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DreamSymbol(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('category: $category, ')
          ..write('meaning: $meaning, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, term, category, meaning, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DreamSymbol &&
          other.id == this.id &&
          other.term == this.term &&
          other.category == this.category &&
          other.meaning == this.meaning &&
          other.source == this.source);
}

class DreamSymbolsCompanion extends UpdateCompanion<DreamSymbol> {
  final Value<int> id;
  final Value<String> term;
  final Value<String> category;
  final Value<String> meaning;
  final Value<String> source;
  const DreamSymbolsCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.category = const Value.absent(),
    this.meaning = const Value.absent(),
    this.source = const Value.absent(),
  });
  DreamSymbolsCompanion.insert({
    this.id = const Value.absent(),
    required String term,
    required String category,
    required String meaning,
    this.source = const Value.absent(),
  }) : term = Value(term),
       category = Value(category),
       meaning = Value(meaning);
  static Insertable<DreamSymbol> custom({
    Expression<int>? id,
    Expression<String>? term,
    Expression<String>? category,
    Expression<String>? meaning,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (category != null) 'category': category,
      if (meaning != null) 'meaning': meaning,
      if (source != null) 'source': source,
    });
  }

  DreamSymbolsCompanion copyWith({
    Value<int>? id,
    Value<String>? term,
    Value<String>? category,
    Value<String>? meaning,
    Value<String>? source,
  }) {
    return DreamSymbolsCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      category: category ?? this.category,
      meaning: meaning ?? this.meaning,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamSymbolsCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('category: $category, ')
          ..write('meaning: $meaning, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $DhikrCountersTable extends DhikrCounters
    with TableInfo<$DhikrCountersTable, DhikrCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DhikrCountersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateIsoMeta = const VerificationMeta(
    'dateIso',
  );
  @override
  late final GeneratedColumn<String> dateIso = GeneratedColumn<String>(
    'date_iso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dhikrKeyMeta = const VerificationMeta(
    'dhikrKey',
  );
  @override
  late final GeneratedColumn<String> dhikrKey = GeneratedColumn<String>(
    'dhikr_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, dateIso, dhikrKey, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dhikr_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<DhikrCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date_iso')) {
      context.handle(
        _dateIsoMeta,
        dateIso.isAcceptableOrUnknown(data['date_iso']!, _dateIsoMeta),
      );
    } else if (isInserting) {
      context.missing(_dateIsoMeta);
    }
    if (data.containsKey('dhikr_key')) {
      context.handle(
        _dhikrKeyMeta,
        dhikrKey.isAcceptableOrUnknown(data['dhikr_key']!, _dhikrKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dhikrKeyMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DhikrCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DhikrCounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dateIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_iso'],
      )!,
      dhikrKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dhikr_key'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $DhikrCountersTable createAlias(String alias) {
    return $DhikrCountersTable(attachedDatabase, alias);
  }
}

class DhikrCounter extends DataClass implements Insertable<DhikrCounter> {
  final int id;
  final String dateIso;
  final String dhikrKey;
  final int count;
  const DhikrCounter({
    required this.id,
    required this.dateIso,
    required this.dhikrKey,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date_iso'] = Variable<String>(dateIso);
    map['dhikr_key'] = Variable<String>(dhikrKey);
    map['count'] = Variable<int>(count);
    return map;
  }

  DhikrCountersCompanion toCompanion(bool nullToAbsent) {
    return DhikrCountersCompanion(
      id: Value(id),
      dateIso: Value(dateIso),
      dhikrKey: Value(dhikrKey),
      count: Value(count),
    );
  }

  factory DhikrCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DhikrCounter(
      id: serializer.fromJson<int>(json['id']),
      dateIso: serializer.fromJson<String>(json['dateIso']),
      dhikrKey: serializer.fromJson<String>(json['dhikrKey']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dateIso': serializer.toJson<String>(dateIso),
      'dhikrKey': serializer.toJson<String>(dhikrKey),
      'count': serializer.toJson<int>(count),
    };
  }

  DhikrCounter copyWith({
    int? id,
    String? dateIso,
    String? dhikrKey,
    int? count,
  }) => DhikrCounter(
    id: id ?? this.id,
    dateIso: dateIso ?? this.dateIso,
    dhikrKey: dhikrKey ?? this.dhikrKey,
    count: count ?? this.count,
  );
  DhikrCounter copyWithCompanion(DhikrCountersCompanion data) {
    return DhikrCounter(
      id: data.id.present ? data.id.value : this.id,
      dateIso: data.dateIso.present ? data.dateIso.value : this.dateIso,
      dhikrKey: data.dhikrKey.present ? data.dhikrKey.value : this.dhikrKey,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DhikrCounter(')
          ..write('id: $id, ')
          ..write('dateIso: $dateIso, ')
          ..write('dhikrKey: $dhikrKey, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateIso, dhikrKey, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DhikrCounter &&
          other.id == this.id &&
          other.dateIso == this.dateIso &&
          other.dhikrKey == this.dhikrKey &&
          other.count == this.count);
}

class DhikrCountersCompanion extends UpdateCompanion<DhikrCounter> {
  final Value<int> id;
  final Value<String> dateIso;
  final Value<String> dhikrKey;
  final Value<int> count;
  const DhikrCountersCompanion({
    this.id = const Value.absent(),
    this.dateIso = const Value.absent(),
    this.dhikrKey = const Value.absent(),
    this.count = const Value.absent(),
  });
  DhikrCountersCompanion.insert({
    this.id = const Value.absent(),
    required String dateIso,
    required String dhikrKey,
    this.count = const Value.absent(),
  }) : dateIso = Value(dateIso),
       dhikrKey = Value(dhikrKey);
  static Insertable<DhikrCounter> custom({
    Expression<int>? id,
    Expression<String>? dateIso,
    Expression<String>? dhikrKey,
    Expression<int>? count,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateIso != null) 'date_iso': dateIso,
      if (dhikrKey != null) 'dhikr_key': dhikrKey,
      if (count != null) 'count': count,
    });
  }

  DhikrCountersCompanion copyWith({
    Value<int>? id,
    Value<String>? dateIso,
    Value<String>? dhikrKey,
    Value<int>? count,
  }) {
    return DhikrCountersCompanion(
      id: id ?? this.id,
      dateIso: dateIso ?? this.dateIso,
      dhikrKey: dhikrKey ?? this.dhikrKey,
      count: count ?? this.count,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dateIso.present) {
      map['date_iso'] = Variable<String>(dateIso.value);
    }
    if (dhikrKey.present) {
      map['dhikr_key'] = Variable<String>(dhikrKey.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DhikrCountersCompanion(')
          ..write('id: $id, ')
          ..write('dateIso: $dateIso, ')
          ..write('dhikrKey: $dhikrKey, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
    'meal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdIsoMeta = const VerificationMeta(
    'createdIso',
  );
  @override
  late final GeneratedColumn<String> createdIso = GeneratedColumn<String>(
    'created_iso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reference,
    arabic,
    meal,
    note,
    createdIso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_iso')) {
      context.handle(
        _createdIsoMeta,
        createdIso.isAcceptableOrUnknown(data['created_iso']!, _createdIsoMeta),
      );
    } else if (isInserting) {
      context.missing(_createdIsoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_iso'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final int id;
  final String reference;
  final String arabic;
  final String meal;
  final String? note;
  final String createdIso;
  const Collection({
    required this.id,
    required this.reference,
    required this.arabic,
    required this.meal,
    this.note,
    required this.createdIso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reference'] = Variable<String>(reference);
    map['arabic'] = Variable<String>(arabic);
    map['meal'] = Variable<String>(meal);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_iso'] = Variable<String>(createdIso);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      reference: Value(reference),
      arabic: Value(arabic),
      meal: Value(meal),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdIso: Value(createdIso),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<int>(json['id']),
      reference: serializer.fromJson<String>(json['reference']),
      arabic: serializer.fromJson<String>(json['arabic']),
      meal: serializer.fromJson<String>(json['meal']),
      note: serializer.fromJson<String?>(json['note']),
      createdIso: serializer.fromJson<String>(json['createdIso']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reference': serializer.toJson<String>(reference),
      'arabic': serializer.toJson<String>(arabic),
      'meal': serializer.toJson<String>(meal),
      'note': serializer.toJson<String?>(note),
      'createdIso': serializer.toJson<String>(createdIso),
    };
  }

  Collection copyWith({
    int? id,
    String? reference,
    String? arabic,
    String? meal,
    Value<String?> note = const Value.absent(),
    String? createdIso,
  }) => Collection(
    id: id ?? this.id,
    reference: reference ?? this.reference,
    arabic: arabic ?? this.arabic,
    meal: meal ?? this.meal,
    note: note.present ? note.value : this.note,
    createdIso: createdIso ?? this.createdIso,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      reference: data.reference.present ? data.reference.value : this.reference,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      meal: data.meal.present ? data.meal.value : this.meal,
      note: data.note.present ? data.note.value : this.note,
      createdIso: data.createdIso.present
          ? data.createdIso.value
          : this.createdIso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('reference: $reference, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal, ')
          ..write('note: $note, ')
          ..write('createdIso: $createdIso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reference, arabic, meal, note, createdIso);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.reference == this.reference &&
          other.arabic == this.arabic &&
          other.meal == this.meal &&
          other.note == this.note &&
          other.createdIso == this.createdIso);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<int> id;
  final Value<String> reference;
  final Value<String> arabic;
  final Value<String> meal;
  final Value<String?> note;
  final Value<String> createdIso;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.reference = const Value.absent(),
    this.arabic = const Value.absent(),
    this.meal = const Value.absent(),
    this.note = const Value.absent(),
    this.createdIso = const Value.absent(),
  });
  CollectionsCompanion.insert({
    this.id = const Value.absent(),
    required String reference,
    required String arabic,
    required String meal,
    this.note = const Value.absent(),
    required String createdIso,
  }) : reference = Value(reference),
       arabic = Value(arabic),
       meal = Value(meal),
       createdIso = Value(createdIso);
  static Insertable<Collection> custom({
    Expression<int>? id,
    Expression<String>? reference,
    Expression<String>? arabic,
    Expression<String>? meal,
    Expression<String>? note,
    Expression<String>? createdIso,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reference != null) 'reference': reference,
      if (arabic != null) 'arabic': arabic,
      if (meal != null) 'meal': meal,
      if (note != null) 'note': note,
      if (createdIso != null) 'created_iso': createdIso,
    });
  }

  CollectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? reference,
    Value<String>? arabic,
    Value<String>? meal,
    Value<String?>? note,
    Value<String>? createdIso,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      arabic: arabic ?? this.arabic,
      meal: meal ?? this.meal,
      note: note ?? this.note,
      createdIso: createdIso ?? this.createdIso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdIso.present) {
      map['created_iso'] = Variable<String>(createdIso.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('reference: $reference, ')
          ..write('arabic: $arabic, ')
          ..write('meal: $meal, ')
          ..write('note: $note, ')
          ..write('createdIso: $createdIso')
          ..write(')'))
        .toString();
  }
}

class $MemorizationsTable extends Memorizations
    with TableInfo<$MemorizationsTable, Memorization> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _surahNumberMeta = const VerificationMeta(
    'surahNumber',
  );
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
    'surah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahNameMeta = const VerificationMeta(
    'surahName',
  );
  @override
  late final GeneratedColumn<String> surahName = GeneratedColumn<String>(
    'surah_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAyahsMeta = const VerificationMeta(
    'totalAyahs',
  );
  @override
  late final GeneratedColumn<int> totalAyahs = GeneratedColumn<int>(
    'total_ayahs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memorizedAyahsMeta = const VerificationMeta(
    'memorizedAyahs',
  );
  @override
  late final GeneratedColumn<int> memorizedAyahs = GeneratedColumn<int>(
    'memorized_ayahs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewIsoMeta = const VerificationMeta(
    'lastReviewIso',
  );
  @override
  late final GeneratedColumn<String> lastReviewIso = GeneratedColumn<String>(
    'last_review_iso',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surahNumber,
    surahName,
    totalAyahs,
    memorizedAyahs,
    lastReviewIso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorizations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Memorization> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_number')) {
      context.handle(
        _surahNumberMeta,
        surahNumber.isAcceptableOrUnknown(
          data['surah_number']!,
          _surahNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surahNumberMeta);
    }
    if (data.containsKey('surah_name')) {
      context.handle(
        _surahNameMeta,
        surahName.isAcceptableOrUnknown(data['surah_name']!, _surahNameMeta),
      );
    } else if (isInserting) {
      context.missing(_surahNameMeta);
    }
    if (data.containsKey('total_ayahs')) {
      context.handle(
        _totalAyahsMeta,
        totalAyahs.isAcceptableOrUnknown(data['total_ayahs']!, _totalAyahsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalAyahsMeta);
    }
    if (data.containsKey('memorized_ayahs')) {
      context.handle(
        _memorizedAyahsMeta,
        memorizedAyahs.isAcceptableOrUnknown(
          data['memorized_ayahs']!,
          _memorizedAyahsMeta,
        ),
      );
    }
    if (data.containsKey('last_review_iso')) {
      context.handle(
        _lastReviewIsoMeta,
        lastReviewIso.isAcceptableOrUnknown(
          data['last_review_iso']!,
          _lastReviewIsoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Memorization map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memorization(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_number'],
      )!,
      surahName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surah_name'],
      )!,
      totalAyahs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_ayahs'],
      )!,
      memorizedAyahs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}memorized_ayahs'],
      )!,
      lastReviewIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_review_iso'],
      ),
    );
  }

  @override
  $MemorizationsTable createAlias(String alias) {
    return $MemorizationsTable(attachedDatabase, alias);
  }
}

class Memorization extends DataClass implements Insertable<Memorization> {
  final int id;
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final int memorizedAyahs;
  final String? lastReviewIso;
  const Memorization({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.memorizedAyahs,
    this.lastReviewIso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_number'] = Variable<int>(surahNumber);
    map['surah_name'] = Variable<String>(surahName);
    map['total_ayahs'] = Variable<int>(totalAyahs);
    map['memorized_ayahs'] = Variable<int>(memorizedAyahs);
    if (!nullToAbsent || lastReviewIso != null) {
      map['last_review_iso'] = Variable<String>(lastReviewIso);
    }
    return map;
  }

  MemorizationsCompanion toCompanion(bool nullToAbsent) {
    return MemorizationsCompanion(
      id: Value(id),
      surahNumber: Value(surahNumber),
      surahName: Value(surahName),
      totalAyahs: Value(totalAyahs),
      memorizedAyahs: Value(memorizedAyahs),
      lastReviewIso: lastReviewIso == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewIso),
    );
  }

  factory Memorization.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memorization(
      id: serializer.fromJson<int>(json['id']),
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      surahName: serializer.fromJson<String>(json['surahName']),
      totalAyahs: serializer.fromJson<int>(json['totalAyahs']),
      memorizedAyahs: serializer.fromJson<int>(json['memorizedAyahs']),
      lastReviewIso: serializer.fromJson<String?>(json['lastReviewIso']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahNumber': serializer.toJson<int>(surahNumber),
      'surahName': serializer.toJson<String>(surahName),
      'totalAyahs': serializer.toJson<int>(totalAyahs),
      'memorizedAyahs': serializer.toJson<int>(memorizedAyahs),
      'lastReviewIso': serializer.toJson<String?>(lastReviewIso),
    };
  }

  Memorization copyWith({
    int? id,
    int? surahNumber,
    String? surahName,
    int? totalAyahs,
    int? memorizedAyahs,
    Value<String?> lastReviewIso = const Value.absent(),
  }) => Memorization(
    id: id ?? this.id,
    surahNumber: surahNumber ?? this.surahNumber,
    surahName: surahName ?? this.surahName,
    totalAyahs: totalAyahs ?? this.totalAyahs,
    memorizedAyahs: memorizedAyahs ?? this.memorizedAyahs,
    lastReviewIso: lastReviewIso.present
        ? lastReviewIso.value
        : this.lastReviewIso,
  );
  Memorization copyWithCompanion(MemorizationsCompanion data) {
    return Memorization(
      id: data.id.present ? data.id.value : this.id,
      surahNumber: data.surahNumber.present
          ? data.surahNumber.value
          : this.surahNumber,
      surahName: data.surahName.present ? data.surahName.value : this.surahName,
      totalAyahs: data.totalAyahs.present
          ? data.totalAyahs.value
          : this.totalAyahs,
      memorizedAyahs: data.memorizedAyahs.present
          ? data.memorizedAyahs.value
          : this.memorizedAyahs,
      lastReviewIso: data.lastReviewIso.present
          ? data.lastReviewIso.value
          : this.lastReviewIso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memorization(')
          ..write('id: $id, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('surahName: $surahName, ')
          ..write('totalAyahs: $totalAyahs, ')
          ..write('memorizedAyahs: $memorizedAyahs, ')
          ..write('lastReviewIso: $lastReviewIso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surahNumber,
    surahName,
    totalAyahs,
    memorizedAyahs,
    lastReviewIso,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memorization &&
          other.id == this.id &&
          other.surahNumber == this.surahNumber &&
          other.surahName == this.surahName &&
          other.totalAyahs == this.totalAyahs &&
          other.memorizedAyahs == this.memorizedAyahs &&
          other.lastReviewIso == this.lastReviewIso);
}

class MemorizationsCompanion extends UpdateCompanion<Memorization> {
  final Value<int> id;
  final Value<int> surahNumber;
  final Value<String> surahName;
  final Value<int> totalAyahs;
  final Value<int> memorizedAyahs;
  final Value<String?> lastReviewIso;
  const MemorizationsCompanion({
    this.id = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.surahName = const Value.absent(),
    this.totalAyahs = const Value.absent(),
    this.memorizedAyahs = const Value.absent(),
    this.lastReviewIso = const Value.absent(),
  });
  MemorizationsCompanion.insert({
    this.id = const Value.absent(),
    required int surahNumber,
    required String surahName,
    required int totalAyahs,
    this.memorizedAyahs = const Value.absent(),
    this.lastReviewIso = const Value.absent(),
  }) : surahNumber = Value(surahNumber),
       surahName = Value(surahName),
       totalAyahs = Value(totalAyahs);
  static Insertable<Memorization> custom({
    Expression<int>? id,
    Expression<int>? surahNumber,
    Expression<String>? surahName,
    Expression<int>? totalAyahs,
    Expression<int>? memorizedAyahs,
    Expression<String>? lastReviewIso,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (surahName != null) 'surah_name': surahName,
      if (totalAyahs != null) 'total_ayahs': totalAyahs,
      if (memorizedAyahs != null) 'memorized_ayahs': memorizedAyahs,
      if (lastReviewIso != null) 'last_review_iso': lastReviewIso,
    });
  }

  MemorizationsCompanion copyWith({
    Value<int>? id,
    Value<int>? surahNumber,
    Value<String>? surahName,
    Value<int>? totalAyahs,
    Value<int>? memorizedAyahs,
    Value<String?>? lastReviewIso,
  }) {
    return MemorizationsCompanion(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      memorizedAyahs: memorizedAyahs ?? this.memorizedAyahs,
      lastReviewIso: lastReviewIso ?? this.lastReviewIso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (surahName.present) {
      map['surah_name'] = Variable<String>(surahName.value);
    }
    if (totalAyahs.present) {
      map['total_ayahs'] = Variable<int>(totalAyahs.value);
    }
    if (memorizedAyahs.present) {
      map['memorized_ayahs'] = Variable<int>(memorizedAyahs.value);
    }
    if (lastReviewIso.present) {
      map['last_review_iso'] = Variable<String>(lastReviewIso.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationsCompanion(')
          ..write('id: $id, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('surahName: $surahName, ')
          ..write('totalAyahs: $totalAyahs, ')
          ..write('memorizedAyahs: $memorizedAyahs, ')
          ..write('lastReviewIso: $lastReviewIso')
          ..write(')'))
        .toString();
  }
}

class $JuzProgressTable extends JuzProgress
    with TableInfo<$JuzProgressTable, JuzProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JuzProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _juzNumberMeta = const VerificationMeta(
    'juzNumber',
  );
  @override
  late final GeneratedColumn<int> juzNumber = GeneratedColumn<int>(
    'juz_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedIsoMeta = const VerificationMeta(
    'updatedIso',
  );
  @override
  late final GeneratedColumn<String> updatedIso = GeneratedColumn<String>(
    'updated_iso',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [juzNumber, completed, updatedIso];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'juz_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<JuzProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('juz_number')) {
      context.handle(
        _juzNumberMeta,
        juzNumber.isAcceptableOrUnknown(data['juz_number']!, _juzNumberMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('updated_iso')) {
      context.handle(
        _updatedIsoMeta,
        updatedIso.isAcceptableOrUnknown(data['updated_iso']!, _updatedIsoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {juzNumber};
  @override
  JuzProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JuzProgressData(
      juzNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz_number'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      updatedIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_iso'],
      ),
    );
  }

  @override
  $JuzProgressTable createAlias(String alias) {
    return $JuzProgressTable(attachedDatabase, alias);
  }
}

class JuzProgressData extends DataClass implements Insertable<JuzProgressData> {
  final int juzNumber;
  final bool completed;
  final String? updatedIso;
  const JuzProgressData({
    required this.juzNumber,
    required this.completed,
    this.updatedIso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['juz_number'] = Variable<int>(juzNumber);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || updatedIso != null) {
      map['updated_iso'] = Variable<String>(updatedIso);
    }
    return map;
  }

  JuzProgressCompanion toCompanion(bool nullToAbsent) {
    return JuzProgressCompanion(
      juzNumber: Value(juzNumber),
      completed: Value(completed),
      updatedIso: updatedIso == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedIso),
    );
  }

  factory JuzProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JuzProgressData(
      juzNumber: serializer.fromJson<int>(json['juzNumber']),
      completed: serializer.fromJson<bool>(json['completed']),
      updatedIso: serializer.fromJson<String?>(json['updatedIso']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'juzNumber': serializer.toJson<int>(juzNumber),
      'completed': serializer.toJson<bool>(completed),
      'updatedIso': serializer.toJson<String?>(updatedIso),
    };
  }

  JuzProgressData copyWith({
    int? juzNumber,
    bool? completed,
    Value<String?> updatedIso = const Value.absent(),
  }) => JuzProgressData(
    juzNumber: juzNumber ?? this.juzNumber,
    completed: completed ?? this.completed,
    updatedIso: updatedIso.present ? updatedIso.value : this.updatedIso,
  );
  JuzProgressData copyWithCompanion(JuzProgressCompanion data) {
    return JuzProgressData(
      juzNumber: data.juzNumber.present ? data.juzNumber.value : this.juzNumber,
      completed: data.completed.present ? data.completed.value : this.completed,
      updatedIso: data.updatedIso.present
          ? data.updatedIso.value
          : this.updatedIso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JuzProgressData(')
          ..write('juzNumber: $juzNumber, ')
          ..write('completed: $completed, ')
          ..write('updatedIso: $updatedIso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(juzNumber, completed, updatedIso);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JuzProgressData &&
          other.juzNumber == this.juzNumber &&
          other.completed == this.completed &&
          other.updatedIso == this.updatedIso);
}

class JuzProgressCompanion extends UpdateCompanion<JuzProgressData> {
  final Value<int> juzNumber;
  final Value<bool> completed;
  final Value<String?> updatedIso;
  const JuzProgressCompanion({
    this.juzNumber = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedIso = const Value.absent(),
  });
  JuzProgressCompanion.insert({
    this.juzNumber = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedIso = const Value.absent(),
  });
  static Insertable<JuzProgressData> custom({
    Expression<int>? juzNumber,
    Expression<bool>? completed,
    Expression<String>? updatedIso,
  }) {
    return RawValuesInsertable({
      if (juzNumber != null) 'juz_number': juzNumber,
      if (completed != null) 'completed': completed,
      if (updatedIso != null) 'updated_iso': updatedIso,
    });
  }

  JuzProgressCompanion copyWith({
    Value<int>? juzNumber,
    Value<bool>? completed,
    Value<String?>? updatedIso,
  }) {
    return JuzProgressCompanion(
      juzNumber: juzNumber ?? this.juzNumber,
      completed: completed ?? this.completed,
      updatedIso: updatedIso ?? this.updatedIso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (juzNumber.present) {
      map['juz_number'] = Variable<int>(juzNumber.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (updatedIso.present) {
      map['updated_iso'] = Variable<String>(updatedIso.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JuzProgressCompanion(')
          ..write('juzNumber: $juzNumber, ')
          ..write('completed: $completed, ')
          ..write('updatedIso: $updatedIso')
          ..write(')'))
        .toString();
  }
}

class $ReadingEventsTable extends ReadingEvents
    with TableInfo<$ReadingEventsTable, ReadingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surahId,
    ayahCount,
    durationSeconds,
    readAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      )!,
    );
  }

  @override
  $ReadingEventsTable createAlias(String alias) {
    return $ReadingEventsTable(attachedDatabase, alias);
  }
}

class ReadingEvent extends DataClass implements Insertable<ReadingEvent> {
  final int id;
  final int surahId;
  final int ayahCount;
  final int durationSeconds;
  final DateTime readAt;
  const ReadingEvent({
    required this.id,
    required this.surahId,
    required this.ayahCount,
    required this.durationSeconds,
    required this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['read_at'] = Variable<DateTime>(readAt);
    return map;
  }

  ReadingEventsCompanion toCompanion(bool nullToAbsent) {
    return ReadingEventsCompanion(
      id: Value(id),
      surahId: Value(surahId),
      ayahCount: Value(ayahCount),
      durationSeconds: Value(durationSeconds),
      readAt: Value(readAt),
    );
  }

  factory ReadingEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingEvent(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      readAt: serializer.fromJson<DateTime>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'readAt': serializer.toJson<DateTime>(readAt),
    };
  }

  ReadingEvent copyWith({
    int? id,
    int? surahId,
    int? ayahCount,
    int? durationSeconds,
    DateTime? readAt,
  }) => ReadingEvent(
    id: id ?? this.id,
    surahId: surahId ?? this.surahId,
    ayahCount: ayahCount ?? this.ayahCount,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    readAt: readAt ?? this.readAt,
  );
  ReadingEvent copyWithCompanion(ReadingEventsCompanion data) {
    return ReadingEvent(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingEvent(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, surahId, ayahCount, durationSeconds, readAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingEvent &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.ayahCount == this.ayahCount &&
          other.durationSeconds == this.durationSeconds &&
          other.readAt == this.readAt);
}

class ReadingEventsCompanion extends UpdateCompanion<ReadingEvent> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> ayahCount;
  final Value<int> durationSeconds;
  final Value<DateTime> readAt;
  const ReadingEventsCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.readAt = const Value.absent(),
  });
  ReadingEventsCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int ayahCount,
    required int durationSeconds,
    required DateTime readAt,
  }) : surahId = Value(surahId),
       ayahCount = Value(ayahCount),
       durationSeconds = Value(durationSeconds),
       readAt = Value(readAt);
  static Insertable<ReadingEvent> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? ayahCount,
    Expression<int>? durationSeconds,
    Expression<DateTime>? readAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (readAt != null) 'read_at': readAt,
    });
  }

  ReadingEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? surahId,
    Value<int>? ayahCount,
    Value<int>? durationSeconds,
    Value<DateTime>? readAt,
  }) {
    return ReadingEventsCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahCount: ayahCount ?? this.ayahCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingEventsCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteSurahsTable extends FavoriteSurahs
    with TableInfo<$FavoriteSurahsTable, FavoriteSurah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteSurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [surahId, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteSurah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahId};
  @override
  FavoriteSurah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteSurah(
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $FavoriteSurahsTable createAlias(String alias) {
    return $FavoriteSurahsTable(attachedDatabase, alias);
  }
}

class FavoriteSurah extends DataClass implements Insertable<FavoriteSurah> {
  final int surahId;
  final DateTime savedAt;
  const FavoriteSurah({required this.surahId, required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_id'] = Variable<int>(surahId);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  FavoriteSurahsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteSurahsCompanion(
      surahId: Value(surahId),
      savedAt: Value(savedAt),
    );
  }

  factory FavoriteSurah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteSurah(
      surahId: serializer.fromJson<int>(json['surahId']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahId': serializer.toJson<int>(surahId),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  FavoriteSurah copyWith({int? surahId, DateTime? savedAt}) => FavoriteSurah(
    surahId: surahId ?? this.surahId,
    savedAt: savedAt ?? this.savedAt,
  );
  FavoriteSurah copyWithCompanion(FavoriteSurahsCompanion data) {
    return FavoriteSurah(
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteSurah(')
          ..write('surahId: $surahId, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahId, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteSurah &&
          other.surahId == this.surahId &&
          other.savedAt == this.savedAt);
}

class FavoriteSurahsCompanion extends UpdateCompanion<FavoriteSurah> {
  final Value<int> surahId;
  final Value<DateTime> savedAt;
  const FavoriteSurahsCompanion({
    this.surahId = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  FavoriteSurahsCompanion.insert({
    this.surahId = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  static Insertable<FavoriteSurah> custom({
    Expression<int>? surahId,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (surahId != null) 'surah_id': surahId,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  FavoriteSurahsCompanion copyWith({
    Value<int>? surahId,
    Value<DateTime>? savedAt,
  }) {
    return FavoriteSurahsCompanion(
      surahId: surahId ?? this.surahId,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteSurahsCompanion(')
          ..write('surahId: $surahId, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EsmaNamesTable esmaNames = $EsmaNamesTable(this);
  late final $DuasTable duas = $DuasTable(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $TopicalAyahsTable topicalAyahs = $TopicalAyahsTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $MiraclesTable miracles = $MiraclesTable(this);
  late final $TajweedLessonsTable tajweedLessons = $TajweedLessonsTable(this);
  late final $DreamSymbolsTable dreamSymbols = $DreamSymbolsTable(this);
  late final $DhikrCountersTable dhikrCounters = $DhikrCountersTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $MemorizationsTable memorizations = $MemorizationsTable(this);
  late final $JuzProgressTable juzProgress = $JuzProgressTable(this);
  late final $ReadingEventsTable readingEvents = $ReadingEventsTable(this);
  late final $FavoriteSurahsTable favoriteSurahs = $FavoriteSurahsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    esmaNames,
    duas,
    surahs,
    ayahs,
    topicalAyahs,
    stories,
    miracles,
    tajweedLessons,
    dreamSymbols,
    dhikrCounters,
    collections,
    memorizations,
    juzProgress,
    readingEvents,
    favoriteSurahs,
  ];
}

typedef $$EsmaNamesTableCreateCompanionBuilder =
    EsmaNamesCompanion Function({
      Value<int> id,
      required int order,
      required String name,
      required String arabic,
      required String meaning,
    });
typedef $$EsmaNamesTableUpdateCompanionBuilder =
    EsmaNamesCompanion Function({
      Value<int> id,
      Value<int> order,
      Value<String> name,
      Value<String> arabic,
      Value<String> meaning,
    });

class $$EsmaNamesTableFilterComposer
    extends Composer<_$AppDatabase, $EsmaNamesTable> {
  $$EsmaNamesTableFilterComposer({
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

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EsmaNamesTableOrderingComposer
    extends Composer<_$AppDatabase, $EsmaNamesTable> {
  $$EsmaNamesTableOrderingComposer({
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

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EsmaNamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EsmaNamesTable> {
  $$EsmaNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);
}

class $$EsmaNamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EsmaNamesTable,
          EsmaName,
          $$EsmaNamesTableFilterComposer,
          $$EsmaNamesTableOrderingComposer,
          $$EsmaNamesTableAnnotationComposer,
          $$EsmaNamesTableCreateCompanionBuilder,
          $$EsmaNamesTableUpdateCompanionBuilder,
          (EsmaName, BaseReferences<_$AppDatabase, $EsmaNamesTable, EsmaName>),
          EsmaName,
          PrefetchHooks Function()
        > {
  $$EsmaNamesTableTableManager(_$AppDatabase db, $EsmaNamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EsmaNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EsmaNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EsmaNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> meaning = const Value.absent(),
              }) => EsmaNamesCompanion(
                id: id,
                order: order,
                name: name,
                arabic: arabic,
                meaning: meaning,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int order,
                required String name,
                required String arabic,
                required String meaning,
              }) => EsmaNamesCompanion.insert(
                id: id,
                order: order,
                name: name,
                arabic: arabic,
                meaning: meaning,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EsmaNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EsmaNamesTable,
      EsmaName,
      $$EsmaNamesTableFilterComposer,
      $$EsmaNamesTableOrderingComposer,
      $$EsmaNamesTableAnnotationComposer,
      $$EsmaNamesTableCreateCompanionBuilder,
      $$EsmaNamesTableUpdateCompanionBuilder,
      (EsmaName, BaseReferences<_$AppDatabase, $EsmaNamesTable, EsmaName>),
      EsmaName,
      PrefetchHooks Function()
    >;
typedef $$DuasTableCreateCompanionBuilder =
    DuasCompanion Function({
      Value<int> id,
      required String title,
      required String category,
      required String arabic,
      Value<String> latin,
      required String body,
      Value<String> source,
    });
typedef $$DuasTableUpdateCompanionBuilder =
    DuasCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> category,
      Value<String> arabic,
      Value<String> latin,
      Value<String> body,
      Value<String> source,
    });

class $$DuasTableFilterComposer extends Composer<_$AppDatabase, $DuasTable> {
  $$DuasTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latin => $composableBuilder(
    column: $table.latin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DuasTableOrderingComposer extends Composer<_$AppDatabase, $DuasTable> {
  $$DuasTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latin => $composableBuilder(
    column: $table.latin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DuasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuasTable> {
  $$DuasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get latin =>
      $composableBuilder(column: $table.latin, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DuasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuasTable,
          Dua,
          $$DuasTableFilterComposer,
          $$DuasTableOrderingComposer,
          $$DuasTableAnnotationComposer,
          $$DuasTableCreateCompanionBuilder,
          $$DuasTableUpdateCompanionBuilder,
          (Dua, BaseReferences<_$AppDatabase, $DuasTable, Dua>),
          Dua,
          PrefetchHooks Function()
        > {
  $$DuasTableTableManager(_$AppDatabase db, $DuasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DuasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> latin = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => DuasCompanion(
                id: id,
                title: title,
                category: category,
                arabic: arabic,
                latin: latin,
                body: body,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String category,
                required String arabic,
                Value<String> latin = const Value.absent(),
                required String body,
                Value<String> source = const Value.absent(),
              }) => DuasCompanion.insert(
                id: id,
                title: title,
                category: category,
                arabic: arabic,
                latin: latin,
                body: body,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DuasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuasTable,
      Dua,
      $$DuasTableFilterComposer,
      $$DuasTableOrderingComposer,
      $$DuasTableAnnotationComposer,
      $$DuasTableCreateCompanionBuilder,
      $$DuasTableUpdateCompanionBuilder,
      (Dua, BaseReferences<_$AppDatabase, $DuasTable, Dua>),
      Dua,
      PrefetchHooks Function()
    >;
typedef $$SurahsTableCreateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> number,
      required String nameTr,
      required String nameArabic,
      required String meaning,
      required int ayahCount,
      required String revelation,
      Value<int> juzStart,
    });
typedef $$SurahsTableUpdateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> number,
      Value<String> nameTr,
      Value<String> nameArabic,
      Value<String> meaning,
      Value<int> ayahCount,
      Value<String> revelation,
      Value<int> juzStart,
    });

class $$SurahsTableFilterComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameTr => $composableBuilder(
    column: $table.nameTr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameArabic => $composableBuilder(
    column: $table.nameArabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get juzStart => $composableBuilder(
    column: $table.juzStart,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurahsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameTr => $composableBuilder(
    column: $table.nameTr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameArabic => $composableBuilder(
    column: $table.nameArabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get juzStart => $composableBuilder(
    column: $table.juzStart,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get nameTr =>
      $composableBuilder(column: $table.nameTr, builder: (column) => column);

  GeneratedColumn<String> get nameArabic => $composableBuilder(
    column: $table.nameArabic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get juzStart =>
      $composableBuilder(column: $table.juzStart, builder: (column) => column);
}

class $$SurahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurahsTable,
          Surah,
          $$SurahsTableFilterComposer,
          $$SurahsTableOrderingComposer,
          $$SurahsTableAnnotationComposer,
          $$SurahsTableCreateCompanionBuilder,
          $$SurahsTableUpdateCompanionBuilder,
          (Surah, BaseReferences<_$AppDatabase, $SurahsTable, Surah>),
          Surah,
          PrefetchHooks Function()
        > {
  $$SurahsTableTableManager(_$AppDatabase db, $SurahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<String> nameTr = const Value.absent(),
                Value<String> nameArabic = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<String> revelation = const Value.absent(),
                Value<int> juzStart = const Value.absent(),
              }) => SurahsCompanion(
                number: number,
                nameTr: nameTr,
                nameArabic: nameArabic,
                meaning: meaning,
                ayahCount: ayahCount,
                revelation: revelation,
                juzStart: juzStart,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required String nameTr,
                required String nameArabic,
                required String meaning,
                required int ayahCount,
                required String revelation,
                Value<int> juzStart = const Value.absent(),
              }) => SurahsCompanion.insert(
                number: number,
                nameTr: nameTr,
                nameArabic: nameArabic,
                meaning: meaning,
                ayahCount: ayahCount,
                revelation: revelation,
                juzStart: juzStart,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurahsTable,
      Surah,
      $$SurahsTableFilterComposer,
      $$SurahsTableOrderingComposer,
      $$SurahsTableAnnotationComposer,
      $$SurahsTableCreateCompanionBuilder,
      $$SurahsTableUpdateCompanionBuilder,
      (Surah, BaseReferences<_$AppDatabase, $SurahsTable, Surah>),
      Surah,
      PrefetchHooks Function()
    >;
typedef $$AyahsTableCreateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      required int surahNumber,
      required int numberInSurah,
      required String arabic,
      required String meal,
      Value<String?> tafsir,
    });
typedef $$AyahsTableUpdateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      Value<int> surahNumber,
      Value<int> numberInSurah,
      Value<String> arabic,
      Value<String> meal,
      Value<String?> tafsir,
    });

class $$AyahsTableFilterComposer extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
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

  ColumnFilters<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberInSurah => $composableBuilder(
    column: $table.numberInSurah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tafsir => $composableBuilder(
    column: $table.tafsir,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahsTableOrderingComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
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

  ColumnOrderings<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberInSurah => $composableBuilder(
    column: $table.numberInSurah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tafsir => $composableBuilder(
    column: $table.tafsir,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numberInSurah => $composableBuilder(
    column: $table.numberInSurah,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get tafsir =>
      $composableBuilder(column: $table.tafsir, builder: (column) => column);
}

class $$AyahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AyahsTable,
          Ayah,
          $$AyahsTableFilterComposer,
          $$AyahsTableOrderingComposer,
          $$AyahsTableAnnotationComposer,
          $$AyahsTableCreateCompanionBuilder,
          $$AyahsTableUpdateCompanionBuilder,
          (Ayah, BaseReferences<_$AppDatabase, $AyahsTable, Ayah>),
          Ayah,
          PrefetchHooks Function()
        > {
  $$AyahsTableTableManager(_$AppDatabase db, $AyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahNumber = const Value.absent(),
                Value<int> numberInSurah = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> meal = const Value.absent(),
                Value<String?> tafsir = const Value.absent(),
              }) => AyahsCompanion(
                id: id,
                surahNumber: surahNumber,
                numberInSurah: numberInSurah,
                arabic: arabic,
                meal: meal,
                tafsir: tafsir,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahNumber,
                required int numberInSurah,
                required String arabic,
                required String meal,
                Value<String?> tafsir = const Value.absent(),
              }) => AyahsCompanion.insert(
                id: id,
                surahNumber: surahNumber,
                numberInSurah: numberInSurah,
                arabic: arabic,
                meal: meal,
                tafsir: tafsir,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AyahsTable,
      Ayah,
      $$AyahsTableFilterComposer,
      $$AyahsTableOrderingComposer,
      $$AyahsTableAnnotationComposer,
      $$AyahsTableCreateCompanionBuilder,
      $$AyahsTableUpdateCompanionBuilder,
      (Ayah, BaseReferences<_$AppDatabase, $AyahsTable, Ayah>),
      Ayah,
      PrefetchHooks Function()
    >;
typedef $$TopicalAyahsTableCreateCompanionBuilder =
    TopicalAyahsCompanion Function({
      Value<int> id,
      required String topic,
      required String reference,
      required String arabic,
      required String meal,
    });
typedef $$TopicalAyahsTableUpdateCompanionBuilder =
    TopicalAyahsCompanion Function({
      Value<int> id,
      Value<String> topic,
      Value<String> reference,
      Value<String> arabic,
      Value<String> meal,
    });

class $$TopicalAyahsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicalAyahsTable> {
  $$TopicalAyahsTableFilterComposer({
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

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicalAyahsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicalAyahsTable> {
  $$TopicalAyahsTableOrderingComposer({
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

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicalAyahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicalAyahsTable> {
  $$TopicalAyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);
}

class $$TopicalAyahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicalAyahsTable,
          TopicalAyah,
          $$TopicalAyahsTableFilterComposer,
          $$TopicalAyahsTableOrderingComposer,
          $$TopicalAyahsTableAnnotationComposer,
          $$TopicalAyahsTableCreateCompanionBuilder,
          $$TopicalAyahsTableUpdateCompanionBuilder,
          (
            TopicalAyah,
            BaseReferences<_$AppDatabase, $TopicalAyahsTable, TopicalAyah>,
          ),
          TopicalAyah,
          PrefetchHooks Function()
        > {
  $$TopicalAyahsTableTableManager(_$AppDatabase db, $TopicalAyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicalAyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicalAyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicalAyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> meal = const Value.absent(),
              }) => TopicalAyahsCompanion(
                id: id,
                topic: topic,
                reference: reference,
                arabic: arabic,
                meal: meal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String topic,
                required String reference,
                required String arabic,
                required String meal,
              }) => TopicalAyahsCompanion.insert(
                id: id,
                topic: topic,
                reference: reference,
                arabic: arabic,
                meal: meal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicalAyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicalAyahsTable,
      TopicalAyah,
      $$TopicalAyahsTableFilterComposer,
      $$TopicalAyahsTableOrderingComposer,
      $$TopicalAyahsTableAnnotationComposer,
      $$TopicalAyahsTableCreateCompanionBuilder,
      $$TopicalAyahsTableUpdateCompanionBuilder,
      (
        TopicalAyah,
        BaseReferences<_$AppDatabase, $TopicalAyahsTable, TopicalAyah>,
      ),
      TopicalAyah,
      PrefetchHooks Function()
    >;
typedef $$StoriesTableCreateCompanionBuilder =
    StoriesCompanion Function({
      Value<int> id,
      required int order,
      required String title,
      required String category,
      required int readMinutes,
      required String summary,
      required String body,
    });
typedef $$StoriesTableUpdateCompanionBuilder =
    StoriesCompanion Function({
      Value<int> id,
      Value<int> order,
      Value<String> title,
      Value<String> category,
      Value<int> readMinutes,
      Value<String> summary,
      Value<String> body,
    });

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
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

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readMinutes => $composableBuilder(
    column: $table.readMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
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

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readMinutes => $composableBuilder(
    column: $table.readMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get readMinutes => $composableBuilder(
    column: $table.readMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoriesTable,
          Story,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (Story, BaseReferences<_$AppDatabase, $StoriesTable, Story>),
          Story,
          PrefetchHooks Function()
        > {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> readMinutes = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> body = const Value.absent(),
              }) => StoriesCompanion(
                id: id,
                order: order,
                title: title,
                category: category,
                readMinutes: readMinutes,
                summary: summary,
                body: body,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int order,
                required String title,
                required String category,
                required int readMinutes,
                required String summary,
                required String body,
              }) => StoriesCompanion.insert(
                id: id,
                order: order,
                title: title,
                category: category,
                readMinutes: readMinutes,
                summary: summary,
                body: body,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoriesTable,
      Story,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (Story, BaseReferences<_$AppDatabase, $StoriesTable, Story>),
      Story,
      PrefetchHooks Function()
    >;
typedef $$MiraclesTableCreateCompanionBuilder =
    MiraclesCompanion Function({
      Value<int> id,
      required String category,
      required String title,
      required String body,
    });
typedef $$MiraclesTableUpdateCompanionBuilder =
    MiraclesCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<String> title,
      Value<String> body,
    });

class $$MiraclesTableFilterComposer
    extends Composer<_$AppDatabase, $MiraclesTable> {
  $$MiraclesTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MiraclesTableOrderingComposer
    extends Composer<_$AppDatabase, $MiraclesTable> {
  $$MiraclesTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MiraclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MiraclesTable> {
  $$MiraclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$MiraclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MiraclesTable,
          Miracle,
          $$MiraclesTableFilterComposer,
          $$MiraclesTableOrderingComposer,
          $$MiraclesTableAnnotationComposer,
          $$MiraclesTableCreateCompanionBuilder,
          $$MiraclesTableUpdateCompanionBuilder,
          (Miracle, BaseReferences<_$AppDatabase, $MiraclesTable, Miracle>),
          Miracle,
          PrefetchHooks Function()
        > {
  $$MiraclesTableTableManager(_$AppDatabase db, $MiraclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MiraclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MiraclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MiraclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
              }) => MiraclesCompanion(
                id: id,
                category: category,
                title: title,
                body: body,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                required String title,
                required String body,
              }) => MiraclesCompanion.insert(
                id: id,
                category: category,
                title: title,
                body: body,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MiraclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MiraclesTable,
      Miracle,
      $$MiraclesTableFilterComposer,
      $$MiraclesTableOrderingComposer,
      $$MiraclesTableAnnotationComposer,
      $$MiraclesTableCreateCompanionBuilder,
      $$MiraclesTableUpdateCompanionBuilder,
      (Miracle, BaseReferences<_$AppDatabase, $MiraclesTable, Miracle>),
      Miracle,
      PrefetchHooks Function()
    >;
typedef $$TajweedLessonsTableCreateCompanionBuilder =
    TajweedLessonsCompanion Function({
      Value<int> id,
      required int order,
      required String title,
      required String rule,
      required String example,
      required String body,
    });
typedef $$TajweedLessonsTableUpdateCompanionBuilder =
    TajweedLessonsCompanion Function({
      Value<int> id,
      Value<int> order,
      Value<String> title,
      Value<String> rule,
      Value<String> example,
      Value<String> body,
    });

class $$TajweedLessonsTableFilterComposer
    extends Composer<_$AppDatabase, $TajweedLessonsTable> {
  $$TajweedLessonsTableFilterComposer({
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

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TajweedLessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $TajweedLessonsTable> {
  $$TajweedLessonsTableOrderingComposer({
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

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TajweedLessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TajweedLessonsTable> {
  $$TajweedLessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get rule =>
      $composableBuilder(column: $table.rule, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$TajweedLessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TajweedLessonsTable,
          TajweedLesson,
          $$TajweedLessonsTableFilterComposer,
          $$TajweedLessonsTableOrderingComposer,
          $$TajweedLessonsTableAnnotationComposer,
          $$TajweedLessonsTableCreateCompanionBuilder,
          $$TajweedLessonsTableUpdateCompanionBuilder,
          (
            TajweedLesson,
            BaseReferences<_$AppDatabase, $TajweedLessonsTable, TajweedLesson>,
          ),
          TajweedLesson,
          PrefetchHooks Function()
        > {
  $$TajweedLessonsTableTableManager(
    _$AppDatabase db,
    $TajweedLessonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TajweedLessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TajweedLessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TajweedLessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> rule = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String> body = const Value.absent(),
              }) => TajweedLessonsCompanion(
                id: id,
                order: order,
                title: title,
                rule: rule,
                example: example,
                body: body,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int order,
                required String title,
                required String rule,
                required String example,
                required String body,
              }) => TajweedLessonsCompanion.insert(
                id: id,
                order: order,
                title: title,
                rule: rule,
                example: example,
                body: body,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TajweedLessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TajweedLessonsTable,
      TajweedLesson,
      $$TajweedLessonsTableFilterComposer,
      $$TajweedLessonsTableOrderingComposer,
      $$TajweedLessonsTableAnnotationComposer,
      $$TajweedLessonsTableCreateCompanionBuilder,
      $$TajweedLessonsTableUpdateCompanionBuilder,
      (
        TajweedLesson,
        BaseReferences<_$AppDatabase, $TajweedLessonsTable, TajweedLesson>,
      ),
      TajweedLesson,
      PrefetchHooks Function()
    >;
typedef $$DreamSymbolsTableCreateCompanionBuilder =
    DreamSymbolsCompanion Function({
      Value<int> id,
      required String term,
      required String category,
      required String meaning,
      Value<String> source,
    });
typedef $$DreamSymbolsTableUpdateCompanionBuilder =
    DreamSymbolsCompanion Function({
      Value<int> id,
      Value<String> term,
      Value<String> category,
      Value<String> meaning,
      Value<String> source,
    });

class $$DreamSymbolsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamSymbolsTable> {
  $$DreamSymbolsTableFilterComposer({
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

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DreamSymbolsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamSymbolsTable> {
  $$DreamSymbolsTableOrderingComposer({
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

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DreamSymbolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamSymbolsTable> {
  $$DreamSymbolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DreamSymbolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamSymbolsTable,
          DreamSymbol,
          $$DreamSymbolsTableFilterComposer,
          $$DreamSymbolsTableOrderingComposer,
          $$DreamSymbolsTableAnnotationComposer,
          $$DreamSymbolsTableCreateCompanionBuilder,
          $$DreamSymbolsTableUpdateCompanionBuilder,
          (
            DreamSymbol,
            BaseReferences<_$AppDatabase, $DreamSymbolsTable, DreamSymbol>,
          ),
          DreamSymbol,
          PrefetchHooks Function()
        > {
  $$DreamSymbolsTableTableManager(_$AppDatabase db, $DreamSymbolsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamSymbolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamSymbolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamSymbolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => DreamSymbolsCompanion(
                id: id,
                term: term,
                category: category,
                meaning: meaning,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String term,
                required String category,
                required String meaning,
                Value<String> source = const Value.absent(),
              }) => DreamSymbolsCompanion.insert(
                id: id,
                term: term,
                category: category,
                meaning: meaning,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DreamSymbolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamSymbolsTable,
      DreamSymbol,
      $$DreamSymbolsTableFilterComposer,
      $$DreamSymbolsTableOrderingComposer,
      $$DreamSymbolsTableAnnotationComposer,
      $$DreamSymbolsTableCreateCompanionBuilder,
      $$DreamSymbolsTableUpdateCompanionBuilder,
      (
        DreamSymbol,
        BaseReferences<_$AppDatabase, $DreamSymbolsTable, DreamSymbol>,
      ),
      DreamSymbol,
      PrefetchHooks Function()
    >;
typedef $$DhikrCountersTableCreateCompanionBuilder =
    DhikrCountersCompanion Function({
      Value<int> id,
      required String dateIso,
      required String dhikrKey,
      Value<int> count,
    });
typedef $$DhikrCountersTableUpdateCompanionBuilder =
    DhikrCountersCompanion Function({
      Value<int> id,
      Value<String> dateIso,
      Value<String> dhikrKey,
      Value<int> count,
    });

class $$DhikrCountersTableFilterComposer
    extends Composer<_$AppDatabase, $DhikrCountersTable> {
  $$DhikrCountersTableFilterComposer({
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

  ColumnFilters<String> get dateIso => $composableBuilder(
    column: $table.dateIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dhikrKey => $composableBuilder(
    column: $table.dhikrKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DhikrCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $DhikrCountersTable> {
  $$DhikrCountersTableOrderingComposer({
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

  ColumnOrderings<String> get dateIso => $composableBuilder(
    column: $table.dateIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dhikrKey => $composableBuilder(
    column: $table.dhikrKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DhikrCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DhikrCountersTable> {
  $$DhikrCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateIso =>
      $composableBuilder(column: $table.dateIso, builder: (column) => column);

  GeneratedColumn<String> get dhikrKey =>
      $composableBuilder(column: $table.dhikrKey, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$DhikrCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DhikrCountersTable,
          DhikrCounter,
          $$DhikrCountersTableFilterComposer,
          $$DhikrCountersTableOrderingComposer,
          $$DhikrCountersTableAnnotationComposer,
          $$DhikrCountersTableCreateCompanionBuilder,
          $$DhikrCountersTableUpdateCompanionBuilder,
          (
            DhikrCounter,
            BaseReferences<_$AppDatabase, $DhikrCountersTable, DhikrCounter>,
          ),
          DhikrCounter,
          PrefetchHooks Function()
        > {
  $$DhikrCountersTableTableManager(_$AppDatabase db, $DhikrCountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DhikrCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DhikrCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DhikrCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dateIso = const Value.absent(),
                Value<String> dhikrKey = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => DhikrCountersCompanion(
                id: id,
                dateIso: dateIso,
                dhikrKey: dhikrKey,
                count: count,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dateIso,
                required String dhikrKey,
                Value<int> count = const Value.absent(),
              }) => DhikrCountersCompanion.insert(
                id: id,
                dateIso: dateIso,
                dhikrKey: dhikrKey,
                count: count,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DhikrCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DhikrCountersTable,
      DhikrCounter,
      $$DhikrCountersTableFilterComposer,
      $$DhikrCountersTableOrderingComposer,
      $$DhikrCountersTableAnnotationComposer,
      $$DhikrCountersTableCreateCompanionBuilder,
      $$DhikrCountersTableUpdateCompanionBuilder,
      (
        DhikrCounter,
        BaseReferences<_$AppDatabase, $DhikrCountersTable, DhikrCounter>,
      ),
      DhikrCounter,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      required String reference,
      required String arabic,
      required String meal,
      Value<String?> note,
      required String createdIso,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      Value<String> reference,
      Value<String> arabic,
      Value<String> meal,
      Value<String?> note,
      Value<String> createdIso,
    });

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
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

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdIso => $composableBuilder(
    column: $table.createdIso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdIso => $composableBuilder(
    column: $table.createdIso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdIso => $composableBuilder(
    column: $table.createdIso,
    builder: (column) => column,
  );
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (
            Collection,
            BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
          ),
          Collection,
          PrefetchHooks Function()
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> meal = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdIso = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                reference: reference,
                arabic: arabic,
                meal: meal,
                note: note,
                createdIso: createdIso,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String reference,
                required String arabic,
                required String meal,
                Value<String?> note = const Value.absent(),
                required String createdIso,
              }) => CollectionsCompanion.insert(
                id: id,
                reference: reference,
                arabic: arabic,
                meal: meal,
                note: note,
                createdIso: createdIso,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (
        Collection,
        BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
      ),
      Collection,
      PrefetchHooks Function()
    >;
typedef $$MemorizationsTableCreateCompanionBuilder =
    MemorizationsCompanion Function({
      Value<int> id,
      required int surahNumber,
      required String surahName,
      required int totalAyahs,
      Value<int> memorizedAyahs,
      Value<String?> lastReviewIso,
    });
typedef $$MemorizationsTableUpdateCompanionBuilder =
    MemorizationsCompanion Function({
      Value<int> id,
      Value<int> surahNumber,
      Value<String> surahName,
      Value<int> totalAyahs,
      Value<int> memorizedAyahs,
      Value<String?> lastReviewIso,
    });

class $$MemorizationsTableFilterComposer
    extends Composer<_$AppDatabase, $MemorizationsTable> {
  $$MemorizationsTableFilterComposer({
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

  ColumnFilters<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surahName => $composableBuilder(
    column: $table.surahName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAyahs => $composableBuilder(
    column: $table.totalAyahs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memorizedAyahs => $composableBuilder(
    column: $table.memorizedAyahs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReviewIso => $composableBuilder(
    column: $table.lastReviewIso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemorizationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemorizationsTable> {
  $$MemorizationsTableOrderingComposer({
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

  ColumnOrderings<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surahName => $composableBuilder(
    column: $table.surahName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAyahs => $composableBuilder(
    column: $table.totalAyahs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memorizedAyahs => $composableBuilder(
    column: $table.memorizedAyahs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReviewIso => $composableBuilder(
    column: $table.lastReviewIso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemorizationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemorizationsTable> {
  $$MemorizationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surahNumber => $composableBuilder(
    column: $table.surahNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surahName =>
      $composableBuilder(column: $table.surahName, builder: (column) => column);

  GeneratedColumn<int> get totalAyahs => $composableBuilder(
    column: $table.totalAyahs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memorizedAyahs => $composableBuilder(
    column: $table.memorizedAyahs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReviewIso => $composableBuilder(
    column: $table.lastReviewIso,
    builder: (column) => column,
  );
}

class $$MemorizationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemorizationsTable,
          Memorization,
          $$MemorizationsTableFilterComposer,
          $$MemorizationsTableOrderingComposer,
          $$MemorizationsTableAnnotationComposer,
          $$MemorizationsTableCreateCompanionBuilder,
          $$MemorizationsTableUpdateCompanionBuilder,
          (
            Memorization,
            BaseReferences<_$AppDatabase, $MemorizationsTable, Memorization>,
          ),
          Memorization,
          PrefetchHooks Function()
        > {
  $$MemorizationsTableTableManager(_$AppDatabase db, $MemorizationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemorizationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahNumber = const Value.absent(),
                Value<String> surahName = const Value.absent(),
                Value<int> totalAyahs = const Value.absent(),
                Value<int> memorizedAyahs = const Value.absent(),
                Value<String?> lastReviewIso = const Value.absent(),
              }) => MemorizationsCompanion(
                id: id,
                surahNumber: surahNumber,
                surahName: surahName,
                totalAyahs: totalAyahs,
                memorizedAyahs: memorizedAyahs,
                lastReviewIso: lastReviewIso,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahNumber,
                required String surahName,
                required int totalAyahs,
                Value<int> memorizedAyahs = const Value.absent(),
                Value<String?> lastReviewIso = const Value.absent(),
              }) => MemorizationsCompanion.insert(
                id: id,
                surahNumber: surahNumber,
                surahName: surahName,
                totalAyahs: totalAyahs,
                memorizedAyahs: memorizedAyahs,
                lastReviewIso: lastReviewIso,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemorizationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemorizationsTable,
      Memorization,
      $$MemorizationsTableFilterComposer,
      $$MemorizationsTableOrderingComposer,
      $$MemorizationsTableAnnotationComposer,
      $$MemorizationsTableCreateCompanionBuilder,
      $$MemorizationsTableUpdateCompanionBuilder,
      (
        Memorization,
        BaseReferences<_$AppDatabase, $MemorizationsTable, Memorization>,
      ),
      Memorization,
      PrefetchHooks Function()
    >;
typedef $$JuzProgressTableCreateCompanionBuilder =
    JuzProgressCompanion Function({
      Value<int> juzNumber,
      Value<bool> completed,
      Value<String?> updatedIso,
    });
typedef $$JuzProgressTableUpdateCompanionBuilder =
    JuzProgressCompanion Function({
      Value<int> juzNumber,
      Value<bool> completed,
      Value<String?> updatedIso,
    });

class $$JuzProgressTableFilterComposer
    extends Composer<_$AppDatabase, $JuzProgressTable> {
  $$JuzProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get juzNumber => $composableBuilder(
    column: $table.juzNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedIso => $composableBuilder(
    column: $table.updatedIso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JuzProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $JuzProgressTable> {
  $$JuzProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get juzNumber => $composableBuilder(
    column: $table.juzNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedIso => $composableBuilder(
    column: $table.updatedIso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JuzProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $JuzProgressTable> {
  $$JuzProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get juzNumber =>
      $composableBuilder(column: $table.juzNumber, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get updatedIso => $composableBuilder(
    column: $table.updatedIso,
    builder: (column) => column,
  );
}

class $$JuzProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JuzProgressTable,
          JuzProgressData,
          $$JuzProgressTableFilterComposer,
          $$JuzProgressTableOrderingComposer,
          $$JuzProgressTableAnnotationComposer,
          $$JuzProgressTableCreateCompanionBuilder,
          $$JuzProgressTableUpdateCompanionBuilder,
          (
            JuzProgressData,
            BaseReferences<_$AppDatabase, $JuzProgressTable, JuzProgressData>,
          ),
          JuzProgressData,
          PrefetchHooks Function()
        > {
  $$JuzProgressTableTableManager(_$AppDatabase db, $JuzProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JuzProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JuzProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JuzProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> juzNumber = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> updatedIso = const Value.absent(),
              }) => JuzProgressCompanion(
                juzNumber: juzNumber,
                completed: completed,
                updatedIso: updatedIso,
              ),
          createCompanionCallback:
              ({
                Value<int> juzNumber = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> updatedIso = const Value.absent(),
              }) => JuzProgressCompanion.insert(
                juzNumber: juzNumber,
                completed: completed,
                updatedIso: updatedIso,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JuzProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JuzProgressTable,
      JuzProgressData,
      $$JuzProgressTableFilterComposer,
      $$JuzProgressTableOrderingComposer,
      $$JuzProgressTableAnnotationComposer,
      $$JuzProgressTableCreateCompanionBuilder,
      $$JuzProgressTableUpdateCompanionBuilder,
      (
        JuzProgressData,
        BaseReferences<_$AppDatabase, $JuzProgressTable, JuzProgressData>,
      ),
      JuzProgressData,
      PrefetchHooks Function()
    >;
typedef $$ReadingEventsTableCreateCompanionBuilder =
    ReadingEventsCompanion Function({
      Value<int> id,
      required int surahId,
      required int ayahCount,
      required int durationSeconds,
      required DateTime readAt,
    });
typedef $$ReadingEventsTableUpdateCompanionBuilder =
    ReadingEventsCompanion Function({
      Value<int> id,
      Value<int> surahId,
      Value<int> ayahCount,
      Value<int> durationSeconds,
      Value<DateTime> readAt,
    });

class $$ReadingEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingEventsTable> {
  $$ReadingEventsTableFilterComposer({
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

  ColumnFilters<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingEventsTable> {
  $$ReadingEventsTableOrderingComposer({
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

  ColumnOrderings<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingEventsTable> {
  $$ReadingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);
}

class $$ReadingEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingEventsTable,
          ReadingEvent,
          $$ReadingEventsTableFilterComposer,
          $$ReadingEventsTableOrderingComposer,
          $$ReadingEventsTableAnnotationComposer,
          $$ReadingEventsTableCreateCompanionBuilder,
          $$ReadingEventsTableUpdateCompanionBuilder,
          (
            ReadingEvent,
            BaseReferences<_$AppDatabase, $ReadingEventsTable, ReadingEvent>,
          ),
          ReadingEvent,
          PrefetchHooks Function()
        > {
  $$ReadingEventsTableTableManager(_$AppDatabase db, $ReadingEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<DateTime> readAt = const Value.absent(),
              }) => ReadingEventsCompanion(
                id: id,
                surahId: surahId,
                ayahCount: ayahCount,
                durationSeconds: durationSeconds,
                readAt: readAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahId,
                required int ayahCount,
                required int durationSeconds,
                required DateTime readAt,
              }) => ReadingEventsCompanion.insert(
                id: id,
                surahId: surahId,
                ayahCount: ayahCount,
                durationSeconds: durationSeconds,
                readAt: readAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingEventsTable,
      ReadingEvent,
      $$ReadingEventsTableFilterComposer,
      $$ReadingEventsTableOrderingComposer,
      $$ReadingEventsTableAnnotationComposer,
      $$ReadingEventsTableCreateCompanionBuilder,
      $$ReadingEventsTableUpdateCompanionBuilder,
      (
        ReadingEvent,
        BaseReferences<_$AppDatabase, $ReadingEventsTable, ReadingEvent>,
      ),
      ReadingEvent,
      PrefetchHooks Function()
    >;
typedef $$FavoriteSurahsTableCreateCompanionBuilder =
    FavoriteSurahsCompanion Function({
      Value<int> surahId,
      Value<DateTime> savedAt,
    });
typedef $$FavoriteSurahsTableUpdateCompanionBuilder =
    FavoriteSurahsCompanion Function({
      Value<int> surahId,
      Value<DateTime> savedAt,
    });

class $$FavoriteSurahsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteSurahsTable> {
  $$FavoriteSurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteSurahsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteSurahsTable> {
  $$FavoriteSurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteSurahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteSurahsTable> {
  $$FavoriteSurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$FavoriteSurahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteSurahsTable,
          FavoriteSurah,
          $$FavoriteSurahsTableFilterComposer,
          $$FavoriteSurahsTableOrderingComposer,
          $$FavoriteSurahsTableAnnotationComposer,
          $$FavoriteSurahsTableCreateCompanionBuilder,
          $$FavoriteSurahsTableUpdateCompanionBuilder,
          (
            FavoriteSurah,
            BaseReferences<_$AppDatabase, $FavoriteSurahsTable, FavoriteSurah>,
          ),
          FavoriteSurah,
          PrefetchHooks Function()
        > {
  $$FavoriteSurahsTableTableManager(
    _$AppDatabase db,
    $FavoriteSurahsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteSurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteSurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteSurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surahId = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => FavoriteSurahsCompanion(surahId: surahId, savedAt: savedAt),
          createCompanionCallback:
              ({
                Value<int> surahId = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => FavoriteSurahsCompanion.insert(
                surahId: surahId,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteSurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteSurahsTable,
      FavoriteSurah,
      $$FavoriteSurahsTableFilterComposer,
      $$FavoriteSurahsTableOrderingComposer,
      $$FavoriteSurahsTableAnnotationComposer,
      $$FavoriteSurahsTableCreateCompanionBuilder,
      $$FavoriteSurahsTableUpdateCompanionBuilder,
      (
        FavoriteSurah,
        BaseReferences<_$AppDatabase, $FavoriteSurahsTable, FavoriteSurah>,
      ),
      FavoriteSurah,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EsmaNamesTableTableManager get esmaNames =>
      $$EsmaNamesTableTableManager(_db, _db.esmaNames);
  $$DuasTableTableManager get duas => $$DuasTableTableManager(_db, _db.duas);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$TopicalAyahsTableTableManager get topicalAyahs =>
      $$TopicalAyahsTableTableManager(_db, _db.topicalAyahs);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$MiraclesTableTableManager get miracles =>
      $$MiraclesTableTableManager(_db, _db.miracles);
  $$TajweedLessonsTableTableManager get tajweedLessons =>
      $$TajweedLessonsTableTableManager(_db, _db.tajweedLessons);
  $$DreamSymbolsTableTableManager get dreamSymbols =>
      $$DreamSymbolsTableTableManager(_db, _db.dreamSymbols);
  $$DhikrCountersTableTableManager get dhikrCounters =>
      $$DhikrCountersTableTableManager(_db, _db.dhikrCounters);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$MemorizationsTableTableManager get memorizations =>
      $$MemorizationsTableTableManager(_db, _db.memorizations);
  $$JuzProgressTableTableManager get juzProgress =>
      $$JuzProgressTableTableManager(_db, _db.juzProgress);
  $$ReadingEventsTableTableManager get readingEvents =>
      $$ReadingEventsTableTableManager(_db, _db.readingEvents);
  $$FavoriteSurahsTableTableManager get favoriteSurahs =>
      $$FavoriteSurahsTableTableManager(_db, _db.favoriteSurahs);
}
