import 'package:flutter/material.dart';

enum DeviceFilter { all, home, office, others }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.username = 'Sudhan'});

  final String username;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0; // 0 = Home, 1 = Profile
  DeviceFilter _filter = DeviceFilter.all;

  final List<_Device> _devices = const [
    _Device(name: 'Office Clock', subtitle: 'Eterna #025', place: 'Office'),
    _Device(name: 'Living Room Clock', subtitle: 'Eterna #101', place: 'Home'),
    _Device(name: 'Bedroom Clock', subtitle: 'Eterna #037', place: 'Home'),
    _Device(name: 'Reception Clock', subtitle: 'Eterna #502', place: 'Office'),
    _Device(name: 'Warehouse Clock', subtitle: 'Eterna #777', place: 'Others'),
  ];

  List<_Device> get _filtered {
    switch (_filter) {
      case DeviceFilter.home:
        return _devices.where((d) => d.place.toLowerCase() == 'home').toList();
      case DeviceFilter.office:
        return _devices.where((d) => d.place.toLowerCase() == 'office').toList();
      case DeviceFilter.others:
        return _devices.where((d) => d.place.toLowerCase() == 'others').toList();
      case DeviceFilter.all:
      default:
        return _devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Hello, ${widget.username} !'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _TopFilterBar(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = _filtered[index];
                return _DeviceCard(device: d);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          // For now both tabs show the same page; wire Profile to another page later.
        },
      ),
    );
  }
}

class _TopFilterBar extends StatelessWidget {
  const _TopFilterBar({required this.selected, required this.onChanged});

  final DeviceFilter selected;
  final ValueChanged<DeviceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    // Material 3 SegmentedButton for All/Home/Office/Others
    return SegmentedButton<DeviceFilter>(
      segments: const [
        ButtonSegment(value: DeviceFilter.all, label: Text('All Devices')),
        ButtonSegment(value: DeviceFilter.home, label: Text('Home')),
        ButtonSegment(value: DeviceFilter.office, label: Text('Office')),
        ButtonSegment(value: DeviceFilter.others, label: Text('Others')),
      ],
      selected: <DeviceFilter>{selected},
      onSelectionChanged: (newSet) {
        if (newSet.isNotEmpty) onChanged(newSet.first);
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final _Device device;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 110,
        child: Row(
          children: [
            // Placeholder image area
            Container(
              width: 120,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Icon(Icons.access_time, size: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(device.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(device.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.bluetooth, size: 16),
                      Chip(
                        label: Text(device.place),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Device {
  final String name;
  final String subtitle;
  final String place;
  const _Device({required this.name, required this.subtitle, required this.place});
}