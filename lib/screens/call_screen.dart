import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_state.dart';
import '../providers/call_provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        final state = provider.state;

        return Scaffold(
          backgroundColor: _getBackgroundColor(state.phase),
          body: SafeArea(
            child: state.phase == CallPhase.ended
                ? _buildEndedScreen(state)
                : Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildCallerAvatar(state),
                      const SizedBox(height: 24),
                      _buildCallerInfo(state),
                      const SizedBox(height: 16),
                      _buildStatusText(state),
                      const Spacer(),
                      if (state.currentMessage.isNotEmpty)
                        Flexible(child: _buildMessageBubble(state)),
                      if (state.isListening)
                        Flexible(child: _buildInputField(provider)),
                      const Spacer(),
                      _buildCallControls(provider, state),
                      const SizedBox(height: 48),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(CallPhase phase) {
    switch (phase) {
      case CallPhase.incoming:
        return const Color(0xFF1a1a2e);
      case CallPhase.ended:
        return const Color(0xFF2d2d44);
      default:
        return const Color(0xFF16213e);
    }
  }

  Widget _buildEndedScreen(CallState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade700,
              ),
              child: const Icon(
                Icons.call_end,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Call Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thanks for using Todo Assistant',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            if (state.currentMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  state.currentMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerAvatar(CallState state) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale =
            state.isSpeaking ? 1.0 + (_pulseController.value * 0.1) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: state.isSpeaking
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : [Colors.blue.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (state.isSpeaking ? Colors.green : Colors.blue)
                      .withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallerInfo(CallState state) {
    return Column(
      children: [
        const Text(
          'Todo Assistant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.phase == CallPhase.incoming ? 'Incoming call...' : 'In call',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(CallState state) {
    String status;
    switch (state.phase) {
      case CallPhase.incoming:
        status = 'Swipe up to answer';
        break;
      case CallPhase.greeting:
        status = 'Greeting...';
        break;
      case CallPhase.reviewTodos:
        status = 'Reviewing your tasks...';
        break;
      case CallPhase.addingTodos:
        status = 'Listening for new tasks...';
        break;
      case CallPhase.summary:
        status = 'Wrapping up...';
        break;
      case CallPhase.ended:
        status = 'Call ended';
        break;
    }

    return Text(
      status,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 14,
      ),
    );
  }

  Widget _buildMessageBubble(CallState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (state.isSpeaking)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => _buildSpeakingDot(index),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            state.currentMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakingDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final offset = index * 0.2;
        final value = ((_pulseController.value + offset) % 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8 + (value * 16),
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildInputField(CallProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a new task...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  provider.processUserInput(text);
                  _inputController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              if (_inputController.text.isNotEmpty) {
                provider.processUserInput(_inputController.text);
                _inputController.clear();
              }
            },
            icon: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(CallProvider provider, CallState state) {
    if (state.phase == CallPhase.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            label: 'Decline',
            onTap: () => provider.skipCall(),
          ),
          _buildControlButton(
            icon: Icons.call,
            color: Colors.green,
            label: 'Accept',
            onTap: () => provider.acceptCall(),
            isLarge: true,
          ),
          _buildControlButton(
            icon: Icons.schedule,
            color: Colors.orange,
            label: 'Later',
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
    }

    if (state.phase == CallPhase.ended) {
      return _buildControlButton(
        icon: Icons.close,
        color: Colors.grey,
        label: 'Close',
        onTap: () => Navigator.pop(context),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.check,
          color: Colors.green,
          label: 'Done',
          onTap: () => provider.processUserInput("That's all"),
        ),
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: 'End',
          onTap: () => provider.endCall(),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 70.0 : 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isLarge ? 32 : 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
