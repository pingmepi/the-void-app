// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gem_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GemNoteImpl _$$GemNoteImplFromJson(Map<String, dynamic> json) =>
    _$GemNoteImpl(
      id: json['id'] as String,
      transcript: json['transcript'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      title: json['title'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$$GemNoteImplToJson(_$GemNoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transcript': instance.transcript,
      'savedAt': instance.savedAt.toIso8601String(),
      'title': instance.title,
      'durationSeconds': instance.durationSeconds,
      'tags': instance.tags,
    };
