import 'dart:ui';

class ChangeLogStrings {
  final String title1;
  final String desc1;
  final String desc1Item1;
  final String desc1Item2;
  final String title2;
  final String desc2;
  final String title3;
  final String desc3;
  final String title4;
  final String desc4;

  const ChangeLogStrings({
    required this.title1,
    required this.desc1,
    this.desc1Item1 = '',
    this.desc1Item2 = '',
    this.title2 = '',
    this.desc2 = '',
    this.title3 = '',
    this.desc3 = '',
    this.title4 = '',
    this.desc4 = '',
  });

  bool get hasVisibleEntries =>
      title1.trim().isNotEmpty ||
      desc1.trim().isNotEmpty ||
      desc1Item1.trim().isNotEmpty ||
      desc1Item2.trim().isNotEmpty ||
      title2.trim().isNotEmpty ||
      desc2.trim().isNotEmpty ||
      title3.trim().isNotEmpty ||
      desc3.trim().isNotEmpty ||
      title4.trim().isNotEmpty ||
      desc4.trim().isNotEmpty;

  static ChangeLogStrings? maybeForLocale(
    Locale locale, {
    bool isOffline = false,
  }) {
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final translations = isOffline ? _offlineTranslations : _translations;
    final strings = translations[key] ??
        translations[locale.languageCode] ??
        translations['en'];

    if (strings == null || !strings.hasVisibleEntries) {
      return null;
    }
    return strings;
  }

  static bool hasContentForLocale(
    Locale locale, {
    bool isOffline = false,
  }) {
    return maybeForLocale(
          locale,
          isOffline: isOffline,
        ) !=
        null;
  }

