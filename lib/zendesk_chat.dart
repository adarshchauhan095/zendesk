import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zendesk2/zendesk2.dart';

class ZendeskChat extends StatefulWidget {
  const ZendeskChat({Key? key}) : super(key: key);

  @override
  _ZendeskChat createState() => _ZendeskChat();
}

class _ZendeskChat extends State<ZendeskChat> {
  final Zendesk2Chat _z = Zendesk2Chat.instance;

  final _tecM = TextEditingController();
  ChatProviderModel? _providerModel;
  ChatSettingsModel? _chatSettingsModel;
  CONNECTION_STATUS? _connectionStatus;
  ChatAccountModel? _chatAccountModel;

  StreamSubscription<ChatProviderModel>? _subscriptionProvidersStream;
  StreamSubscription<CONNECTION_STATUS>? _subscriptionConnetionStatusStream;
  StreamSubscription<ChatSettingsModel>? _subscriptionChatSettingsStream;
  StreamSubscription<ChatAccountModel>? _subscriptionAccountProvidersStream;

  Future<bool> _onWillPopScope() async {
    await _subscriptionProvidersStream?.cancel();
    await _subscriptionConnetionStatusStream?.cancel();
    await _subscriptionChatSettingsStream?.cancel();
    await _subscriptionAccountProvidersStream?.cancel();
    await _z.dispose();
    await _z.disconnect();
    return true;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await _z.connect();
      _subscriptionProvidersStream =
          _z.providersStream?.listen((providerModel) {
        _providerModel = providerModel;
        debugPrint('ProviderModel: ${_providerModel!.isChatting}');
        setState(() {});
      });
      _subscriptionChatSettingsStream =
          _z.chatSettingsStream?.listen((settingsModel) {
        _chatSettingsModel = settingsModel;
        debugPrint('Chat Settings: ${_chatSettingsModel!.fileSizeLimit}');
        setState(() {});
      });
      _subscriptionConnetionStatusStream =
          _z.connectionStatusStream?.listen((connectionStatus) {
        _connectionStatus = connectionStatus;
        debugPrint('Connection Status: $_connectionStatus');
        setState(() {});
      });
      _subscriptionAccountProvidersStream =
          _z.chatIsOnlineStream?.listen((chatAccountModel) {
        _chatAccountModel = chatAccountModel;
        debugPrint('isOnline: ${_chatAccountModel!.isOnline}');
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isOnline =
        ((_chatAccountModel?.isOnline ?? false) ? 'ONLINE' : 'OFFLINE');
    return WillPopScope(
      onWillPop: _onWillPopScope,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.black,
            size: 35,
          ),
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Contact us',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(
                width: 10,
              ),
              (_chatAccountModel?.isOnline ?? false)
                  ? const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 10,
                    )
                  : const SizedBox()
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.black,
              ),
            )
          ],
        ),
        body: _providerModel == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_providerModel != null) Expanded(child: _chat()),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_providerModel != null &&
                          _providerModel!.agents.isNotEmpty)
                        if (_providerModel!.agents.first.isTyping)
                          const Text(
                            'Agent is typing...',
                            textAlign: TextAlign.start,
                          ),
                      Padding(
                        padding: EdgeInsets.only(bottom: mq.viewPadding.bottom),
                        child: Column(
                          children: [
                            if (_chatSettingsModel?.fileSizeLimit != null)
                              Column(
                                children: [
                                  Text('Can send files: ' +
                                      _chatSettingsModel!.isFileSendingEnabled!
                                          .toString()),
                                  Text('Fle size limit: ' +
                                      (_chatSettingsModel!.fileSizeLimit! ~/
                                              1024)
                                          .toString()
                                          .substring(0, 2) +
                                      ' MB'),
                                ],
                              ),
                            Text('$_connectionStatus'),
                            _userWidget(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _attach() async {
    bool isPhoto = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: const [
                Icon(Icons.camera_alt),
                Text('Photo'),
              ],
            ),
            onTap: () => Navigator.of(context).pop(true),
          ),
          ListTile(
            title: Row(
              children: const [
                Icon(FontAwesomeIcons.file),
                Text('File'),
              ],
            ),
            onTap: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );

    final compatibleExt = _chatSettingsModel?.supportedFileTypes;

    final Object? result;
    if (isPhoto) {
      result = await ImagePicker().pickImage(source: ImageSource.gallery);
    } else {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: compatibleExt?.toList() ?? [],
      );
    }
    final file =
        result is FilePickerResult ? result.files.single : (result as File);

    final path = file is PlatformFile ? file.path : (file as File).path;

    _z.sendFile(path!);
  }

  void _settings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: const [
                Icon(Icons.close),
                Text('End chat'),
              ],
            ),
            onTap: () async {
              await _z.endChat();
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  void _send() async {
    final text = _tecM.text;
    if (text.isNotEmpty) {
      await _z.sendMessage(text);
      _tecM.clear();
      _z.sendTyping(false);
      setState(() {});
    }
  }

  Widget _userWidget() => Container(
        padding: const EdgeInsets.all(5),
        child: Card(
          color: Theme.of(context).primaryColor,
          elevation: 10,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 0.1,
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.amber),
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        FontAwesomeIcons.pencilAlt,
                        color: Colors.white,
                      ),
                    ),
                    controller: _tecM,
                    onChanged: (text) => _z.sendTyping(text.isNotEmpty),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'attachFab',
                      mini: true,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.attach_file),
                      onPressed: _attach,
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zendeskSettings',
                      child: const Icon(Icons.settings),
                      onPressed: _settings,
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'zendeskSend',
                      child: const Icon(Icons.send),
                      onPressed: _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _chat() => Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: (_providerModel?.logs ?? []).map(
              (log) {
                ChatMessage? chatMessage = log.chatLogType.chatMessage;

                String message = chatMessage?.message ?? '';

                String name = log.displayName;

                bool isAttachment = false;
                bool isJoinOrLeave = false;
                bool isAgent = log.chatParticipant == CHAT_PARTICIPANT.AGENT;

                Agent? agent;
                if (isAgent) {
                  agent = _providerModel!.agents.firstWhereOrNull(
                      (element) => element.displayName == name);
                }

                switch (log.chatLogType.logType) {
                  case LOG_TYPE.ATTACHMENT_MESSAGE:
                    message = 'Attachment';
                    isAttachment = true;
                    break;
                  case LOG_TYPE.MEMBER_JOIN:
                    message = '$name Joined!';
                    isJoinOrLeave = true;
                    break;
                  case LOG_TYPE.MEMBER_LEAVE:
                    message = '$name Left!';
                    isJoinOrLeave = true;
                    break;
                  case LOG_TYPE.MESSAGE:
                    message = message;
                    break;
                  case LOG_TYPE.OPTIONS_MESSAGE:
                    message = 'Options message';
                    break;
                }

                bool isVisitor =
                    log.chatParticipant == CHAT_PARTICIPANT.VISITOR;

                final imageUrl = log.chatLogType.chatAttachment?.url;

                final mimeType = log.chatLogType.chatAttachment
                    ?.chatAttachmentAttachment.mimeType
                    ?.toLowerCase();
                final isImage = mimeType == null
                    ? false
                    : (mimeType.contains('jpg') ||
                        mimeType.contains('png') ||
                        mimeType.contains('jpeg') ||
                        mimeType.contains('gif'));

                return isJoinOrLeave
                    ? Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: isVisitor
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isAgent)
                                  agent?.avatar != null
                                      ? CachedNetworkImage(
                                          imageUrl: agent!.avatar ?? '')
                                      : const Icon(Icons.person),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: message.length <= 50
                                          ? double.infinity
                                          : MediaQuery.of(context).size.width *
                                              0.6,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        if (isAttachment)
                                          GestureDetector(
                                            onTap: () => launch(log
                                                    .chatLogType
                                                    .chatAttachment
                                                    ?.chatAttachmentAttachment
                                                    .url ??
                                                ''),
                                            child: isImage
                                                ? CachedNetworkImage(
                                                    imageUrl: imageUrl ?? '',
                                                    placeholder: (context,
                                                            url) =>
                                                        const CircularProgressIndicator(),
                                                  )
                                                : Column(
                                                    children: [
                                                      const Icon(
                                                          FontAwesomeIcons
                                                              .file),
                                                      Text(log
                                                              .chatLogType
                                                              .chatAttachment
                                                              ?.chatAttachmentAttachment
                                                              .name ??
                                                          '')
                                                    ],
                                                  ),
                                          ),
                                        Text(message),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isVisitor)
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 15,
                                    color: Colors.purple,
                                  ),
                              ],
                            ),
                          )
                        ],
                      );
              },
            ).toList(),
          ),
        ),
      );
}
