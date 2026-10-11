import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/core/support_service.dart';

void main() {
  group('SupportCategory & TicketStatus Enums', () {
    test('SupportCategory fromValue resolves known and falls back to ostalo', () {
      expect(SupportCategory.fromValue('bug'), SupportCategory.bug);
      expect(SupportCategory.fromValue('pitanje'), SupportCategory.pitanje);
      expect(SupportCategory.fromValue('sugestija'), SupportCategory.sugestija);
      expect(SupportCategory.fromValue('ostalo'), SupportCategory.ostalo);
      expect(SupportCategory.fromValue('non_existing'), SupportCategory.ostalo);
    });

    test('TicketStatus fromValue resolves known and falls back to otvoren', () {
      expect(TicketStatus.fromValue('otvoren'), TicketStatus.otvoren);
      expect(TicketStatus.fromValue('u_obradi'), TicketStatus.uObradi);
      expect(TicketStatus.fromValue('zatvoren'), TicketStatus.zatvoren);
      expect(TicketStatus.fromValue('unknown_status'), TicketStatus.otvoren);
    });
  });

  group('SupportTicketModel Serialization', () {
    test('parses modern json schema properly', () {
      final json = {
        'id': 'uuid-1234-5678',
        'ticket_number': 'TKT-AB12CD',
        'user_id': 'user-1',
        'user_email': 'test@example.com',
        'user_name': 'Marko Marković',
        'category': 'bug',
        'subject': 'Greška sa korpom',
        'body': 'Ne mogu da promenim količinu',
        'status': 'u_obradi',
        'admin_note': 'Istražujemo problem',
        'created_at': '2026-10-08T12:00:00Z',
        'updated_at': '2026-10-08T12:30:00Z',
      };

      final ticket = SupportTicketModel.fromJson(json);

      expect(ticket.id, 'uuid-1234-5678');
      expect(ticket.ticketNumber, 'TKT-AB12CD');
      expect(ticket.userId, 'user-1');
      expect(ticket.userEmail, 'test@example.com');
      expect(ticket.userName, 'Marko Marković');
      expect(ticket.category, SupportCategory.bug);
      expect(ticket.subject, 'Greška sa korpom');
      expect(ticket.body, 'Ne mogu da promenim količinu');
      expect(ticket.status, TicketStatus.uObradi);
      expect(ticket.adminNote, 'Istražujemo problem');
    });

    test('parses legacy json schema with message and email fallback', () {
      final json = {
        'id': 'abcd1234-legacy',
        'email': 'legacy@example.com',
        'subject': 'Pitanje o dostavi',
        'message': 'Legacy message content',
        'admin_reply': 'Legacy admin reply',
        'created_at': '2026-10-08T10:00:00Z',
        'updated_at': '2026-10-08T10:00:00Z',
      };

      final ticket = SupportTicketModel.fromJson(json);

      expect(ticket.id, 'abcd1234-legacy');
      expect(ticket.ticketNumber, 'TKT-ABCD1234');
      expect(ticket.userEmail, 'legacy@example.com');
      expect(ticket.body, 'Legacy message content');
      expect(ticket.adminNote, 'Legacy admin reply');
      expect(ticket.category, SupportCategory.ostalo);
      expect(ticket.status, TicketStatus.otvoren);
    });
  });

  group('TicketMessageModel Serialization', () {
    test('parses message model and correctly sets isAdmin flag', () {
      final userJson = {
        'id': 'msg-1',
        'ticket_id': 'ticket-1',
        'sender_id': 'user-1',
        'sender_role': 'user',
        'body': 'Pozdrav, imam pitanje.',
        'created_at': '2026-10-08T14:00:00Z',
      };
      final userMsg = TicketMessageModel.fromJson(userJson);
      expect(userMsg.id, 'msg-1');
      expect(userMsg.isAdmin, isFalse);

      final adminJson = {
        'id': 'msg-2',
        'ticket_id': 'ticket-1',
        'sender_id': 'admin-1',
        'sender_role': 'admin',
        'body': 'Odgovor od tima za podršku.',
        'created_at': '2026-10-08T14:05:00Z',
      };
      final adminMsg = TicketMessageModel.fromJson(adminJson);
      expect(adminMsg.id, 'msg-2');
      expect(adminMsg.isAdmin, isTrue);
    });
  });
}
