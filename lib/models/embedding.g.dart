// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEmbeddingCollection on Isar {
  IsarCollection<Embedding> get embeddings => this.collection();
}

const EmbeddingSchema = CollectionSchema(
  name: r'Embedding',
  id: -8064100183150254587,
  properties: {
    r'embedding': PropertySchema(
      id: 0,
      name: r'embedding',
      type: IsarType.doubleList,
    ),
    r'fileID': PropertySchema(
      id: 1,
      name: r'fileID',
      type: IsarType.long,
    ),
    r'model': PropertySchema(
      id: 2,
      name: r'model',
      type: IsarType.byte,
      enumMap: _EmbeddingmodelEnumValueMap,
    ),
    r'updationTime': PropertySchema(
      id: 3,
      name: r'updationTime',
      type: IsarType.long,
    )
  },
  estimateSize: _embeddingEstimateSize,
  serialize: _embeddingSerialize,
  deserialize: _embeddingDeserialize,
  deserializeProp: _embeddingDeserializeProp,
  idName: r'id',
  indexes: {
    r'unique_file_model_embedding': IndexSchema(
      id: 6248303800853228628,
      name: r'unique_file_model_embedding',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'model',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'fileID',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _embeddingGetId,
  getLinks: _embeddingGetLinks,
  attach: _embeddingAttach,
  version: '3.1.0+1',
);

int _embeddingEstimateSize(
  Embedding object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.embedding.length * 8;
  return bytesCount;
}

void _embeddingSerialize(
  Embedding object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDoubleList(offsets[0], object.embedding);
  writer.writeLong(offsets[1], object.fileID);
  writer.writeByte(offsets[2], object.model.index);
  writer.writeLong(offsets[3], object.updationTime);
}

Embedding _embeddingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Embedding(
    embedding: reader.readDoubleList(offsets[0]) ?? [],
    fileID: reader.readLong(offsets[1]),
    model: _EmbeddingmodelValueEnumMap[reader.readByteOrNull(offsets[2])] ??
        Model.onnxClip,
    updationTime: reader.readLongOrNull(offsets[3]),
  );
  object.id = id;
  return object;
}

P _embeddingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (_EmbeddingmodelValueEnumMap[reader.readByteOrNull(offset)] ??
          Model.onnxClip) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _EmbeddingmodelEnumValueMap = {
  'onnxClip': 0,
  'ggmlClip': 1,
};
const _EmbeddingmodelValueEnumMap = {
  0: Model.onnxClip,
  1: Model.ggmlClip,
};

Id _embeddingGetId(Embedding object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _embeddingGetLinks(Embedding object) {
  return [];
}

void _embeddingAttach(IsarCollection<dynamic> col, Id id, Embedding object) {
  object.id = id;
}

extension EmbeddingByIndex on IsarCollection<Embedding> {
  Future<Embedding?> getByModelFileID(Model model, int fileID) {
    return getByIndex(r'unique_file_model_embedding', [model, fileID]);
  }

  Embedding? getByModelFileIDSync(Model model, int fileID) {
    return getByIndexSync(r'unique_file_model_embedding', [model, fileID]);
  }

  Future<bool> deleteByModelFileID(Model model, int fileID) {
    return deleteByIndex(r'unique_file_model_embedding', [model, fileID]);
  }

  bool deleteByModelFileIDSync(Model model, int fileID) {
    return deleteByIndexSync(r'unique_file_model_embedding', [model, fileID]);
  }

  Future<List<Embedding?>> getAllByModelFileID(
      List<Model> modelValues, List<int> fileIDValues) {
    final len = modelValues.length;
    assert(fileIDValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([modelValues[i], fileIDValues[i]]);
    }

    return getAllByIndex(r'unique_file_model_embedding', values);
  }

  List<Embedding?> getAllByModelFileIDSync(
      List<Model> modelValues, List<int> fileIDValues) {
    final len = modelValues.length;
    assert(fileIDValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([modelValues[i], fileIDValues[i]]);
    }

    return getAllByIndexSync(r'unique_file_model_embedding', values);
  }

  Future<int> deleteAllByModelFileID(
      List<Model> modelValues, List<int> fileIDValues) {
    final len = modelValues.length;
    assert(fileIDValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([modelValues[i], fileIDValues[i]]);
    }

    return deleteAllByIndex(r'unique_file_model_embedding', values);
  }

  int deleteAllByModelFileIDSync(
      List<Model> modelValues, List<int> fileIDValues) {
    final len = modelValues.length;
    assert(fileIDValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([modelValues[i], fileIDValues[i]]);
    }

    return deleteAllByIndexSync(r'unique_file_model_embedding', values);
  }

  Future<Id> putByModelFileID(Embedding object) {
    return putByIndex(r'unique_file_model_embedding', object);
  }

  Id putByModelFileIDSync(Embedding object, {bool saveLinks = true}) {
    return putByIndexSync(r'unique_file_model_embedding', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByModelFileID(List<Embedding> objects) {
    return putAllByIndex(r'unique_file_model_embedding', objects);
  }

  List<Id> putAllByModelFileIDSync(List<Embedding> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'unique_file_model_embedding', objects,
        saveLinks: saveLinks);
  }
}

extension EmbeddingQueryWhereSort
    on QueryBuilder<Embedding, Embedding, QWhere> {
  QueryBuilder<Embedding, Embedding, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhere> anyModelFileID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'unique_file_model_embedding'),
      );
    });
  }
}

