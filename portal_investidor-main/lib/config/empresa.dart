/// Os contactos da Cleveroption, os mesmos do site (lib/data.ts, COMPANY).
///
/// Estão escritos à mão porque a API não os devolve. Ficam aqui num sítio só:
/// usa-os o ecrã de contactos e a ficha da fração. Se mudarem no site, mudam
/// aqui.
class Empresa {
  Empresa._();

  static const String telefone = '+351912923952';
  static const String telefoneVisivel = '+351 912 923 952';

  /// O número para o wa.me, sem "+" nem espaços. É o mesmo do telefone.
  static const String numeroWhatsapp = '351912923952';
  static const String whatsapp = 'https://wa.me/$numeroWhatsapp';

  static const String email = 'geral@cleveroption.pt';
  static const String morada =
      'Via Eng. Edgar Cardoso 23, 5.º D, Vila Nova de Gaia';

  /// O endereço público do site (o SITE_URL do site), para os links que se
  /// partilham — por exemplo o de uma fração.
  static const String site = 'https://www.cleveroption.pt';
}
