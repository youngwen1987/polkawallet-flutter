// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingStore _$StakingStoreFromJson(Map<String, dynamic> json) {
  return StakingStore(
    json['description'] as String,
  )..done = json['done'] as bool;
}

Map<String, dynamic> _$StakingStoreToJson(StakingStore instance) =>
    <String, dynamic>{
      'description': instance.description,
      'done': instance.done,
    };

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$StakingStore on _StakingStore, Store {
  final _$descriptionAtom = Atom(name: '_StakingStore.description');

  @override
  String get description {
    _$descriptionAtom.context.enforceReadPolicy(_$descriptionAtom);
    _$descriptionAtom.reportObserved();
    return super.description;
  }

  @override
  set description(String value) {
    _$descriptionAtom.context.conditionallyRunInAction(() {
      super.description = value;
      _$descriptionAtom.reportChanged();
    }, _$descriptionAtom, name: '${_$descriptionAtom.name}_set');
  }

  final _$doneAtom = Atom(name: '_StakingStore.done');

  @override
  bool get done {
    _$doneAtom.context.enforceReadPolicy(_$doneAtom);
    _$doneAtom.reportObserved();
    return super.done;
  }

  @override
  set done(bool value) {
    _$doneAtom.context.conditionallyRunInAction(() {
      super.done = value;
      _$doneAtom.reportChanged();
    }, _$doneAtom, name: '${_$doneAtom.name}_set');
  }
}
