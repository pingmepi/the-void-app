// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gem_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GemNote _$GemNoteFromJson(Map<String, dynamic> json) {
  return _GemNote.fromJson(json);
}

/// @nodoc
mixin _$GemNote {
  /// Unique identifier for the gem
  String get id => throw _privateConstructorUsedError;

  /// The transcribed text content
  String get transcript => throw _privateConstructorUsedError;

  /// When the gem was saved
  DateTime get savedAt => throw _privateConstructorUsedError;

  /// Optional title (user can add later)
  String? get title => throw _privateConstructorUsedError;

  /// Duration of the original recording in seconds
  int? get durationSeconds => throw _privateConstructorUsedError;

  /// Tags for organization (optional feature)
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this GemNote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GemNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GemNoteCopyWith<GemNote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GemNoteCopyWith<$Res> {
  factory $GemNoteCopyWith(GemNote value, $Res Function(GemNote) then) =
      _$GemNoteCopyWithImpl<$Res, GemNote>;
  @useResult
  $Res call({
    String id,
    String transcript,
    DateTime savedAt,
    String? title,
    int? durationSeconds,
    List<String> tags,
  });
}

/// @nodoc
class _$GemNoteCopyWithImpl<$Res, $Val extends GemNote>
    implements $GemNoteCopyWith<$Res> {
  _$GemNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GemNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transcript = null,
    Object? savedAt = null,
    Object? title = freezed,
    Object? durationSeconds = freezed,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            transcript: null == transcript
                ? _value.transcript
                : transcript // ignore: cast_nullable_to_non_nullable
                      as String,
            savedAt: null == savedAt
                ? _value.savedAt
                : savedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GemNoteImplCopyWith<$Res> implements $GemNoteCopyWith<$Res> {
  factory _$$GemNoteImplCopyWith(
    _$GemNoteImpl value,
    $Res Function(_$GemNoteImpl) then,
  ) = __$$GemNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String transcript,
    DateTime savedAt,
    String? title,
    int? durationSeconds,
    List<String> tags,
  });
}

/// @nodoc
class __$$GemNoteImplCopyWithImpl<$Res>
    extends _$GemNoteCopyWithImpl<$Res, _$GemNoteImpl>
    implements _$$GemNoteImplCopyWith<$Res> {
  __$$GemNoteImplCopyWithImpl(
    _$GemNoteImpl _value,
    $Res Function(_$GemNoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GemNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transcript = null,
    Object? savedAt = null,
    Object? title = freezed,
    Object? durationSeconds = freezed,
    Object? tags = null,
  }) {
    return _then(
      _$GemNoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        transcript: null == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as String,
        savedAt: null == savedAt
            ? _value.savedAt
            : savedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GemNoteImpl implements _GemNote {
  const _$GemNoteImpl({
    required this.id,
    required this.transcript,
    required this.savedAt,
    this.title,
    this.durationSeconds,
    final List<String> tags = const [],
  }) : _tags = tags;

  factory _$GemNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$GemNoteImplFromJson(json);

  /// Unique identifier for the gem
  @override
  final String id;

  /// The transcribed text content
  @override
  final String transcript;

  /// When the gem was saved
  @override
  final DateTime savedAt;

  /// Optional title (user can add later)
  @override
  final String? title;

  /// Duration of the original recording in seconds
  @override
  final int? durationSeconds;

  /// Tags for organization (optional feature)
  final List<String> _tags;

  /// Tags for organization (optional feature)
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'GemNote(id: $id, transcript: $transcript, savedAt: $savedAt, title: $title, durationSeconds: $durationSeconds, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GemNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    transcript,
    savedAt,
    title,
    durationSeconds,
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of GemNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GemNoteImplCopyWith<_$GemNoteImpl> get copyWith =>
      __$$GemNoteImplCopyWithImpl<_$GemNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GemNoteImplToJson(this);
  }
}

abstract class _GemNote implements GemNote {
  const factory _GemNote({
    required final String id,
    required final String transcript,
    required final DateTime savedAt,
    final String? title,
    final int? durationSeconds,
    final List<String> tags,
  }) = _$GemNoteImpl;

  factory _GemNote.fromJson(Map<String, dynamic> json) = _$GemNoteImpl.fromJson;

  /// Unique identifier for the gem
  @override
  String get id;

  /// The transcribed text content
  @override
  String get transcript;

  /// When the gem was saved
  @override
  DateTime get savedAt;

  /// Optional title (user can add later)
  @override
  String? get title;

  /// Duration of the original recording in seconds
  @override
  int? get durationSeconds;

  /// Tags for organization (optional feature)
  @override
  List<String> get tags;

  /// Create a copy of GemNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GemNoteImplCopyWith<_$GemNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
