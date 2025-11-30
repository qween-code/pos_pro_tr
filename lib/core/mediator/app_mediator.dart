import 'dart:async';

/// Base class for all application events
abstract class AppEvent {
  final DateTime timestamp;
  
  AppEvent() : timestamp = DateTime.now();
  
  String get eventType => runtimeType.toString();
}

/// Mediator pattern implementation for loose coupling between features
class AppMediator {
  static final AppMediator _instance = AppMediator._internal();
  factory AppMediator() => _instance;
  AppMediator._internal();
  
  final _eventController = StreamController<AppEvent>.broadcast();
  
  /// Publish an event to all listeners
  void publish(AppEvent event) {
    _eventController.add(event);
  }
  
  /// Subscribe to specific event type
  Stream<T> on<T extends AppEvent>() {
    return _eventController.stream
        .where((event) => event is T)
        .cast<T>();
  }
  
  /// Subscribe to all events
  Stream<AppEvent> get stream => _eventController.stream;
  
  /// Dispose mediator resources
  void dispose() {
    _eventController.close();
  }
}
