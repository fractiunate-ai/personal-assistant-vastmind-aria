enum CallPhase {
  incoming,      // Showing incoming call UI
  greeting,      // AI greeting the user
  reviewTodos,   // Reviewing current todos
  addingTodos,   // Adding new todos
  summary,       // Final summary
  ended,         // Call ended
}

class CallState {
  final CallPhase phase;
  final bool isSpeaking;
  final bool isListening;
  final String currentMessage;
  final List<String> conversationHistory;

  const CallState({
    this.phase = CallPhase.incoming,
    this.isSpeaking = false,
    this.isListening = false,
    this.currentMessage = '',
    this.conversationHistory = const [],
  });

  CallState copyWith({
    CallPhase? phase,
    bool? isSpeaking,
    bool? isListening,
    String? currentMessage,
    List<String>? conversationHistory,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      currentMessage: currentMessage ?? this.currentMessage,
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }

  bool get isActive =>
      phase != CallPhase.incoming && phase != CallPhase.ended;
}