extension EmbeddingQueryWhere
    on QueryBuilder<Embedding, Embedding, QWhereClause> {
  QueryBuilder<Embedding, Embedding, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> modelEqualToAnyFileID(
      Model model) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unique_file_model_embedding',
        value: [model],
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelNotEqualToAnyFileID(Model model) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [],
              upper: [model],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [],
              upper: [model],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelGreaterThanAnyFileID(
    Model model, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [model],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> modelLessThanAnyFileID(
    Model model, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [],
        upper: [model],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> modelBetweenAnyFileID(
    Model lowerModel,
    Model upperModel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [lowerModel],
        includeLower: includeLower,
        upper: [upperModel],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause> modelFileIDEqualTo(
      Model model, int fileID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unique_file_model_embedding',
        value: [model, fileID],
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelEqualToFileIDNotEqualTo(Model model, int fileID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model],
              upper: [model, fileID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model, fileID],
              includeLower: false,
              upper: [model],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model, fileID],
              includeLower: false,
              upper: [model],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unique_file_model_embedding',
              lower: [model],
              upper: [model, fileID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelEqualToFileIDGreaterThan(
    Model model,
    int fileID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [model, fileID],
        includeLower: include,
        upper: [model],
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelEqualToFileIDLessThan(
    Model model,
    int fileID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [model],
        upper: [model, fileID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterWhereClause>
      modelEqualToFileIDBetween(
    Model model,
    int lowerFileID,
    int upperFileID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unique_file_model_embedding',
        lower: [model, lowerFileID],
        includeLower: includeLower,
        upper: [model, upperFileID],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EmbeddingQueryFilter
    on QueryBuilder<Embedding, Embedding, QFilterCondition> {
  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'embedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'embedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'embedding',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> embeddingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      embeddingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> fileIDEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileID',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> fileIDGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileID',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> fileIDLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileID',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> fileIDBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> modelEqualTo(
      Model value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'model',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> modelGreaterThan(
    Model value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'model',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> modelLessThan(
    Model value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'model',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> modelBetween(
    Model lower,
    Model upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'model',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      updationTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updationTime',
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      updationTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updationTime',
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> updationTimeEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updationTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      updationTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updationTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition>
      updationTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updationTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterFilterCondition> updationTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updationTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EmbeddingQueryObject
    on QueryBuilder<Embedding, Embedding, QFilterCondition> {}

extension EmbeddingQueryLinks
    on QueryBuilder<Embedding, Embedding, QFilterCondition> {}

extension EmbeddingQuerySortBy on QueryBuilder<Embedding, Embedding, QSortBy> {
  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByFileID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileID', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByFileIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileID', Sort.desc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> sortByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension EmbeddingQuerySortThenBy
    on QueryBuilder<Embedding, Embedding, QSortThenBy> {
  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByFileID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileID', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByFileIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileID', Sort.desc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<Embedding, Embedding, QAfterSortBy> thenByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension EmbeddingQueryWhereDistinct
    on QueryBuilder<Embedding, Embedding, QDistinct> {
  QueryBuilder<Embedding, Embedding, QDistinct> distinctByEmbedding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embedding');
    });
  }

  QueryBuilder<Embedding, Embedding, QDistinct> distinctByFileID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileID');
    });
  }

  QueryBuilder<Embedding, Embedding, QDistinct> distinctByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'model');
    });
  }

  QueryBuilder<Embedding, Embedding, QDistinct> distinctByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updationTime');
    });
  }
}

extension EmbeddingQueryProperty
    on QueryBuilder<Embedding, Embedding, QQueryProperty> {
  QueryBuilder<Embedding, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Embedding, List<double>, QQueryOperations> embeddingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embedding');
    });
  }

  QueryBuilder<Embedding, int, QQueryOperations> fileIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileID');
    });
  }

  QueryBuilder<Embedding, Model, QQueryOperations> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'model');
    });
  }

  QueryBuilder<Embedding, int?, QQueryOperations> updationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updationTime');
    });
  }
}
