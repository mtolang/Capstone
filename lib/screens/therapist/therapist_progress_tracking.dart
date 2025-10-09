import 'package:flutter/material.dart';
import 'package:kindora/widgets/mini_trend_line.dart';
import 'package:kindora/widgets/status_chip.dart';

class TherapistProgressTrackingPage extends StatelessWidget {
  const TherapistProgressTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width;
    final topCols = maxW > 1200 ? 4 : maxW > 800 ? 2 : 1;
    final midCols = maxW > 1100 ? 3 : 1;
    final bottomCols = maxW > 1100 ? 2 : 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: topCols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.2,
              children: [
                const _StatCard('Active Patients', '3', 'Currently under your care', Icons.favorite_outline),
                const _StatCard('Pending Reports', '3', 'Reports due this week', Icons.description_outlined),
                const _StatCard('Upcoming Sessions', '3', 'Next 3 days', Icons.event_available_outlined),
                const _StatCard('Avg Weekly Change', '+2.3%', 'Across all domains', Icons.trending_up),
              ],
            ),

            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: midCols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: const [
                _DomainCard('Motor', PatientStatus.onTrack, [1.0,2.0,2.5,2.6,3.0,3.2,3.4], '+11% over last 7 days'),
                _DomainCard('Speech', PatientStatus.watch, [1.5,1.6,1.7,1.7,1.9,2.1,2.3], '+8% over last 7 days'),
                _DomainCard('Cognitive', PatientStatus.needsAttention, [1.2,1.3,1.35,1.4,1.42,1.44,1.45], '+1% over last 7 days'),
                _DomainCard('Socio-emotional', PatientStatus.onTrack, [0.9,1.2,1.22,1.25,1.28,1.3,1.33], '+7% over last 7 days'),
                _UpcomingSessionsCard(),
              ],
            ),

            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: bottomCols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: const [
                _ActivePatientsTableCard(),
                _EngagementHeatmapCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title; final String value; final String subtitle; final IconData icon;
  const _StatCard(this.title, this.value, this.subtitle, this.icon);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(backgroundColor: Colors.indigo.withOpacity(0.08), child: Icon(icon, color: Colors.indigo)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 6),
            Row(children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final String title; final PatientStatus status; final List<double> trend; final String change;
  const _DomainCard(this.title, this.status, this.trend, this.change);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            StatusChip(status: status),
          ]),
          const SizedBox(height: 8),
          MiniTrendLine(data: trend, height: 72),
          const SizedBox(height: 8),
          Text(change, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ]),
      ),
    );
  }
}

class _UpcomingSessionsCard extends StatelessWidget {
  const _UpcomingSessionsCard();
  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Ava Santos', 'Teletherapy • 2025-09-27 at 10:00', 'Teletherapy'),
      ('Mia Garcia', 'In-person • 2025-09-28 at 14:30', 'In-person'),
      ('Liam Cruz', 'Teletherapy • 2025-09-29 at 09:15', 'Teletherapy'),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Upcoming Sessions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            IconButton(onPressed: (){}, icon: const Icon(Icons.more_horiz, color: Colors.grey))
          ]),
          const SizedBox(height: 8),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                CircleAvatar(child: Text(it.$1[0])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(it.$2, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: Text(it.$3, style: const TextStyle(fontSize: 12)))
              ]),
            ),
        ]),
      ),
    );
  }
}

class _ActivePatientsTableCard extends StatelessWidget { const _ActivePatientsTableCard();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Ava Santos', 7, 'ASD Level 1', 70, PatientStatus.onTrack),
      ('Liam Cruz', 6, 'ADHD Combined', 55, PatientStatus.watch),
      ('Mia Garcia', 8, 'Developmental Delay', 46, PatientStatus.needsAttention),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Active Patients', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: const [
              Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(child: Text('Age', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Overall', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 4),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(children: [
                Expanded(flex: 3, child: Text(r.$1)),
                Expanded(child: Text('${r.$2}')),
                Expanded(flex: 3, child: Text(r.$3)),
                Expanded(flex: 2, child: Row(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: r.$4/100, minHeight: 8, backgroundColor: Colors.grey.shade200))),
                  const SizedBox(width: 8), Text('${r.$4}%'),
                ])),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: StatusChip(status: r.$5))),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _EngagementHeatmapCard extends StatelessWidget { const _EngagementHeatmapCard();
  @override
  Widget build(BuildContext context) {
    final intensities = List.generate(7 * 7, (i) => (i % 7 + (i ~/ 7)) % 5);
    final colors = [
      Colors.indigo.shade50,
      Colors.indigo.shade100,
      Colors.indigo.shade200,
      Colors.indigo.shade300,
      Colors.indigo.shade400,
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Engagement Heatmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final i in intensities)
              Container(width: 22, height: 22, decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(4))),
          ]),
          const SizedBox(height: 12),
          Text('Green = frequent activity, light = skipped', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ]),
      ),
    );
  }
}
