import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/communication/realtime_channel_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRealtimeChannel extends RealtimeChannel {
  bool subscribed = false;
  _FakeRealtimeChannel(super.topic, super.client);

  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    subscribed = true;
    callback?.call(RealtimeSubscribeStatus.subscribed, null);
    return this;
  }
}

void main() {
  group('RealtimeChannelManager', () {
    late RealtimeChannelManager manager;
    late SupabaseClient mockClient;
    final List<RealtimeChannel> removedChannels = [];

    setUp(() {
      manager = RealtimeChannelManager();
      removedChannels.clear();
      mockClient = SupabaseClient('https://fake.supabase.co', 'fake-key');
    });

    tearDown(() async {
      await manager.releaseAll(mockClient);
    });

    test('acquires channel lazily and ref-counts multiple listeners', () {
      const channelName = 'products-seller-seller123';
      int eventCountA = 0;
      int eventCountB = 0;
      void Function()? trigger;

      final releaseA = manager.acquire(
        client: mockClient,
        channelName: channelName,
        onEvent: () => eventCountA++,
        createChannel: (client, notifyAll) {
          trigger = notifyAll;
          return _FakeRealtimeChannel(channelName, client.realtime);
        },
      );

      expect(manager.activeChannelCount, equals(1));
      expect(manager.refCount(channelName), equals(1));

      final releaseB = manager.acquire(
        client: mockClient,
        channelName: channelName,
        onEvent: () => eventCountB++,
        createChannel: (client, notifyAll) {
          fail('createChannel should not be called when channel already exists');
        },
      );

      expect(manager.activeChannelCount, equals(1));
      expect(manager.refCount(channelName), equals(2));

      // Trigger event should notify both listeners
      trigger?.call();
      expect(eventCountA, equals(1));
      expect(eventCountB, equals(1));

      // Release first listener - channel remains active
      releaseA();
      expect(manager.activeChannelCount, equals(1));
      expect(manager.refCount(channelName), equals(1));

      // Trigger should now only notify listener B
      trigger?.call();
      expect(eventCountA, equals(1));
      expect(eventCountB, equals(2));

      // Release second listener - channel is removed
      releaseB();
      expect(manager.activeChannelCount, equals(0));
      expect(manager.refCount(channelName), equals(0));
    });

    test('double release of the same callback is idempotent', () {
      const channelName = 'orders-seller-seller999';
      final release = manager.acquire(
        client: mockClient,
        channelName: channelName,
        onEvent: () {},
        createChannel: (client, notifyAll) =>
            _FakeRealtimeChannel(channelName, client.realtime),
      );

      expect(manager.refCount(channelName), equals(1));
      release();
      expect(manager.refCount(channelName), equals(0));
      release(); // Second call should not go negative
      expect(manager.refCount(channelName), equals(0));
    });
  });
}
