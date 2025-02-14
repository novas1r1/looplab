import 'package:dart_mappable/dart_mappable.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_element.dart';

part 'changelog_version.mapper.dart';

@MappableClass()
class ChangelogVersion with ChangelogVersionMappable {
  final String version;
  final DateTime releaseDate;
  final List<ChangelogElement> updates;

  const ChangelogVersion({
    required this.version,
    required this.releaseDate,
    required this.updates,
  });
}
