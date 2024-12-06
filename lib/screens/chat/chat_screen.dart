class ChatScreen extends StatefulWidget {
  final String chatId;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  bool _isAttaching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ChatHeader(chatId: widget.chatId),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(chatId: widget.chatId),
          ),
          MessageComposer(
            controller: _messageController,
            onSend: _sendMessage,
            onAttach: _attachFile,
          ),
        ],
      ),
    );
  }
}
