import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import 'dart:math';

class VoiceAssistantWidget extends StatefulWidget {
  final String userType;
  final Function(String)? onCommandRecognized;
  final bool showVisualFeedback;
  final bool showAdvancedControls;
  
  const VoiceAssistantWidget({
    Key? key,
    required this.userType,
    this.onCommandRecognized,
    this.showVisualFeedback = true,
    this.showAdvancedControls = false,
  }) : super(key: key);

  @override
  _VoiceAssistantWidgetState createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceService>(
      builder: (context, voiceService, child) {
        // Handle voice command navigation
        if (voiceService.lastRecognizedText.isNotEmpty) {
          String? command = voiceService.getMatchedCommand(voiceService.lastRecognizedText);
          if (command != null && widget.onCommandRecognized != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onCommandRecognized!(command);
            });
          }
        }
        
        // Animate pulse when listening
        if (voiceService.isListening) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _pulseController.reset();
          _waveController.stop();
          _waveController.reset();
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showVisualFeedback) ...[
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Wave animation
                  if (voiceService.isListening)
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 120 + (20 * _waveAnimation.value),
                          height: 120 + (20 * _waveAnimation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3 * (1 - _waveAnimation.value)),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Main microphone button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: voiceService.isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: voiceService.isListening 
                                ? Colors.red.withValues(alpha: 0.9)
                                : voiceService.isSpeaking
                                    ? Colors.blue.withValues(alpha: 0.9)
                                    : Colors.green.withValues(alpha: 0.9),
                            boxShadow: voiceService.isListening
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                  ]
                                : voiceService.isSpeaking
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : null,
                          ),
                          child: Icon(
                            voiceService.isListening 
                                ? Icons.mic 
                                : voiceService.isSpeaking
                                    ? Icons.volume_up
                                    : Icons.mic_none,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                voiceService.isListening 
                    ? "Listening..." 
                    : voiceService.isSpeaking 
                        ? "Speaking..." 
                        : "Tap to speak",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: voiceService.isListening 
                      ? Colors.red 
                      : voiceService.isSpeaking 
                          ? Colors.blue 
                          : Colors.grey[600],
                ),
              ),
              if (voiceService.lastRecognizedText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "You said: ${voiceService.lastRecognizedText}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
            
            // Voice control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Listen button
                ElevatedButton.icon(
                  onPressed: voiceService.isVoiceEnabled 
                      ? (voiceService.isListening 
                          ? voiceService.stopListening 
                          : voiceService.startListening)
                      : null,
                  icon: Icon(
                    voiceService.isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                  label: Text(
                    voiceService.isListening ? "Stop" : "Listen",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: voiceService.isListening 
                        ? Colors.red 
                        : voiceService.isVoiceEnabled
                            ? Colors.green
                            : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                
                // Help button
                ElevatedButton.icon(
                  onPressed: () => voiceService.provideHelp(widget.userType),
                  icon: const Icon(Icons.help, color: Colors.white),
                  label: const Text(
                    "Help",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
            
            // Advanced controls
            if (widget.showAdvancedControls) ...[
              const SizedBox(height: 20),
              _buildAdvancedControls(voiceService),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdvancedControls(VoiceService voiceService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            
            // Voice enabled toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Voice Enabled'),
                Switch(
                  value: voiceService.isVoiceEnabled,
                  onChanged: (value) => voiceService.toggleVoiceEnabled(),
                ),
              ],
            ),
            
            // Training mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Training Mode'),
                Switch(
                  value: voiceService.isTrainingMode,
                  onChanged: (value) => value 
                      ? voiceService.startTrainingMode()
                      : voiceService.stopTrainingMode(),
                ),
              ],
            ),
            
            // Language selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Language'),
                DropdownButton<String>(
                  value: voiceService.currentLanguage,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'te', child: Text('తెలుగు')),
                  ],
                  onChanged: (value) {
                    if (value != null) voiceService.setLanguage(value);
                  },
                ),
              ],
            ),
            
            // Context selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Context'),
                DropdownButton<String>(
                  value: voiceService.currentContext,
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                    DropdownMenuItem(value: 'retailer', child: Text('Retailer')),
                  ],
                  onChanged: (value) {
                    if (value != null) voiceService.setContext(value);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Command history
            if (voiceService.voiceCommandHistory.isNotEmpty) ...[
              const Text(
                'Recent Commands',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: min(5, voiceService.voiceCommandHistory.length),
                  itemBuilder: (context, index) {
                    final command = voiceService.voiceCommandHistory[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 16),
                      title: Text(
                        command,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => voiceService.clearHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Clear History'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Floating Voice Button for easy access
class FloatingVoiceButton extends StatelessWidget {
  final String userType;
  final Function(String)? onCommandRecognized;
  
  const FloatingVoiceButton({
    Key? key,
    required this.userType,
    this.onCommandRecognized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceService>(
      builder: (context, voiceService, child) {
        return Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: voiceService.isListening 
                ? voiceService.stopListening 
                : voiceService.startListening,
            backgroundColor: voiceService.isListening ? Colors.red : Colors.green,
            child: Icon(
              voiceService.isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 30,
            ),
          ),
        );
      },
    );
  }
}

