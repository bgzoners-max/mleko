import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Realtime Channels & Unread Count Batching Tests', () {
    test('debouncing coalesces multiple burst events into a single database fetch', () async {
      int fetchCount = 0;
      Timer? debounceTimer;

      void scheduleLoadUnreadCount([Duration delay = const Duration(milliseconds: 50)]) {
        debounceTimer?.cancel();
        debounceTimer = Timer(delay, () {
          fetchCount++;
        });
      }

      // Simulate a burst of 10 incoming notifications arriving 5ms apart
      for (int i = 0; i < 10; i++) {
        scheduleLoadUnreadCount();
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // At this point, the timer has been constantly rescheduled, so fetchCount should still be 0
      expect(fetchCount, equals(0), reason: 'Debounce timer should not fire during rapid bursts');

      // Wait for debounce window (50ms) to elapse
      await Future.delayed(const Duration(milliseconds: 80));

      // After cooldown, exactly one fetch should have executed
      expect(fetchCount, equals(1), reason: 'Multiple rapid events must coalesce into 1 fetch');

      debounceTimer?.cancel();
    });

    test('debouncing allows subsequent calls after previous delay completes', () async {
      int fetchCount = 0;
      Timer? debounceTimer;

      void scheduleLoadUnreadCount([Duration delay = const Duration(milliseconds: 30)]) {
        debounceTimer?.cancel();
        debounceTimer = Timer(delay, () {
          fetchCount++;
        });
      }

      // First trigger
      scheduleLoadUnreadCount();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fetchCount, equals(1));

      // Second trigger after delay completes
      scheduleLoadUnreadCount();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fetchCount, equals(2));

      debounceTimer?.cancel();
    });

    test('conversation room reference counting properly tracks active listeners and cleanup', () {
      final rooms = <String, ({int refCount, List<void Function()> callbacks})>{};

      void addListener(String convId, void Function() cb) {
        var room = rooms[convId];
        if (room == null) {
          room = (refCount: 0, callbacks: <void Function()>[]);
          rooms[convId] = room;
        }
        room.callbacks.add(cb);
        rooms[convId] = (refCount: room.refCount + 1, callbacks: room.callbacks);
      }

      void removeListener(String convId, void Function() cb) {
        final room = rooms[convId];
        if (room == null) return;
        room.callbacks.remove(cb);
        final newCount = room.refCount - 1;
        if (newCount <= 0) {
          rooms.remove(convId);
        } else {
          rooms[convId] = (refCount: newCount, callbacks: room.callbacks);
        }
      }

      const convId = 'conv-123';
      void onMsg() {}
      void onTyping() {}
      void onReaction() {}

      // Open screen: 3 streams subscribe
      addListener(convId, onMsg);
      addListener(convId, onTyping);
      addListener(convId, onReaction);

      expect(rooms.containsKey(convId), isTrue);
      expect(rooms[convId]!.refCount, equals(3));
      expect(rooms[convId]!.callbacks.length, equals(3));

      // Close typing indicator
      removeListener(convId, onTyping);
      expect(rooms.containsKey(convId), isTrue);
      expect(rooms[convId]!.refCount, equals(2));

      // Close reactions and messages
      removeListener(convId, onReaction);
      removeListener(convId, onMsg);

      // Room should be completely removed from active channels
      expect(rooms.containsKey(convId), isFalse);
    });
  });
}
