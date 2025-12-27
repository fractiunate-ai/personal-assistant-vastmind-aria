import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/call_state.dart';
import '../models/todo.dart';
import '../services/audio_service.dart';
import '../services/gradio_tts_service.dart';
import '../services/todo_service.dart';

class CallProvider extends ChangeNotifier {
  final TodoService _todoService;
  final GradioTtsService _ttsService;
  final AudioService _audioService;

  CallState _state = const CallState();
  String _userName = 'David';

  CallState get state => _state;
  String get userName => _userName;
  List<Todo> get todos => _todoService.todos;
  List<Todo> get activeTodos => _todoService.activeTodos;

  CallProvider({
    required TodoService todoService,
    required GradioTtsService ttsService,
    required AudioService audioService,
  })  : _todoService = todoService,
        _ttsService = ttsService,
        _audioService = audioService {
    _audioService.onPlaybackComplete.listen((_) => _onSpeechComplete());
  }

  /// Accept incoming call and start the conversation
  Future<void> acceptCall() async {
    _updateState(_state.copyWith(phase: CallPhase.greeting));
    await _speak(_todoService.getTimeBasedGreeting(_userName));
  }

  /// Decline or end the call
  void endCall() {
    _audioService.stop();
    _updateState(const CallState(phase: CallPhase.ended));
  }

  /// Skip today's call
  void skipCall() {
    endCall();
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    _updateState(_state.copyWith(
      isSpeaking: true,
      currentMessage: text,
      conversationHistory: [..._state.conversationHistory, 'AI: $text'],
    ));

    final audioPath = await _ttsService.synthesizeSpeech(text);
    if (audioPath != null) {
      await _audioService.playFile(audioPath);
    } else {
      // TTS failed, simulate delay then continue
      await Future.delayed(const Duration(seconds: 2));
      _onSpeechComplete();
    }
  }

  /// Called when speech playback completes
  void _onSpeechComplete() {
    _updateState(_state.copyWith(isSpeaking: false));

    // Progress to next phase
    switch (_state.phase) {
      case CallPhase.greeting:
        _startTodoReview();
        break;
      case CallPhase.reviewTodos:
        _askForNewTodos();
        break;
      case CallPhase.addingTodos:
        _startListening();
        break;
      case CallPhase.summary:
        endCall();
        break;
      default:
        break;
    }
  }

  /// Review current todos
  Future<void> _startTodoReview() async {
    _updateState(_state.copyWith(phase: CallPhase.reviewTodos));
    final summary = _todoService.getTodoSummary();
    await _speak(summary);
  }

  /// Ask about new todos
  Future<void> _askForNewTodos() async {
    _updateState(_state.copyWith(phase: CallPhase.addingTodos));
    await _speak(
        "Would you like to add any new tasks? Say them now, or tap end call when done.");
  }

  /// Start listening for user input
  void _startListening() {
    _updateState(_state.copyWith(isListening: true));
    // In a full implementation, this would use speech-to-text
    // For now, we'll wait for manual input
  }

  /// Process user voice input (or text for testing)
  Future<void> processUserInput(String input) async {
    _updateState(_state.copyWith(
      isListening: false,
      conversationHistory: [..._state.conversationHistory, 'You: $input'],
    ));

    // Check for completion phrases
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains('done') ||
        lowerInput.contains('no more') ||
        lowerInput.contains('that\'s all') ||
        lowerInput.contains('nothing')) {
      await _finishCall();
      return;
    }

    // Add as a new todo
    await _todoService.addTodo(title: input);
    await _speak("Added: $input. Anything else?");
  }

  /// Finish the call with a summary
  Future<void> _finishCall() async {
    _updateState(_state.copyWith(phase: CallPhase.summary));

    final active = _todoService.activeTodos.length;
    await _speak(
      "Great! You now have $active active tasks. Have a productive day! Talk to you tomorrow.",
    );
  }

  /// Toggle todo completion
  Future<void> toggleTodo(String id) async {
    await _todoService.toggleComplete(id);
    notifyListeners();
  }

  /// Add a todo manually
  Future<void> addTodo(String title) async {
    await _todoService.addTodo(title: title);
    notifyListeners();
  }

  /// Delete a todo
  Future<void> deleteTodo(String id) async {
    await _todoService.deleteTodo(id);
    notifyListeners();
  }

  void _updateState(CallState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Reset to incoming call state (for testing)
  void resetCall() {
    _updateState(const CallState(phase: CallPhase.incoming));
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
