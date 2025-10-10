import 'package:flutter/material.dart';
import '../services/game_data_service.dart';

class DatabaseOptimizationTool extends StatefulWidget {
  const DatabaseOptimizationTool({super.key});

  @override
  _DatabaseOptimizationToolState createState() =>
      _DatabaseOptimizationToolState();
}

class _DatabaseOptimizationToolState extends State<DatabaseOptimizationTool> {
  bool _isOptimizing = false;
  String _status = 'Ready to optimize database';
  List<String> _logs = [];

  Future<void> _runOptimization() async {
    setState(() {
      _isOptimizing = true;
      _status = 'Optimizing database...';
      _logs.clear();
    });

    try {
      // Add log function
      void addLog(String message) {
        setState(() {
          _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
        });
      }

      addLog('Starting database optimization...');

      // Run the optimization
      await GameDataService.optimizeUserGameData();

      addLog('✅ Optimization completed successfully!');
      addLog('💾 Database space has been optimized');

      setState(() {
        _status = 'Optimization completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error during optimization: $e';
        _logs.add('❌ Error: $e');
      });
    } finally {
      setState(() {
        _isOptimizing = false;
      });
    }
  }

  Future<void> _viewCurrentProgress() async {
    try {
      final progress = await GameDataService.getUserGameProgress();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Current Game Progress'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User ID: ${progress.userId}'),
                const SizedBox(height: 16),
                const Text('Game Levels:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...progress.gameProgress.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                          '${entry.key}: Level ${entry.value.currentLevel} (Best: ${entry.value.bestScore})'),
                    )),
                const SizedBox(height: 16),
                Text(
                    'Total Sessions: ${progress.totalSessions.values.fold(0, (a, b) => a + b)}'),
                Text(
                    'Last Played: ${progress.lastPlayed.toString().substring(0, 16)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Optimization'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Optimization',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will:\n'
                      '• Merge duplicate progress data\n'
                      '• Keep highest levels and best scores\n'
                      '• Remove old session documents\n'
                      '• Optimize database storage',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        color: _isOptimizing ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isOptimizing ? null : _runOptimization,
                    icon: _isOptimizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(
                        _isOptimizing ? 'Optimizing...' : 'Run Optimization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewCurrentProgress,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Optimization Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet. Run optimization to see progress.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
