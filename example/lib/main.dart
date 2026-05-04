import 'package:flutter/material.dart';
import 'package:secure_screen_guard/secure_screen_guard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureScreenGuard Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SecurityMode _mode = SecurityMode.balanced;
  final List<String> _log = [];

  void _addLog(String message) {
    setState(() => _log.insert(0, '[${TimeOfDay.now().format(context)}] $message'));
  }

  @override
  void initState() {
    super.initState();
    // Global event listeners (useful for analytics/logging).
    SecureScreenGuard.onScreenshot
        .listen((_) => _addLog('📸 Screenshot detected'));
    SecureScreenGuard.onRecordingStart
        .listen((_) => _addLog('🔴 Recording started'));
    SecureScreenGuard.onRecordingStop
        .listen((_) => _addLog('⬛ Recording stopped'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SecureScreenGuard Demo')),
      body: Column(
        children: [
          // ── Mode selector ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<SecurityMode>(
                  value: _mode,
                  items: SecurityMode.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                      .toList(),
                  onChanged: (m) {
                    if (m == null) return;
                    setState(() => _mode = m);
                    SecureScreenGuard.setMode(m);
                  },
                ),
              ],
            ),
          ),

          // ── Sensitive content example ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SecureScreen(
              blurOnRecording: true,
              blurOnScreenshot: true,
              enabled: _mode != SecurityMode.off,
              onScreenshot: () => _addLog('Widget: screenshot callback'),
              onRecordingStart: () => _addLog('Widget: recording started'),
              onRecordingStop: () => _addLog('Widget: recording stopped'),
              child: Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Icon(Icons.credit_card, size: 48, color: Colors.indigo),
                      SizedBox(height: 12),
                      Text(
                        'Sensitive Payment Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Card: •••• •••• •••• 4242'),
                      Text('CVV: •••'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Manual controls ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    SecureScreenGuard.enable();
                    _addLog('Protection enabled globally');
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text('Enable'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    SecureScreenGuard.disable();
                    _addLog('Protection disabled globally');
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Disable'),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Event log ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Event Log',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(
            child: _log.isEmpty
                ? const Center(child: Text('No events yet. Take a screenshot!'))
                : ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(_log[i], style: const TextStyle(fontSize: 13)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
