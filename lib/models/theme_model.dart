import 'package:hive/hive.dart';

part 'theme_model.g.dart';

@HiveType(typeId: 6)
class ThemePreference extends HiveObject {
  @HiveField(0)
  final String mode;

  ThemePreference({required this.mode});
}
