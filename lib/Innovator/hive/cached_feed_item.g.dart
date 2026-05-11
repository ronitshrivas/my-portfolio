// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_feed_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedFeedItemAdapter extends TypeAdapter<CachedFeedItem> {
  @override
  final int typeId = 0;

  @override
  CachedFeedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedFeedItem(
      id: fields[0] as String,
      authorId: fields[1] as String,
      authorName: fields[2] as String,
      authorAvatar: fields[3] as String,
      status: fields[4] as String,
      type: fields[5] as String,
      mediaUrls: (fields[6] as List).cast<String>(),
      likes: fields[7] as int,
      isLiked: fields[8] as bool,
      comments: fields[9] as int,
      isFollowed: fields[10] as bool,
      createdAt: fields[11] as String,
      isReel: fields[12] as bool,
      sharedPostId: fields[13] as String?,
      thumbnailUrl: fields[14] as String?,
      currentUserReaction: fields[15] as String?,
      savedAt: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedFeedItem obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.authorName)
      ..writeByte(3)
      ..write(obj.authorAvatar)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.mediaUrls)
      ..writeByte(7)
      ..write(obj.likes)
      ..writeByte(8)
      ..write(obj.isLiked)
      ..writeByte(9)
      ..write(obj.comments)
      ..writeByte(10)
      ..write(obj.isFollowed)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.isReel)
      ..writeByte(13)
      ..write(obj.sharedPostId)
      ..writeByte(14)
      ..write(obj.thumbnailUrl)
      ..writeByte(15)
      ..write(obj.currentUserReaction)
      ..writeByte(16)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFeedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
