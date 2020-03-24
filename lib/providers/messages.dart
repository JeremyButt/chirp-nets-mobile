import 'package:chirp_nets/models/message.dart';
import 'package:chirp_nets/models/user.dart';
import 'package:chirp_nets/utils/notifications.dart';
import 'package:flutter/material.dart';
import 'package:chirp_nets/utils/database.dart';
import 'package:chirp_nets/utils/utils.dart';
import 'users.dart';

class Messages with ChangeNotifier {
  Messages() {
    retrieveMessagesFromAllConversations();
  }

  Map<int, List<Message>> _messages = {};
  Users users;
  Map<int, Message> _lastMessages = {};

  Map<int, List<Message>> get messages {
    return {..._messages};
  }

  Map<int, Message> get lastMessages {
    return _lastMessages;
  }

  List<Message> getMessagesFromConversation(int convId) {
    if (_messages[convId] != null) {
      return _messages[convId];
    }
    return [];
  }

  void retrieveMessagesFromAllConversations() async {
    List<Message> messages;
    messages = await getMessages();
    for (Message message in messages) {
      if (_messages[message.conversationId] == null) {
        _messages[message.conversationId] = [message];
      } else {
        if (!_messages[message.conversationId].contains(message)) {
          _messages[message.conversationId].add(message);
        }
      }
    }
    notifyListeners();
  }

  List<int> getUserIds(int conversationId) {
    List<int> ids = [];
    List<Message> messages = getMessagesFromConversation(conversationId);
    messages.forEach((message) {
      if (!ids.contains(message.sentBy)) {
        ids.add(message.sentBy);
      }
    });
    return ids;
  }

  Future<int> addMessage(int sentBy, int conversationId, String message,
      DateTime createdAt) async {
    Message newMessage = Message(
      sentBy: sentBy,
      conversationId: conversationId,
      message: message,
      createdAt: createdAt,
    );
    int id = await create(table: 'messages', object: newMessage);
    _lastMessages[conversationId] = newMessage;
    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId].add(
      Message(
        id: id,
        sentBy: sentBy,
        conversationId: conversationId,
        message: message,
        createdAt: createdAt,
      ),
    );
    notifyListeners();
    return id;
  }

  List<Message> getList(int conversationId) {
    List<Message> messages = [];
    messages = getMessagesFromConversation(conversationId);
    messages.sort((a, b) => -a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  void deleteMessage(id) {
    _messages.remove(id);
    delete(table: 'messages', id: id);
    notifyListeners();
  }

  void getLastMessageFromConversation(int conversationId) async {
    List<Message> message = await getMessages(
            where: 'conversationId = ?', whereArgs: [conversationId], limit: 10)
        .then((m) => m);
    var lastMessage = message.isEmpty ? Message() : message[0];
    _lastMessages.putIfAbsent(conversationId, () => lastMessage);
    notifyListeners();
  }

  void recieveMessage(List<int> listMessage) async {
    List<int> recievedMessage = listMessage.sublist(0, listMessage.length - 1);
    // int checksum = listMessage.last;
    // if (!validateChecksum(checksum, recievedMessage)) {
    //   debugPrint('Checksum incorrect');
    // }
    // Here we should check the nodeId in the packet and set accordingly
    User user = await users.getOrCreate(name: 'Becky', nodeId: 1);
    String parsedMessage = parseMessage(recievedMessage);
    print(parsedMessage);
    if (parsedMessage != '') {
      addMessage(user.id, 1, parsedMessage, DateTime.now());
      showNotification(0, '${user.name}', '$parsedMessage', '$parsedMessage');
    }
  }
}
