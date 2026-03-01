// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClassesTable extends Classes with TableInfo<$ClassesTable, SchoolClass> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _schoolYearMeta =
      const VerificationMeta('schoolYear');
  @override
  late final GeneratedColumn<String> schoolYear = GeneratedColumn<String>(
      'school_year', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, schoolYear];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classes';
  @override
  VerificationContext validateIntegrity(Insertable<SchoolClass> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('school_year')) {
      context.handle(
          _schoolYearMeta,
          schoolYear.isAcceptableOrUnknown(
              data['school_year']!, _schoolYearMeta));
    } else if (isInserting) {
      context.missing(_schoolYearMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchoolClass map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchoolClass(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      schoolYear: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_year'])!,
    );
  }

  @override
  $ClassesTable createAlias(String alias) {
    return $ClassesTable(attachedDatabase, alias);
  }
}

class SchoolClass extends DataClass implements Insertable<SchoolClass> {
  final int id;
  final String name;
  final String schoolYear;
  const SchoolClass(
      {required this.id, required this.name, required this.schoolYear});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['school_year'] = Variable<String>(schoolYear);
    return map;
  }

  ClassesCompanion toCompanion(bool nullToAbsent) {
    return ClassesCompanion(
      id: Value(id),
      name: Value(name),
      schoolYear: Value(schoolYear),
    );
  }

  factory SchoolClass.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchoolClass(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      schoolYear: serializer.fromJson<String>(json['schoolYear']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'schoolYear': serializer.toJson<String>(schoolYear),
    };
  }

  SchoolClass copyWith({int? id, String? name, String? schoolYear}) =>
      SchoolClass(
        id: id ?? this.id,
        name: name ?? this.name,
        schoolYear: schoolYear ?? this.schoolYear,
      );
  @override
  String toString() {
    return (StringBuffer('SchoolClass(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('schoolYear: $schoolYear')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, schoolYear);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchoolClass &&
          other.id == this.id &&
          other.name == this.name &&
          other.schoolYear == this.schoolYear);
}

class ClassesCompanion extends UpdateCompanion<SchoolClass> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> schoolYear;
  const ClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.schoolYear = const Value.absent(),
  });
  ClassesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String schoolYear,
  })  : name = Value(name),
        schoolYear = Value(schoolYear);
  static Insertable<SchoolClass> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? schoolYear,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (schoolYear != null) 'school_year': schoolYear,
    });
  }

  ClassesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String>? schoolYear}) {
    return ClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolYear: schoolYear ?? this.schoolYear,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (schoolYear.present) {
      map['school_year'] = Variable<String>(schoolYear.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('schoolYear: $schoolYear')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students with TableInfo<$StudentsTable, Student> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
      'class_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES classes (id)'));
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, classId, firstName, lastName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(Insertable<Student> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Student map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Student(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_id'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class Student extends DataClass implements Insertable<Student> {
  final int id;
  final int classId;
  final String firstName;
  final String lastName;
  const Student(
      {required this.id,
      required this.classId,
      required this.firstName,
      required this.lastName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['class_id'] = Variable<int>(classId);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      classId: Value(classId),
      firstName: Value(firstName),
      lastName: Value(lastName),
    );
  }

  factory Student.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Student(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int>(json['classId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int>(classId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
    };
  }

  Student copyWith(
          {int? id, int? classId, String? firstName, String? lastName}) =>
      Student(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
      );
  @override
  String toString() {
    return (StringBuffer('Student(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, classId, firstName, lastName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Student &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName);
}

class StudentsCompanion extends UpdateCompanion<Student> {
  final Value<int> id;
  final Value<int> classId;
  final Value<String> firstName;
  final Value<String> lastName;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
  });
  StudentsCompanion.insert({
    this.id = const Value.absent(),
    required int classId,
    required String firstName,
    required String lastName,
  })  : classId = Value(classId),
        firstName = Value(firstName),
        lastName = Value(lastName);
  static Insertable<Student> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<String>? firstName,
    Expression<String>? lastName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });
  }

  StudentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? classId,
      Value<String>? firstName,
      Value<String>? lastName}) {
    return StudentsCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<Subject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final int id;
  final String name;
  const Subject({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Subject copyWith({int? id, String? name}) => Subject(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject && other.id == this.id && other.name == this.name);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<String> name;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  SubjectsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ClassSubjectsTable extends ClassSubjects
    with TableInfo<$ClassSubjectsTable, ClassSubject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassSubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
      'class_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES classes (id)'));
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  @override
  List<GeneratedColumn> get $columns => [classId, subjectId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_subjects';
  @override
  VerificationContext validateIntegrity(Insertable<ClassSubject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {classId, subjectId};
  @override
  ClassSubject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassSubject(
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subject_id'])!,
    );
  }

  @override
  $ClassSubjectsTable createAlias(String alias) {
    return $ClassSubjectsTable(attachedDatabase, alias);
  }
}

class ClassSubject extends DataClass implements Insertable<ClassSubject> {
  final int classId;
  final int subjectId;
  const ClassSubject({required this.classId, required this.subjectId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['class_id'] = Variable<int>(classId);
    map['subject_id'] = Variable<int>(subjectId);
    return map;
  }

  ClassSubjectsCompanion toCompanion(bool nullToAbsent) {
    return ClassSubjectsCompanion(
      classId: Value(classId),
      subjectId: Value(subjectId),
    );
  }

  factory ClassSubject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassSubject(
      classId: serializer.fromJson<int>(json['classId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'classId': serializer.toJson<int>(classId),
      'subjectId': serializer.toJson<int>(subjectId),
    };
  }

  ClassSubject copyWith({int? classId, int? subjectId}) => ClassSubject(
        classId: classId ?? this.classId,
        subjectId: subjectId ?? this.subjectId,
      );
  @override
  String toString() {
    return (StringBuffer('ClassSubject(')
          ..write('classId: $classId, ')
          ..write('subjectId: $subjectId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(classId, subjectId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassSubject &&
          other.classId == this.classId &&
          other.subjectId == this.subjectId);
}

class ClassSubjectsCompanion extends UpdateCompanion<ClassSubject> {
  final Value<int> classId;
  final Value<int> subjectId;
  final Value<int> rowid;
  const ClassSubjectsCompanion({
    this.classId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassSubjectsCompanion.insert({
    required int classId,
    required int subjectId,
    this.rowid = const Value.absent(),
  })  : classId = Value(classId),
        subjectId = Value(subjectId);
  static Insertable<ClassSubject> custom({
    Expression<int>? classId,
    Expression<int>? subjectId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (classId != null) 'class_id': classId,
      if (subjectId != null) 'subject_id': subjectId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassSubjectsCompanion copyWith(
      {Value<int>? classId, Value<int>? subjectId, Value<int>? rowid}) {
    return ClassSubjectsCompanion(
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassSubjectsCompanion(')
          ..write('classId: $classId, ')
          ..write('subjectId: $subjectId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GradeCategoriesTable extends GradeCategories
    with TableInfo<$GradeCategoriesTable, GradeCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradeCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _weightPercentMeta =
      const VerificationMeta('weightPercent');
  @override
  late final GeneratedColumn<double> weightPercent = GeneratedColumn<double>(
      'weight_percent', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#2196F3'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('school'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, weightPercent, colorHex, icon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_categories';
  @override
  VerificationContext validateIntegrity(Insertable<GradeCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('weight_percent')) {
      context.handle(
          _weightPercentMeta,
          weightPercent.isAcceptableOrUnknown(
              data['weight_percent']!, _weightPercentMeta));
    } else if (isInserting) {
      context.missing(_weightPercentMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradeCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      weightPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_percent'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
    );
  }

  @override
  $GradeCategoriesTable createAlias(String alias) {
    return $GradeCategoriesTable(attachedDatabase, alias);
  }
}

class GradeCategory extends DataClass implements Insertable<GradeCategory> {
  final int id;
  final String name;
  final double weightPercent;
  final String colorHex;
  final String icon;
  const GradeCategory(
      {required this.id,
      required this.name,
      required this.weightPercent,
      required this.colorHex,
      required this.icon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['weight_percent'] = Variable<double>(weightPercent);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon'] = Variable<String>(icon);
    return map;
  }

  GradeCategoriesCompanion toCompanion(bool nullToAbsent) {
    return GradeCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      weightPercent: Value(weightPercent),
      colorHex: Value(colorHex),
      icon: Value(icon),
    );
  }

  factory GradeCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      weightPercent: serializer.fromJson<double>(json['weightPercent']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'weightPercent': serializer.toJson<double>(weightPercent),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String>(icon),
    };
  }

  GradeCategory copyWith(
          {int? id,
          String? name,
          double? weightPercent,
          String? colorHex,
          String? icon}) =>
      GradeCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        weightPercent: weightPercent ?? this.weightPercent,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
      );
  @override
  String toString() {
    return (StringBuffer('GradeCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('weightPercent: $weightPercent, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, weightPercent, colorHex, icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.weightPercent == this.weightPercent &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon);
}

class GradeCategoriesCompanion extends UpdateCompanion<GradeCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> weightPercent;
  final Value<String> colorHex;
  final Value<String> icon;
  const GradeCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.weightPercent = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
  });
  GradeCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double weightPercent,
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
  })  : name = Value(name),
        weightPercent = Value(weightPercent);
  static Insertable<GradeCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? weightPercent,
    Expression<String>? colorHex,
    Expression<String>? icon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (weightPercent != null) 'weight_percent': weightPercent,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
    });
  }

  GradeCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? weightPercent,
      Value<String>? colorHex,
      Value<String>? icon}) {
    return GradeCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      weightPercent: weightPercent ?? this.weightPercent,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (weightPercent.present) {
      map['weight_percent'] = Variable<double>(weightPercent.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('weightPercent: $weightPercent, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }
}

class $GradesTable extends Grades with TableInfo<$GradesTable, Grade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
      'student_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES students (id)'));
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES grade_categories (id)'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _semesterMeta =
      const VerificationMeta('semester');
  @override
  late final GeneratedColumn<int> semester = GeneratedColumn<int>(
      'semester', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _commentMeta =
      const VerificationMeta('comment');
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
      'comment', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, studentId, subjectId, categoryId, value, semester, date, comment];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades';
  @override
  VerificationContext validateIntegrity(Insertable<Grade> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta,
          semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(_commentMeta,
          comment.isAcceptableOrUnknown(data['comment']!, _commentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grade(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}student_id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subject_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      semester: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}semester'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      comment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comment'])!,
    );
  }

  @override
  $GradesTable createAlias(String alias) {
    return $GradesTable(attachedDatabase, alias);
  }
}

class Grade extends DataClass implements Insertable<Grade> {
  final int id;
  final int studentId;
  final int subjectId;
  final int categoryId;
  final double value;
  final int semester;
  final DateTime date;
  final String comment;
  const Grade(
      {required this.id,
      required this.studentId,
      required this.subjectId,
      required this.categoryId,
      required this.value,
      required this.semester,
      required this.date,
      required this.comment});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['subject_id'] = Variable<int>(subjectId);
    map['category_id'] = Variable<int>(categoryId);
    map['value'] = Variable<double>(value);
    map['semester'] = Variable<int>(semester);
    map['date'] = Variable<DateTime>(date);
    map['comment'] = Variable<String>(comment);
    return map;
  }

  GradesCompanion toCompanion(bool nullToAbsent) {
    return GradesCompanion(
      id: Value(id),
      studentId: Value(studentId),
      subjectId: Value(subjectId),
      categoryId: Value(categoryId),
      value: Value(value),
      semester: Value(semester),
      date: Value(date),
      comment: Value(comment),
    );
  }

  factory Grade.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grade(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      value: serializer.fromJson<double>(json['value']),
      semester: serializer.fromJson<int>(json['semester']),
      date: serializer.fromJson<DateTime>(json['date']),
      comment: serializer.fromJson<String>(json['comment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'subjectId': serializer.toJson<int>(subjectId),
      'categoryId': serializer.toJson<int>(categoryId),
      'value': serializer.toJson<double>(value),
      'semester': serializer.toJson<int>(semester),
      'date': serializer.toJson<DateTime>(date),
      'comment': serializer.toJson<String>(comment),
    };
  }

  Grade copyWith(
          {int? id,
          int? studentId,
          int? subjectId,
          int? categoryId,
          double? value,
          int? semester,
          DateTime? date,
          String? comment}) =>
      Grade(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        subjectId: subjectId ?? this.subjectId,
        categoryId: categoryId ?? this.categoryId,
        value: value ?? this.value,
        semester: semester ?? this.semester,
        date: date ?? this.date,
        comment: comment ?? this.comment,
      );
  @override
  String toString() {
    return (StringBuffer('Grade(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('value: $value, ')
          ..write('semester: $semester, ')
          ..write('date: $date, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, studentId, subjectId, categoryId, value, semester, date, comment);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grade &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.subjectId == this.subjectId &&
          other.categoryId == this.categoryId &&
          other.value == this.value &&
          other.semester == this.semester &&
          other.date == this.date &&
          other.comment == this.comment);
}

class GradesCompanion extends UpdateCompanion<Grade> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<int> subjectId;
  final Value<int> categoryId;
  final Value<double> value;
  final Value<int> semester;
  final Value<DateTime> date;
  final Value<String> comment;
  const GradesCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.value = const Value.absent(),
    this.semester = const Value.absent(),
    this.date = const Value.absent(),
    this.comment = const Value.absent(),
  });
  GradesCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required int subjectId,
    required int categoryId,
    required double value,
    required int semester,
    required DateTime date,
    this.comment = const Value.absent(),
  })  : studentId = Value(studentId),
        subjectId = Value(subjectId),
        categoryId = Value(categoryId),
        value = Value(value),
        semester = Value(semester),
        date = Value(date);
  static Insertable<Grade> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<int>? subjectId,
    Expression<int>? categoryId,
    Expression<double>? value,
    Expression<int>? semester,
    Expression<DateTime>? date,
    Expression<String>? comment,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (subjectId != null) 'subject_id': subjectId,
      if (categoryId != null) 'category_id': categoryId,
      if (value != null) 'value': value,
      if (semester != null) 'semester': semester,
      if (date != null) 'date': date,
      if (comment != null) 'comment': comment,
    });
  }

  GradesCompanion copyWith(
      {Value<int>? id,
      Value<int>? studentId,
      Value<int>? subjectId,
      Value<int>? categoryId,
      Value<double>? value,
      Value<int>? semester,
      Value<DateTime>? date,
      Value<String>? comment}) {
    return GradesCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      categoryId: categoryId ?? this.categoryId,
      value: value ?? this.value,
      semester: semester ?? this.semester,
      date: date ?? this.date,
      comment: comment ?? this.comment,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (semester.present) {
      map['semester'] = Variable<int>(semester.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('value: $value, ')
          ..write('semester: $semester, ')
          ..write('date: $date, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }
}

class $SemesterSettingsTable extends SemesterSettings
    with TableInfo<$SemesterSettingsTable, SemesterSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemesterSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
      'subject_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  static const VerificationMeta _firstHalfWeightMeta =
      const VerificationMeta('firstHalfWeight');
  @override
  late final GeneratedColumn<double> firstHalfWeight = GeneratedColumn<double>(
      'first_half_weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(50.0));
  static const VerificationMeta _secondHalfWeightMeta =
      const VerificationMeta('secondHalfWeight');
  @override
  late final GeneratedColumn<double> secondHalfWeight = GeneratedColumn<double>(
      'second_half_weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(50.0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, subjectId, firstHalfWeight, secondHalfWeight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semester_settings';
  @override
  VerificationContext validateIntegrity(Insertable<SemesterSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    }
    if (data.containsKey('first_half_weight')) {
      context.handle(
          _firstHalfWeightMeta,
          firstHalfWeight.isAcceptableOrUnknown(
              data['first_half_weight']!, _firstHalfWeightMeta));
    }
    if (data.containsKey('second_half_weight')) {
      context.handle(
          _secondHalfWeightMeta,
          secondHalfWeight.isAcceptableOrUnknown(
              data['second_half_weight']!, _secondHalfWeightMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemesterSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subject_id']),
      firstHalfWeight: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}first_half_weight'])!,
      secondHalfWeight: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}second_half_weight'])!,
    );
  }

  @override
  $SemesterSettingsTable createAlias(String alias) {
    return $SemesterSettingsTable(attachedDatabase, alias);
  }
}

class SemesterSetting extends DataClass implements Insertable<SemesterSetting> {
  final int id;
  final int? subjectId;
  final double firstHalfWeight;
  final double secondHalfWeight;
  const SemesterSetting(
      {required this.id,
      this.subjectId,
      required this.firstHalfWeight,
      required this.secondHalfWeight});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<int>(subjectId);
    }
    map['first_half_weight'] = Variable<double>(firstHalfWeight);
    map['second_half_weight'] = Variable<double>(secondHalfWeight);
    return map;
  }

  SemesterSettingsCompanion toCompanion(bool nullToAbsent) {
    return SemesterSettingsCompanion(
      id: Value(id),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      firstHalfWeight: Value(firstHalfWeight),
      secondHalfWeight: Value(secondHalfWeight),
    );
  }

  factory SemesterSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterSetting(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int?>(json['subjectId']),
      firstHalfWeight: serializer.fromJson<double>(json['firstHalfWeight']),
      secondHalfWeight: serializer.fromJson<double>(json['secondHalfWeight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int?>(subjectId),
      'firstHalfWeight': serializer.toJson<double>(firstHalfWeight),
      'secondHalfWeight': serializer.toJson<double>(secondHalfWeight),
    };
  }

  SemesterSetting copyWith(
          {int? id,
          Value<int?> subjectId = const Value.absent(),
          double? firstHalfWeight,
          double? secondHalfWeight}) =>
      SemesterSetting(
        id: id ?? this.id,
        subjectId: subjectId.present ? subjectId.value : this.subjectId,
        firstHalfWeight: firstHalfWeight ?? this.firstHalfWeight,
        secondHalfWeight: secondHalfWeight ?? this.secondHalfWeight,
      );
  @override
  String toString() {
    return (StringBuffer('SemesterSetting(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('firstHalfWeight: $firstHalfWeight, ')
          ..write('secondHalfWeight: $secondHalfWeight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subjectId, firstHalfWeight, secondHalfWeight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterSetting &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.firstHalfWeight == this.firstHalfWeight &&
          other.secondHalfWeight == this.secondHalfWeight);
}

class SemesterSettingsCompanion extends UpdateCompanion<SemesterSetting> {
  final Value<int> id;
  final Value<int?> subjectId;
  final Value<double> firstHalfWeight;
  final Value<double> secondHalfWeight;
  const SemesterSettingsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.firstHalfWeight = const Value.absent(),
    this.secondHalfWeight = const Value.absent(),
  });
  SemesterSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.firstHalfWeight = const Value.absent(),
    this.secondHalfWeight = const Value.absent(),
  });
  static Insertable<SemesterSetting> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<double>? firstHalfWeight,
    Expression<double>? secondHalfWeight,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (firstHalfWeight != null) 'first_half_weight': firstHalfWeight,
      if (secondHalfWeight != null) 'second_half_weight': secondHalfWeight,
    });
  }

  SemesterSettingsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? subjectId,
      Value<double>? firstHalfWeight,
      Value<double>? secondHalfWeight}) {
    return SemesterSettingsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      firstHalfWeight: firstHalfWeight ?? this.firstHalfWeight,
      secondHalfWeight: secondHalfWeight ?? this.secondHalfWeight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (firstHalfWeight.present) {
      map['first_half_weight'] = Variable<double>(firstHalfWeight.value);
    }
    if (secondHalfWeight.present) {
      map['second_half_weight'] = Variable<double>(secondHalfWeight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemesterSettingsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('firstHalfWeight: $firstHalfWeight, ')
          ..write('secondHalfWeight: $secondHalfWeight')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $ClassesTable classes = $ClassesTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $ClassSubjectsTable classSubjects = $ClassSubjectsTable(this);
  late final $GradeCategoriesTable gradeCategories =
      $GradeCategoriesTable(this);
  late final $GradesTable grades = $GradesTable(this);
  late final $SemesterSettingsTable semesterSettings =
      $SemesterSettingsTable(this);
  late final ClassesDao classesDao = ClassesDao(this as AppDatabase);
  late final StudentsDao studentsDao = StudentsDao(this as AppDatabase);
  late final SubjectsDao subjectsDao = SubjectsDao(this as AppDatabase);
  late final GradesDao gradesDao = GradesDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        classes,
        students,
        subjects,
        classSubjects,
        gradeCategories,
        grades,
        semesterSettings
      ];
}
