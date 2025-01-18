import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = context.read<PackageInfo>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Licenses'),
      ),
      body: LicensePage(
        applicationName: 'RepeatLab',
        applicationVersion: packageInfo.version,
        applicationIcon: Image.asset('assets/icons/icon.png'),
      ),
    );
  }
}
