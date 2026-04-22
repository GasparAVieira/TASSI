import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class FAQTabContent extends StatefulWidget {
  const FAQTabContent({super.key});

  @override
  State<FAQTabContent> createState() => _FAQTabContentState();
}

class _FAQTabContentState extends State<FAQTabContent> {
  Future<List<dynamic>>? _faqsFuture;
  final Map<int, ExpansibleController> _controllers = {};
  Locale? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context);
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _faqsFuture = _loadFaqs(newLocale.languageCode);
    }
  }

  Future<List<dynamic>> _loadFaqs(String langCode) async {
    final String response = await rootBundle.loadString('assets/data/faqs_$langCode.json');
    return json.decode(response);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
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
                  l10n.faq,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  l10n.faqSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<dynamic>>(
              future: _faqsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading FAQs: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No FAQs found.'));
                }

                final faqs = snapshot.data!;
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: faqs.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final dynamic faq = entry.value;
                      final bool isLast = idx == faqs.length - 1;
                      final controller = _controllers.putIfAbsent(idx, () => ExpansibleController());

                      return Column(
                        children: [
                          Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              controller: controller,
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  // Close all other tiles
                                  for (var key in _controllers.keys) {
                                    if (key != idx) {
                                      _controllers[key]?.collapse();
                                    }
                                  }
                                }
                              },
                              title: Text(
                                faq['q']!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              children: [
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    faq['a']!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
