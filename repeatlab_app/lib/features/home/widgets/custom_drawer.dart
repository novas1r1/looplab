import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/features/home/dataprotection_page.dart';
import 'package:repeatlab/features/home/legal_notices_page.dart';
import 'package:repeatlab/features/paywall/cubits/paywall_cubit.dart';
import 'package:wiredash/wiredash.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appVersion = context.read<PackageInfo>().version;
    final buildNumber = context.read<PackageInfo>().buildNumber;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RepeatLab',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Music Loop Station',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'User Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          FutureBuilder(
            future: context.read<PaywallCubit>().hasUserPurched(),
            initialData: false,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return snapshot.data == true
                  ? ListTile(
                      leading: const Icon(Icons.free_cancellation),
                      title: const Text('Cancel Subscription'),
                      onTap: () {
                        context.read<PaywallCubit>().cancelSubscription();
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Buy RepeatLab Pro'),
            onTap: () {
              context.read<PaywallCubit>().showPaywall();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Improve the app',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback/Bugs'),
            onTap: () {
              Wiredash.of(context).show(inheritMaterialTheme: true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            onTap: () async {
              await DialogHelper.displayRateAppDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Legals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Data Protection'),
            onTap: () {
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataprotectionPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Legal Notices'),
            onTap: () {
              Navigator.pop(context);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LegalNoticesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Licenses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LicensePage(
                    applicationName: 'RepeatLab',
                    applicationVersion: appVersion,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version $appVersion ($buildNumber)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
