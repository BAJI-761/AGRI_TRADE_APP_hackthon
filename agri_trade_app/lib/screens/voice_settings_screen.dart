import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../widgets/voice_assistant_widget.dart';
import '../services/offline_service.dart';
import '../widgets/navigation_helper.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  _VoiceSettingsScreenState createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: 'Voice Settings',
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.help),
              onPressed: () => Provider.of<VoiceService>(context, listen: false)
                  .provideHelp('general'),
            ),
          ],
        ),
      body: Consumer<VoiceService>(
        builder: (context, voiceService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voice Status Card
                Card(
                  color: voiceService.isVoiceEnabled 
                      ? Colors.green[50] 
                      : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          voiceService.isVoiceEnabled 
                              ? Icons.volume_up 
                              : Icons.volume_off,
                          color: voiceService.isVoiceEnabled 
                              ? Colors.green 
                              : Colors.red,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voiceService.isVoiceEnabled 
                                    ? 'Voice Features Enabled' 
                                    : 'Voice Features Disabled',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: voiceService.isVoiceEnabled 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                              Text(
                                voiceService.isVoiceEnabled 
                                    ? 'You can use voice commands to navigate the app'
                                    : 'Enable voice features to use voice commands',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: voiceService.isVoiceEnabled,
                          onChanged: (value) => voiceService.toggleVoiceEnabled(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // App Preferences
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Notifications (placeholder)'),
                            Switch(
                              value: true,
                              onChanged: (v) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications not implemented yet')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Clear Cache'),
                                    content: const Text('Clear offline cached data?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (!confirmed) return;
                            await Provider.of<OfflineService>(context, listen: false).clearAllOfflineData();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Offline data cleared')),
                            );
                          },
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Clear Offline Cache'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Language Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Language'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                voiceService.currentLanguage == 'en' ? 'English' : 'తెలుగు',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => voiceService.setLanguage('en'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: voiceService.currentLanguage == 'en' 
                                    ? Colors.blue 
                                    : Colors.grey[300],
                                foregroundColor: voiceService.currentLanguage == 'en' 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                              child: const Text('English'),
                            ),
                            ElevatedButton(
                              onPressed: () => voiceService.setLanguage('te'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: voiceService.currentLanguage == 'te' 
                                    ? Colors.blue 
                                    : Colors.grey[300],
                                foregroundColor: voiceService.currentLanguage == 'te' 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                              child: const Text('తెలుగు'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Context Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Context',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Set the context to get relevant voice commands for your role.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildContextButton(
                              'General',
                              'general',
                              Icons.public,
                              voiceService.currentContext == 'general',
                              voiceService,
                            ),
                            _buildContextButton(
                              'Farmer',
                              'farmer',
                              Icons.agriculture,
                              voiceService.currentContext == 'farmer',
                              voiceService,
                            ),
                            _buildContextButton(
                              'Retailer',
                              'retailer',
                              Icons.store,
                              voiceService.currentContext == 'retailer',
                              voiceService,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Training Mode
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Training Mode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Practice voice commands with feedback',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            Switch(
                              value: voiceService.isTrainingMode,
                              onChanged: (value) => value 
                                  ? voiceService.startTrainingMode()
                                  : voiceService.stopTrainingMode(),
                            ),
                          ],
                        ),
                        if (voiceService.isTrainingMode) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Training mode is active. Try different voice commands and get feedback on recognition accuracy.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Voice Assistant Widget
                const Text(
                  'Voice Assistant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Test your voice commands with the assistant below:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                
                VoiceAssistantWidget(
                  userType: voiceService.currentContext,
                  onCommandRecognized: (command) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Command recognized: $command'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  showVisualFeedback: true,
                  showAdvancedControls: false,
                ),
                
                const SizedBox(height: 20),
                
                // Command History
                if (voiceService.voiceCommandHistory.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Commands',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => voiceService.clearHistory(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: voiceService.voiceCommandHistory.length,
                              itemBuilder: (context, index) {
                                final command = voiceService.voiceCommandHistory[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(Icons.history, color: Colors.blue),
                                    title: Text(
                                      command,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildContextButton(
    String label,
    String context,
    IconData icon,
    bool isSelected,
    VoiceService voiceService,
  ) {
    return ElevatedButton.icon(
      onPressed: () => voiceService.setContext(context),
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
