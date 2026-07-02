/// The three languages the app ships with. `label` is shown in the picker,
/// `code` is the short badge (EN / RU / UZ).
enum AppLanguage {
  en('English', 'EN'),
  ru('Русский', 'RU'),
  uz("O'zbekcha", 'UZ');

  const AppLanguage(this.label, this.code);

  final String label;
  final String code;
}
