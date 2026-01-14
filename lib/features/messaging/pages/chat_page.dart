import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/services/auth_session.dart';
import '../models/conversation.dart';
import '../models/conversation_type.dart';
import '../models/message.dart';
import '../models/message_status.dart';
import '../models/attachment_type.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Conversation? _conv;
  List<Message> _messages = const [];

  final _inputCtrl = TextEditingController();
  bool _showEmoji = false;

  // 🎤 Audio – enregistrement
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  // ▶️ Audio – lecture
  final AudioPlayer _player = AudioPlayer();
  String? _playingAttachmentId;

  @override
  void initState() {
    super.initState();

    // ⭐ Chargement depuis Hive + marquage delivered/read pour DIRECT
    MessageService.loadConversation(widget.conversationId).then((_) {
      final me = AuthSession.currentUser?.matricule;
      final c = ConversationService.getById(widget.conversationId);

      if (me != null && c?.type == ConversationType.direct) {
        MessageService.markDirectConversationAsRead(
          conversationId: widget.conversationId,
          readerMatricule: me,
        );
      }

      _reload();
    });
  }

  @override
  void dispose() {
    // 🧹 Nettoyage cache mémoire
    MessageService.clearCacheFor(widget.conversationId);

    _inputCtrl.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _conv = ConversationService.getById(widget.conversationId);
      _messages = MessageService.getMessages(widget.conversationId);
    });
  }

  String _title(Conversation c) {
    switch (c.type) {
      case ConversationType.global:
        return 'Global';
      default:
        return c.title;
    }
  }

  // ✉️ TEXTE
  Future<void> _sendText() async {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;

    MessageService.sendText(
      conversationId: widget.conversationId,
      content: text,
    );

    _inputCtrl.clear();
    _reload();
  }

  // 🖼️ IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final f = File(x.path);
    final att = MessageService.makeAttachment(
      type: AttachmentType.image,
      path: x.path,
      name: x.name,
      sizeBytes: await f.length(),
    );

    MessageService.sendWithAttachments(
      conversationId: widget.conversationId,
      attachments: [att],
    );
    _reload();
  }

  // 📎 FICHIER
  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    if (f.path == null) return;

    final att = MessageService.makeAttachment(
      type: AttachmentType.file,
      path: f.path!,
      name: f.name,
      sizeBytes: f.size,
    );

    MessageService.sendWithAttachments(
      conversationId: widget.conversationId,
      attachments: [att],
    );
    _reload();
  }

  // 🎤 AUDIO
  Future<void> _toggleRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path == null) return;
      final f = File(path);

      final att = MessageService.makeAttachment(
        type: AttachmentType.audio,
        path: path,
        name: 'Message vocal',
        sizeBytes: await f.length(),
      );

      MessageService.sendWithAttachments(
        conversationId: widget.conversationId,
        attachments: [att],
      );
      _reload();
    } else {
      if (!await _recorder.hasPermission()) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() => _isRecording = true);
    }
  }

  // ▶️ LECTURE AUDIO
  Future<void> _togglePlayAudio({
    required String attachmentId,
    required String path,
  }) async {
    if (_playingAttachmentId == attachmentId && _player.playing) {
      await _player.pause();
      setState(() {});
      return;
    }

    await _player.stop();
    _playingAttachmentId = attachmentId;
    await _player.setFilePath(path);
    await _player.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthSession.currentUser?.matricule ?? '';
    final isAdmin = AuthSession.isAdmin;
    final c = _conv;

    if (c == null) {
      return const Scaffold(
        body: Center(child: Text('Conversation introuvable')),
      );
    }

    final canWrite = isAdmin || c.participants.contains(me);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title(c)),
            Text(
              '${c.participants.length} membres',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.senderMatricule == me;

                final time =
                    '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}';

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(
                            m.senderMatricule,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        if (m.hasText) Text(m.content!),

                        for (final a in m.attachments) ...[
                          const SizedBox(height: 6),
                          if (a.type == AttachmentType.image)
                            GestureDetector(
                              onTap: () => OpenFilex.open(a.path),
                              child: Image.file(File(a.path), width: 180),
                            ),
                          if (a.type == AttachmentType.file)
                            ListTile(
                              dense: true,
                              leading:
                                  const Icon(Icons.insert_drive_file),
                              title: Text(a.name),
                              onTap: () => OpenFilex.open(a.path),
                            ),
                          if (a.type == AttachmentType.audio)
                            _AudioTile(
                              title: a.name,
                              sizeBytes: a.sizeBytes,
                              isPlaying:
                                  _playingAttachmentId == a.id &&
                                      _player.playing,
                              onPlayPause: () => _togglePlayAudio(
                                attachmentId: a.id,
                                path: a.path,
                              ),
                              onOpenExternal: () =>
                                  OpenFilex.open(a.path),
                            ),
                        ],

                        const SizedBox(height: 4),

                        // ⏱️ HEURE + STATUT WHATSAPP-LIKE
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(time,
                                style: const TextStyle(fontSize: 11)),
                            if (isMe)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 6),
                                child: GestureDetector(
                                  onTap: m.status ==
                                          MessageStatus.failed
                                      ? () {
                                          MessageService.retry(m);
                                          _reload();
                                        }
                                      : null,
                                  child: Icon(
                                    m.status == MessageStatus.sent
                                        ? Icons.check
                                        : m.status ==
                                                MessageStatus.delivered
                                            ? Icons.done_all
                                            : m.status ==
                                                    MessageStatus.read
                                                ? Icons.done_all
                                                : Icons.schedule,
                                    size: 14,
                                    color: m.status ==
                                            MessageStatus.read
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (!canWrite)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: const Text(
                'Lecture seule — vous n’êtes pas membre',
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions),
                        onPressed: () =>
                            setState(() => _showEmoji = !_showEmoji),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _pickFile,
                      ),
                      IconButton(
                        icon: Icon(
                          _isRecording
                              ? Icons.stop_circle
                              : Icons.mic,
                          color:
                              _isRecording ? Colors.red : null,
                        ),
                        onPressed: _toggleRecord,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          enabled: !_isRecording,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Message…',
                          ),
                          onSubmitted: (_) => _sendText(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed:
                            _isRecording ? null : _sendText,
                      ),
                    ],
                  ),
                  if (_showEmoji)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        textEditingController: _inputCtrl,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// 🎧 AUDIO TILE
class _AudioTile extends StatelessWidget {
  final String title;
  final int sizeBytes;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onOpenExternal;

  const _AudioTile({
    required this.title,
    required this.sizeBytes,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: onPlayPause,
        ),
        Expanded(child: Text(title)),
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: onOpenExternal,
        ),
      ],
    );
  }
}
