import 'package:dogplatform/core/realtime/realtime_client.dart';
import 'package:dogplatform/features/social/application/providers.dart';
import 'package:dogplatform/features/social/data/dto/social_dtos.dart';
import 'package:dogplatform/features/social/domain/entities/social.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Social contract parsing', () {
    test('maps every exact SocialStatus value', () {
      expect(SocialStatus.fromWire('None'), SocialStatus.none);
      expect(SocialStatus.fromWire('Friends'), SocialStatus.friends);
      expect(SocialStatus.fromWire('PendingSent'), SocialStatus.pendingSent);
      expect(
        SocialStatus.fromWire('PendingReceived'),
        SocialStatus.pendingReceived,
      );
      expect(() => SocialStatus.fromWire('unknown'), throwsFormatException);
    });

    test('parses numbered pagination without deriving hasNextPage', () {
      final page = numberedPage<SocialUser>({
        'items': [
          {
            'userId': 'user-1',
            'displayName': 'Ada',
            'profilePhotoUrl': null,
            'socialStatus': 'Friends',
          },
        ],
        'pageNumber': 2,
        'pageSize': 20,
        'totalItems': 41,
        'totalPages': 3,
        'hasNextPage': true,
      }, (json) => SocialUserDto.fromJson(json).toDomain());

      expect(page.pageNumber, 2);
      expect(page.totalPages, 3);
      expect(page.hasNextPage, isTrue);
      expect(page.items.single.socialStatus, SocialStatus.friends);
    });

    test('parses the exact before/beforeId message cursor', () {
      final page = messagePage({
        'items': [_messageJson('message-1')],
        'nextCursor': {
          'before': '2026-10-10T18:58:13.504723Z',
          'beforeId': 'message-1',
        },
        'hasMore': true,
      });

      expect(page.nextCursor?.beforeId, 'message-1');
      expect(page.nextCursor?.before.isUtc, isTrue);
      expect(page.hasMore, isTrue);
    });

    test('parses friend and chat realtime envelopes without magic payloads', () {
      final event = RealtimeEvent.tryParse(
        '{"event":"chat.message.received","data":${_messageJsonString('message-1')}}',
      );
      expect(event?.name, 'chat.message.received');
      expect(ChatMessageDto.fromJson(event!.data).toDomain().id, 'message-1');
      expect(RealtimeEvent.tryParse('{"event":"unknown"}'), isNull);
    });
  });

  test('message reconciliation deduplicates POST, REST and realtime by id', () {
    final first = ChatMessageDto.fromJson(_messageJson('same-id')).toDomain();
    final duplicate = ChatMessageDto.fromJson(
      _messageJson('same-id'),
    ).toDomain();
    final olderJson = _messageJson('older')
      ..['createdAtUtc'] = '2026-10-10T17:58:13.504723Z';
    final older = ChatMessageDto.fromJson(olderJson).toDomain();

    final merged = mergeMessages([first], [duplicate, older]);

    expect(merged.map((item) => item.id), ['same-id', 'older']);
  });
}

Map<String, dynamic> _messageJson(String id) => {
  'id': id,
  'conversationId': 'conversation-1',
  'senderUserId': 'user-1',
  'content': 'Hola',
  'createdAtUtc': '2026-10-10T18:58:13.504723Z',
  'editedAtUtc': null,
  'deletedAtUtc': null,
};

String _messageJsonString(String id) =>
    '{"id":"$id","conversationId":"conversation-1",'
    '"senderUserId":"user-1","content":"Hola",'
    '"createdAtUtc":"2026-10-10T18:58:13.504723Z",'
    '"editedAtUtc":null,"deletedAtUtc":null}';
