
enum MessageType {
  signal,
  rpc,
  internal,
}

abstract class AbMessage {
  int? type;
  String? id;
  // int? transactionId;
  dynamic payload;
}

 class MessageClass extends AbMessage{
  MessageType _messageType;
  String _id;
  int? _transactionId;
  dynamic _payload;

  MessageClass(String id, dynamic payload, MessageType messageType, int? transactionId)
      : _id = id,
        _payload = payload,
        _messageType = messageType,
         _transactionId = transactionId;

  dynamic getPayload() {
    return _payload;
  }
  dynamic getId() {
    return _id;
  }
  dynamic getMesageType() {
    return _messageType;
  }
  dynamic getTransactionId() {
    return _transactionId;
  }
}
