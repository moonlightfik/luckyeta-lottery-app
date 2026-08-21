import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
  });

  @override
  State<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState
    extends State<AccountSettingsPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool notificationsEnabled = true;
  bool soundEnabled = true;

  String selectedTheme = 'System';
  String selectedLanguage = 'English';

  bool isLoading = true;

  DocumentReference<Map<String, dynamic>>? get settingsRef {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    final ref = settingsRef;

    if (ref == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          notificationsEnabled =
              data['notificationsEnabled'] ?? true;

          soundEnabled =
              data['soundEnabled'] ?? true;

          selectedTheme =
              data['theme'] ?? 'System';

          selectedLanguage =
              data['language'] ?? 'English';
        }
      } else {
        await ref.set({
          'notificationsEnabled': true,
          'soundEnabled': true,
          'theme': 'System',
          'language': 'English',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error loading account settings: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> _saveSettings() async {
    final ref = settingsRef;

    if (ref == null) {
      return;
    }

    try {
      await ref.set(
        {
          'notificationsEnabled':
              notificationsEnabled,
          'soundEnabled': soundEnabled,
          'theme': selectedTheme,
          'language': selectedLanguage,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      debugPrint(
        'Error saving account settings: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _changeNotifications(
    bool value,
  ) async {
    setState(() {
      notificationsEnabled = value;
    });

    await _saveSettings();
  }

  // ============================================================
  // SOUND
  // ============================================================

  Future<void> _changeSound(
    bool value,
  ) async {
    setState(() {
      soundEnabled = value;
    });

    await _saveSettings();
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<void> _selectTheme() async {
    final result =
        await showModalBottomSheet<String>(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              _themeOption(
                'System',
                Icons.settings_suggest,
              ),

              _themeOption(
                'Light',
                Icons.light_mode,
              ),

              _themeOption(
                'Dark',
                Icons.dark_mode,
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedTheme = result;
    });

    await _saveSettings();
  }

  Widget _themeOption(
    String theme,
    IconData icon,
  ) {
    final selected =
        selectedTheme == theme;

    return ListTile(
      leading: Icon(
        icon,
        color:
            selected ? Colors.green : null,
      ),
      title: Text(theme),
      trailing: selected
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : null,
      onTap: () {
        Navigator.pop(
          context,
          theme,
        );
      },
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> _selectLanguage() async {
    final result =
        await showModalBottomSheet<String>(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Choose Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              _languageOption(
                'English',
              ),

              _languageOption(
                'Amharic',
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedLanguage = result;
    });

    await _saveSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$result selected.',
        ),
      ),
    );
  }

  Widget _languageOption(
    String language,
  ) {
    final selected =
        selectedLanguage == language;

    return ListTile(
      leading: const Icon(
        Icons.language,
      ),
      title: Text(language),
      trailing: selected
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : null,
      onTap: () {
        Navigator.pop(
          context,
          language,
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LuckyEta',
      applicationVersion: '1.0.2',
      applicationIcon:
          const Icon(
        Icons.confirmation_number,
        color: Colors.green,
        size: 40,
      ),
      children: const [
        Text(
          'LuckyEta is a lottery platform '
          'where users can discover lotteries, '
          'purchase tickets and participate in '
          'draws.',
        ),
        SizedBox(height: 12),
        Text(
          'Eta means fate — your lucky moment '
          'could be waiting for you. 🍀',
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Settings',
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                // ==================================================
                // NOTIFICATIONS
                // ==================================================

                _sectionTitle(
                  'PREFERENCES',
                ),

                _settingsCard(
                  children: [
                    SwitchListTile(
                      secondary:
                          const Icon(
                        Icons.notifications_outlined,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Notifications',
                      ),
                      subtitle: const Text(
                        'Receive LuckyEta notifications',
                      ),
                      value:
                          notificationsEnabled,
                      activeColor:
                          Colors.green,
                      onChanged:
                          _changeNotifications,
                    ),

                    const Divider(
                      height: 1,
                    ),

                    SwitchListTile(
                      secondary:
                          const Icon(
                        Icons.volume_up_outlined,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Sound',
                      ),
                      subtitle: const Text(
                        'Play sounds for app notifications',
                      ),
                      value: soundEnabled,
                      activeColor:
                          Colors.green,
                      onChanged:
                          _changeSound,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // APPEARANCE
                // ==================================================

                _sectionTitle(
                  'APPEARANCE',
                ),

                _settingsCard(
                  children: [
                    ListTile(
                      leading:
                          const Icon(
                        Icons.palette_outlined,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Theme',
                      ),
                      subtitle: Text(
                        selectedTheme,
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size: 16,
                      ),
                      onTap:
                          _selectTheme,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LANGUAGE
                // ==================================================

                _sectionTitle(
                  'LANGUAGE',
                ),

                _settingsCard(
                  children: [
                    ListTile(
                      leading:
                          const Icon(
                        Icons.language,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Language',
                      ),
                      subtitle: Text(
                        selectedLanguage,
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size: 16,
                      ),
                      onTap:
                          _selectLanguage,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // ABOUT
                // ==================================================

                _sectionTitle(
                  'ABOUT',
                ),

                _settingsCard(
                  children: [
                    ListTile(
                      leading:
                          const Icon(
                        Icons.info_outline,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'About LuckyEta',
                      ),
                      subtitle:
                          const Text(
                        'Version 1.0.2',
                      ),
                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios,
                        size: 16,
                      ),
                      onTap:
                          _showAbout,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ==================================================
                // INFO
                // ==================================================

                Center(
                  child: Text(
                    'LuckyEta • Your Fate, Your Chance 🍀',
                    style: TextStyle(
                      color:
                          Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight:
              FontWeight.bold,
          fontSize: 13,
          letterSpacing: .5,
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