  static const Map<String, ChangeLogStrings> _translations = {
    'en': ChangeLogStrings(
      title1: 'Photos experience',
      desc1:
          'Photos and videos now download faster, making the app feel quicker overall.',
      title2: 'Memories load faster',
      desc2:
          'Rediscovering old memories should now feel smoother thanks to under-the-hood performance improvements.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Prohlížení fotek',
      desc1:
          'Fotky a videa se teď stahují rychleji, takže celá aplikace působí svižněji.',
      title2: 'Vzpomínky se načítají rychleji',
      desc2:
          'Znovuobjevování starých vzpomínek by teď mělo být plynulejší díky vylepšením výkonu na pozadí.',
    ),
    'de': ChangeLogStrings(
      title1: 'Fotoerlebnis',
      desc1:
          'Fotos und Videos werden jetzt schneller heruntergeladen, sodass sich die App insgesamt schneller anfühlt.',
      title2: 'Erinnerungen laden schneller',
      desc2:
          'Das Wiederentdecken alter Erinnerungen sollte sich dank Leistungsverbesserungen im Hintergrund jetzt flüssiger anfühlen.',
    ),
    'es': ChangeLogStrings(
      title1: 'Experiencia con fotos',
      desc1:
          'Las fotos y los videos ahora se descargan más rápido, haciendo que la app se sienta más ágil en general.',
      title2: 'Los recuerdos cargan más rápido',
      desc2:
          'Redescubrir recuerdos antiguos ahora debería sentirse más fluido gracias a mejoras de rendimiento internas.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Expérience photos',
      desc1:
          'Les photos et vidéos se téléchargent désormais plus vite, ce qui rend l\'application globalement plus réactive.',
      title2: 'Les souvenirs se chargent plus vite',
      desc2:
          'Redécouvrir d\'anciens souvenirs devrait maintenant être plus fluide grâce à des améliorations de performance en coulisses.',
    ),
    'it': ChangeLogStrings(
      title1: 'Esperienza foto',
      desc1:
          'Foto e video ora vengono scaricati più velocemente, rendendo l\'app complessivamente più rapida.',
      title2: 'I ricordi si caricano più velocemente',
      desc2:
          'Riscoprire vecchi ricordi dovrebbe ora risultare più fluido grazie a miglioramenti delle prestazioni dietro le quinte.',
    ),
    'ja': ChangeLogStrings(
      title1: '写真体験',
      desc1: '写真や動画のダウンロードがより速くなり、アプリ全体がより軽快に感じられるようになりました。',
      title2: '思い出の読み込みが高速化',
      desc2: '内部のパフォーマンス改善により、昔の思い出をよりスムーズに振り返れるようになりました。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Foto-ervaring',
      desc1:
          'Foto\'s en video\'s worden nu sneller gedownload, waardoor de app in het algemeen sneller aanvoelt.',
      title2: 'Herinneringen laden sneller',
      desc2:
          'Oude herinneringen herontdekken zou nu soepeler moeten aanvoelen dankzij prestatieverbeteringen achter de schermen.',
    ),
    'no': ChangeLogStrings(
      title1: 'Fotoopplevelse',
      desc1:
          'Bilder og videoer lastes nå ned raskere, slik at appen føles raskere totalt sett.',
      title2: 'Minner lastes raskere',
      desc2:
          'Det skal nå føles jevnere å gjenoppdage gamle minner takket være ytelsesforbedringer under panseret.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Korzystanie ze zdjęć',
      desc1:
          'Zdjęcia i filmy pobierają się teraz szybciej, dzięki czemu cała aplikacja działa sprawniej.',
      title2: 'Wspomnienia ładują się szybciej',
      desc2:
          'Ponowne odkrywanie dawnych wspomnień powinno być teraz płynniejsze dzięki wewnętrznym usprawnieniom wydajności.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Experiência com fotos',
      desc1:
          'Fotos e vídeos agora baixam mais rápido, deixando o app mais ágil como um todo.',
      title2: 'Memórias carregam mais rápido',
      desc2:
          'Redescobrir memórias antigas agora deve ser mais fluido graças a melhorias internas de desempenho.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Experiência de fotografias',
      desc1:
          'As fotografias e os vídeos são agora transferidos mais rapidamente, tornando a aplicação mais ágil no geral.',
      title2: 'As memórias carregam mais depressa',
      desc2:
          'Redescobrir memórias antigas deverá agora ser mais fluido graças a melhorias internas de desempenho.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Experiența cu fotografii',
      desc1:
          'Fotografiile și videoclipurile se descarcă acum mai rapid, făcând aplicația să pară mai rapidă în ansamblu.',
      title2: 'Amintirile se încarcă mai repede',
      desc2:
          'Redescoperirea amintirilor vechi ar trebui să fie acum mai fluidă datorită îmbunătățirilor de performanță din culise.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Работа с фото',
      desc1:
          'Фотографии и видео теперь загружаются быстрее, поэтому приложение в целом ощущается более быстрым.',
      title2: 'Воспоминания загружаются быстрее',
      desc2:
          'Возвращаться к старым воспоминаниям теперь должно быть плавнее благодаря внутренним улучшениям производительности.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Fotoğraf deneyimi',
      desc1:
          'Fotoğraflar ve videolar artık daha hızlı indiriliyor, böylece uygulama genel olarak daha hızlı hissettiriyor.',
      title2: 'Anılar daha hızlı yükleniyor',
      desc2:
          'Arka plandaki performans iyileştirmeleri sayesinde eski anıları yeniden keşfetmek artık daha akıcı olmalı.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Робота з фото',
      desc1:
          'Фотографії та відео тепер завантажуються швидше, тож застосунок загалом відчувається швидшим.',
      title2: 'Спогади завантажуються швидше',
      desc2:
          'Повертатися до старих спогадів тепер має бути плавніше завдяки внутрішнім покращенням продуктивності.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Trải nghiệm ảnh',
      desc1:
          'Ảnh và video giờ tải xuống nhanh hơn, giúp toàn bộ ứng dụng có cảm giác nhanh hơn.',
      title2: 'Kỷ niệm tải nhanh hơn',
      desc2:
          'Việc khám phá lại các kỷ niệm cũ giờ sẽ mượt mà hơn nhờ những cải thiện hiệu năng bên trong.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '照片体验',
      desc1: '照片和视频现在下载更快，让整个应用用起来更加流畅。',
      title2: '回忆加载更快',
      desc2: '得益于底层性能改进，重温旧回忆现在应该会更加顺畅。',
    ),
  };

  static const Map<String, ChangeLogStrings> _offlineTranslations = {};
}
