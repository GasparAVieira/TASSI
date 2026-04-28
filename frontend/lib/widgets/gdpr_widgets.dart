import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class GDPRTabContent extends StatefulWidget {
  const GDPRTabContent({super.key});

  @override
  State<GDPRTabContent> createState() => _GDPRTabContentState();
}

class _GDPRTabContentState extends State<GDPRTabContent>
    with AutomaticKeepAliveClientMixin {
  Future<Map<String, dynamic>>? _gdprFuture;
  final Map<int, ExpansibleController> _controllers = {};
  Locale? _currentLocale;
  final SettingsService _settings = SettingsService();

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context);
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _gdprFuture = _loadGdprData(newLocale.languageCode);
    }
  }

  Future<Map<String, dynamic>> _loadGdprData(String langCode) async {
    final String response = await rootBundle.loadString('assets/data/gdpr_$langCode.json');
    return json.decode(response);
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _gdprFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error loading GDPR data: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No GDPR data found.'));
        }

        final data = snapshot.data!;
        final sections = data['sections'] as List<dynamic>;
        final dpo = data['dpo'] as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const FlutterLogo(size: 56.0),
                    title: Text(
                      data['headerTitle'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      data['headerSubtitle'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Accordion Card
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: sections.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final dynamic section = entry.value;
                      final bool isLast = idx == sections.length - 1;
                      final controller = _controllers.putIfAbsent(
                          idx, () => ExpansibleController());

                      return Column(
                        children: [
                          Theme(
                            data:
                                theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              controller: controller,
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  for (var key in _controllers.keys) {
                                    if (key != idx) {
                                      _controllers[key]?.collapse();
                                    }
                                  }
                                }
                              },
                              title: Text(
                                section['title'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (section['introText'] != null) ...[
                                        Text(
                                          section['introText'],
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      ...List<String>.from(section['items'])
                                          .map((item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 7.0),
                                                      child: Icon(Icons.circle,
                                                          size: 5,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: _RichItemText(item),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Action Buttons
                if (AuthScope.of(context).isLoggedIn)
                  ListenableBuilder(
                    listenable: _settings,
                    builder: (context, _) {
                      return Column(
                        children: [
                          FilledButton(
                            onPressed: () => _showSnackbar(context, data['exportRequestSuccess']),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(data['exportButton']),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => _showSnackbar(context, data['deletionRequestSuccess']),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(data['deletionButton']),
                          ),
                        ],
                      );
                    }
                  ),
                const SizedBox(height: 10),

                // DPO Info Card
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['dpoTitle'],
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${data['emailLabel']}: ${dpo['email']}',
                            style: theme.textTheme.bodyMedium),
                        Text('${data['phoneLabel']}: ${dpo['phone']}',
                            style: theme.textTheme.bodyMedium),
                        Text('${data['officeLabel']}: ${dpo['office']}',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RichItemText extends StatelessWidget {
  final String text;
  const _RichItemText(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colonIndex = text.indexOf(':');

    if (colonIndex != -1 && colonIndex < 35) {
      final key = text.substring(0, colonIndex + 1);
      final value = text.substring(colonIndex + 1);

      List<TextSpan> spans = [];
      spans.add(TextSpan(
        text: key,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      if (value.contains('phone (optional)')) {
        int start = value.indexOf('phone (optional)');
        spans.add(TextSpan(text: value.substring(0, start)));
        spans.add(const TextSpan(
          text: 'phone (optional)',
          style: TextStyle(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(
            text: value.substring(start + 'phone (optional)'.length)));
      } else {
        spans.add(TextSpan(text: value));
      }

      return RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurface),
          children: spans,
        ),
      );
    }

    if (text.contains('(anonymized)')) {
      int start = text.indexOf('(anonymized)');
      return RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurface),
          children: [
            TextSpan(text: text.substring(0, start)),
            const TextSpan(
              text: '(anonymized)',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            TextSpan(text: text.substring(start + '(anonymized)'.length)),
          ],
        ),
      );
    }

    return Text(text, style: theme.textTheme.bodyMedium);
  }
}
