import 'package:get/get.dart';

/// GetX translation class — wraps our ARB-based strings.
/// GetX needs key→value maps per language code.
/// We keep using the generated AppLocalizations for the actual strings,
/// so this class is a thin bridge that GetX requires to call Get.updateLocale().
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
    'en_US': {},
    'en': {},
    'am': {},
    'ti': {},
  };
}
