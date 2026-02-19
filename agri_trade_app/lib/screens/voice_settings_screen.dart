import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../widgets/voice_assistant_widget.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navigation_helper.dart';
import '../widgets/app_gradient_scaffold.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VoiceSettingsScreenState createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Settings', // Should be localized if possible
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.help, color: Colors.white),
                  onPressed: () => Provider.of<VoiceService>(context, listen: false)
                      .provideHelp('general'),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          Consumer<VoiceService>(
            builder: (context, voiceService, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voice Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration.copyWith(
                      color: voiceService.isVoiceEnabled 
                          ? AppTheme.primaryGreen.withOpacity(0.05)
                          : AppTheme.errorRed.withOpacity(0.05),
                      border: Border.all(
                        color: voiceService.isVoiceEnabled 
                            ? AppTheme.primaryGreen.withOpacity(0.3)
                            : AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            voiceService.isVoiceEnabled 
                                ? Icons.mic 
                                : Icons.mic_off,
                            color: voiceService.isVoiceEnabled 
                                ? AppTheme.primaryGreen
                                : AppTheme.errorRed,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voiceService.isVoiceEnabled 
                                    ? 'Voice Active' 
                                    : 'Voice Disabled',
                                style: AppTheme.headingSmall.copyWith(
                                  color: voiceService.isVoiceEnabled 
                                      ? AppTheme.primaryGreen
                                      : AppTheme.errorRed,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                voiceService.isVoiceEnabled 
                                    ? 'Tap microphone to speak'
                                    : 'Enable to use voice commands',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: voiceService.isVoiceEnabled,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (value) => voiceService.toggleVoiceEnabled(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Configuration', style: AppTheme.headingSmall),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingRow(
                          'Language',
                          Row(
                            children: [
                              _buildLangOption('English', 'en', voiceService),
                              const SizedBox(width: 8),
                              _buildLangOption('తెలుగు', 'te', voiceService),
                            ],
                          ),
                        ),
                        Divider(height: 32, color: Colors.grey.withOpacity(0.1)),
                        _buildSettingRow(
                          'Role Context',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildContextChip('General', 'general', Icons.public, voiceService),
                              _buildContextChip('Farmer', 'farmer', Icons.agriculture, voiceService),
                              _buildContextChip('Retailer', 'retailer', Icons.store, voiceService),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tools Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Tools', style: AppTheme.headingSmall),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Training Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Practice voice commands with feedback'),
                          trailing: Switch(
                            value: voiceService.isTrainingMode,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) => value 
                                ? voiceService.startTrainingMode()
                                : voiceService.stopTrainingMode(),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Clear Offline Cache', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Remove stored offline data'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.secondaryAmber),
                            onPressed: () => _showClearCacheDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (voiceService.isTrainingMode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Training Mode active. Try speaking commands to test recognition accuracy.',
                              style: AppTheme.bodySmall.copyWith(color: Colors.blue[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  // Voice Assistant Test Area
                  Center(
                    child: VoiceAssistantWidget(
                      userType: voiceService.currentContext,
                      onCommandRecognized: (command) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Recognized: $command'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      showVisualFeedback: true,
                      showAdvancedControls: false,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildLangOption(String label, String code, VoiceService service) {
    final isSelected = service.currentLanguage == code;
    return GestureDetector(
      onTap: () => service.setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContextChip(String label, String context, IconData icon, VoiceService service) {
    final isSelected = service.currentContext == context;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) service.setContext(context);
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Delete all offline data? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && mounted) {
      // ignore: use_build_context_synchronously
      final offlineService = Provider.of<OfflineService>(context, listen: false);
      await offlineService.clearAllOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline data cleared'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    }
  }
}

