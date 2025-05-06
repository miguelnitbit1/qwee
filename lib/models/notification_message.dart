class NotificationMessage {
  final String message;
  final bool isError;
  
  NotificationMessage({
    required this.message,
    this.isError = false,
  });
}