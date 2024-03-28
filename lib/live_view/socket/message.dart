class LiveMessage {
  LiveMessage({
    required this.event,
    this.payload,
    this.topic,
    this.ref,
  });

  final String event;
  final Map<String, dynamic>? payload;
  final String? topic;
  final String? ref;
}
