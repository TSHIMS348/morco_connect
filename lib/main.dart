import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/auth/services/auth_session.dart';

// =============================
// 🟣 ANNOUNCEMENTS
// =============================
import 'features/announcements/models/announcement.dart';
import 'features/announcements/models/announcement_target.dart';
import 'features/announcements/models/announcement_type.dart';
import 'features/announcements/models/announcement_priority.dart';
import 'features/announcements/models/announcement_target_type.dart';
import 'features/announcements/models/announcement_status.dart';

// =============================
// 🧱 MESSAGING
// =============================
import 'features/messaging/models/attachment.dart';
import 'features/messaging/models/message.dart';
import 'features/messaging/models/conversation.dart';
import 'features/messaging/models/attachment_type.dart';
import 'features/messaging/models/message_status.dart';
import 'features/messaging/models/conversation_type.dart';

// =============================
// 🔐 AUTH
// =============================
import 'features/auth/models/user_role.dart';

// =============================
// 🔁 Messaging service
// =============================
import 'features/messaging/services/message_service.dart';

Future<void> main() async {
  // ⚠️ TOUJOURS en premier
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // =============================
    // 🧱 Hive init
    // =============================
    await Hive.initFlutter();

    // =============================
    // ✅ Register adapters (safe)
    // =============================
    _registerAdapterSafe(AttachmentAdapter());
    _registerAdapterSafe(MessageAdapter());
    _registerAdapterSafe(ConversationAdapter());

    _registerAdapterSafe(AttachmentTypeAdapter());
    _registerAdapterSafe(MessageStatusAdapter());
    _registerAdapterSafe(ConversationTypeAdapter());

    _registerAdapterSafe(UserRoleAdapter());

    _registerAdapterSafe(AnnouncementAdapter());
    _registerAdapterSafe(AnnouncementTargetAdapter());
    _registerAdapterSafe(AnnouncementTypeAdapter());
    _registerAdapterSafe(AnnouncementPriorityAdapter());
    _registerAdapterSafe(AnnouncementTargetTypeAdapter());
    _registerAdapterSafe(AnnouncementStatusAdapter());

    // =============================
    // 🔐 Restore session
    // =============================
    try {
      await AuthSession.restore();
    } catch (e, st) {
      debugPrint('⚠️ AuthSession.restore error: $e');
      debugPrintStack(stackTrace: st);
    }

    // =============================
    // 🔁 Retry failed messages
    // =============================
    try {
      await MessageService.retryAllFailed();
    } catch (e, st) {
      debugPrint('⚠️ retryAllFailed error: $e');
      debugPrintStack(stackTrace: st);
    }

    // =============================
    // 🚀 RUN APP (MÊME ZONE)
    // =============================
    runApp(const MorcoConnectApp());
  } catch (e, st) {
    // 🔴 Crash critique → app de secours
    debugPrint('❌ Fatal startup error: $e');
    debugPrintStack(stackTrace: st);

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Erreur au démarrage:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Enregistrement Hive sécurisé
void _registerAdapterSafe(TypeAdapter adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
