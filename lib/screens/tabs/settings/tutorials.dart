import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/services.dart';
import '../../../../widgets/widgets.dart';

/// Shows audio tutorial in a tall bottom sheet
void _showAudioTutorialBottomSheet({
  required BuildContext context,
  required ThemeProvider theme,
  required String title,
  required IconData icon,
}) {
  VibrationService.mediumFeedback();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8, // Taller than other bottom sheets
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 10,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Down arrow button at top center
              Center(
                child: GestureDetector(
                  onTap: () {
                    VibrationService.mediumFeedback();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 48,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: theme.fontSize + 12,
                    color: theme.buttonTextColor,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: theme.fontSize + 8,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Placeholder for audio player
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 100,
                        color: theme.buttonTextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Audio tutorial coming soon',
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          color: theme.buttonTextColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tutorials screen with guidance on using Solari glasses
class TutorialsScreen extends StatefulWidget {
  /// Creates a tutorials screen
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  bool _isReady = false;
  
  // Track which text sections are expanded
  final Map<String, bool> _expandedSections = {
    'connecting': false,
    'capabilities': false,
    'features': false,
    'text_format': false,
    'speech': false,
    'screen_reader': false,
    'select_to_speak': false,
    'magnification': false,
    'voice_assist': false,
    'color_inversion': false,
    'high_contrast': false,
    'vibration': false,
    'system_sync': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('tutorials');
        // Delay body content registration to let app bar register first
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isReady = true;
            });
            // Then focus the first element (back button)
            if (ScreenReaderService().isEnabled) {
              Future.delayed(const Duration(milliseconds: 200), () {
                ScreenReaderService().focusNext();
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    ScreenReaderService().clearContextNodes('tutorials');
    super.dispose();
  }

  /// Helper method to get text shadows for high contrast mode
  static List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;
    final shadowColor = theme.isDarkMode ? Colors.white : Colors.black;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: shadowColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Tutorials", 
        showBackButton: true,
        screenReaderContext: 'tutorials',
      ),
      body: ScreenReaderGestureDetector(
        child: !_isReady
          ? const SizedBox.shrink()
          : GestureDetector(
          onTap: () {
            clearSelectToSpeakSelection();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Section
                    _buildSectionHeader(theme, Icons.video_library, 'Video'),
                    const SizedBox(height: 10),
                    ScreenReaderFocusable(
                      context: 'tutorials',
                      label: 'Video tutorial placeholder',
                      hint: 'Video tutorial coming soon',
                      child: const Placeholder(fallbackHeight: 200),
                    ),
                    const SizedBox(height: 30),

                    // Audio Section
                    _buildSectionHeader(theme, Icons.headphones, 'Audio'),
                    const SizedBox(height: 10),
                    _buildAudioGrid(theme),
                    const SizedBox(height: 30),

                    // Text Section
                    _buildSectionHeader(theme, Icons.article, 'Text'),
                    const SizedBox(height: 10),
                    
                    // Expandable sections
                    _buildExpandableSection(
                      theme,
                      'connecting',
                      'Connecting with Solari',
                      'To get started with your smart glasses, first connect them via Bluetooth. Navigate to the Settings tab, then select Device Status to pair your Solari glasses. Once connected, you can begin using all the features.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'capabilities',
                      'Solari Capabilities',
                      'Solari smart glasses offer vision assistance, voice interaction, and real-time information. You can ask questions, get descriptions of your surroundings, read text, and receive audio guidance for navigation.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'features',
                      'Solari App Features',
                      'The app includes Chat Input for voice interaction, History for reviewing past conversations, and Settings for customizing your experience. Access tutorials, FAQs, and support through the Help section.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'text_format',
                      'Accessibility: Text Format',
                      'Customize the text display with adjustable font size and line spacing. Choose between light and dark themes, and enable high contrast mode for better visibility. These settings ensure comfortable reading for all users.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'speech',
                      'Accessibility: Speech Settings',
                      'Adjust voice speed and pitch to your preference. Control the rate at which text is read aloud and modify the voice characteristics to match your listening comfort. These settings apply to all audio feedback.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'screen_reader',
                      'Accessibility: Screen Reader',
                      'Enable Screen Reader for audio navigation guidance. Use swipe gestures to move between elements: swipe right to go forward, swipe left to go back, and double-tap to activate. The screen reader announces each element as you navigate.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'select_to_speak',
                      'Accessibility: Select to Speak',
                      'Tap any text on the screen to have it read aloud. This feature allows you to selectively hear content without navigating through all elements. Tapped text is highlighted until you select another item.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'magnification',
                      'Accessibility: Magnification',
                      'Enable magnification to zoom in on any part of the screen. Use pinch gestures to zoom in and out, and drag to pan across the magnified view. This helps users with low vision see content more clearly.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'voice_assist',
                      'Accessibility: Voice Assist',
                      'Voice Assist provides hands-free control of the application. Use voice commands to navigate, activate features, and interact with content. This feature is especially useful when your hands are occupied.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'color_inversion',
                      'Accessibility: Color Inversion',
                      'Color Inversion reverses the display colors to reduce eye strain and improve readability. This feature swaps light backgrounds with dark ones and vice versa, making it easier to read in different lighting conditions or for users with light sensitivity.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'high_contrast',
                      'Accessibility: High Contrast',
                      'High Contrast mode enhances text visibility by adding bold shadows around text. This makes content easier to read against any background, especially beneficial for users with low vision or in bright lighting conditions.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'vibration',
                      'Accessibility: Vibration',
                      'Enable haptic feedback to receive physical vibrations when interacting with buttons and controls. This tactile response helps confirm actions and provides an additional sensory cue for navigation, useful for users who benefit from non-visual feedback.',
                    ),
                    _buildExpandableSection(
                      theme,
                      'system_sync',
                      'Accessibility: System Sync',
                      'System Sync automatically matches the app\'s theme and settings to your device\'s system preferences. When enabled, the app will adopt your device\'s dark mode, font size, and other accessibility settings for a consistent experience across all apps.',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader(ThemeProvider theme, IconData icon, String title) {
    return ScreenReaderFocusable(
      context: 'tutorials',
      label: '$title section',
      hint: title,
      child: Row(
        children: [
          Icon(
            icon,
            size: theme.fontSize + 12,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 12),
          Semantics(
            header: true,
            child: SelectToSpeakText(
              title, 
              style: TextStyle(
                fontSize: theme.fontSize + 8,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
                shadows: _getTextShadows(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioGrid(ThemeProvider theme) {
    final items = [
      {'label': 'Using Solari', 'icon': Icons.smart_toy_outlined},
      {'label': 'Accessibility Features', 'icon': Icons.accessibility_new},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ScreenReaderFocusable(
          context: 'tutorials',
          label: '${item['label']} audio tutorial',
          hint: 'Double tap to play ${item['label']} audio tutorial',
          onTap: () {
            _showAudioTutorialBottomSheet(
              context: context,
              theme: theme,
              title: item['label'] as String,
              icon: item['icon'] as IconData,
            );
          },
          child: FeatureCard(
            theme: theme,
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            onTap: () {
              _showAudioTutorialBottomSheet(
                context: context,
                theme: theme,
                title: item['label'] as String,
                icon: item['icon'] as IconData,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpandableSection(
    ThemeProvider theme,
    String key,
    String title,
    String content,
  ) {
    final isExpanded = _expandedSections[key] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenReaderFocusable(
          context: 'tutorials',
          label: '$title, ${isExpanded ? 'expanded' : 'collapsed'}',
          hint: 'Double tap to ${isExpanded ? 'collapse' : 'expand'}',
          onTap: () {
            VibrationService.mediumFeedback();
            setState(() {
              _expandedSections[key] = !isExpanded;
            });
          },
          child: InkWell(
            onTap: () {
              VibrationService.mediumFeedback();
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.buttonTextColor,
                    size: theme.fontSize + 4,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectToSpeakText(
                      title,
                      style: TextStyle(
                        fontSize: theme.fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: ScreenReaderFocusable(
              context: 'tutorials',
              label: '$title content',
              hint: content,
              child: SelectToSpeakText(
                content,
                style: TextStyle(
                  fontSize: theme.fontSize,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

