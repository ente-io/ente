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
      title1: 'Smoother memories',
      desc1:
          'Rediscovering old memories feels better, with new haptics and under-the-hood improvements.',
      title2: 'Faster browsing',
      desc2:
          "Your photos and videos load faster. We've updated our infrastructure, so everything feels snappier.",
      title3: 'Better memory lane',
      desc3:
          'Memory lanes now appear for more people in your life, including kids 3 and up. Shared links load faster, with smoother animations.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Plynulejší vzpomínky',
      desc1:
          'Znovuobjevování starých vzpomínek je příjemnější díky nové haptické odezvě a vylepšením na pozadí.',
      title2: 'Rychlejší prohlížení',
      desc2:
          'Vaše fotky a videa se načítají rychleji. Aktualizovali jsme naši infrastrukturu, takže vše působí svižněji.',
      title3: 'Lepší memory lane',
      desc3:
          'Memory lane se nyní zobrazuje pro více lidí ve vašem životě, včetně dětí od 3 let. Sdílené odkazy se načítají rychleji a animace jsou plynulejší.',
    ),
    'de': ChangeLogStrings(
      title1: 'Flüssigere Erinnerungen',
      desc1:
          'Das Wiederentdecken alter Erinnerungen fühlt sich mit neuer Haptik und Verbesserungen im Hintergrund besser an.',
      title2: 'Schnelleres Browsen',
      desc2:
          'Ihre Fotos und Videos laden schneller. Wir haben unsere Infrastruktur aktualisiert, damit sich alles reaktionsschneller anfühlt.',
      title3: 'Bessere Memory Lane',
      desc3:
          'Memory Lanes erscheinen jetzt für mehr Menschen in Ihrem Leben, einschließlich Kindern ab 3 Jahren. Geteilte Links laden schneller und Animationen laufen flüssiger.',
    ),
    'es': ChangeLogStrings(
      title1: 'Recuerdos más fluidos',
      desc1:
          'Redescubrir recuerdos antiguos se siente mejor, con nuevas respuestas hápticas y mejoras internas.',
      title2: 'Navegación más rápida',
      desc2:
          'Tus fotos y videos cargan más rápido. Hemos actualizado nuestra infraestructura para que todo se sienta más ágil.',
      title3: 'Mejor memory lane',
      desc3:
          'Las memory lanes ahora aparecen para más personas en tu vida, incluidos niños de 3 años en adelante. Los enlaces compartidos cargan más rápido, con animaciones más fluidas.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Souvenirs plus fluides',
      desc1:
          'Redécouvrir d’anciens souvenirs est plus agréable, avec de nouvelles vibrations et des améliorations internes.',
      title2: 'Navigation plus rapide',
      desc2:
          'Vos photos et vidéos se chargent plus vite. Nous avons mis à jour notre infrastructure pour rendre l’ensemble plus réactif.',
      title3: 'Meilleure memory lane',
      desc3:
          'Les memory lanes apparaissent désormais pour davantage de personnes de votre vie, y compris les enfants de 3 ans et plus. Les liens partagés se chargent plus vite, avec des animations plus fluides.',
    ),
    'it': ChangeLogStrings(
      title1: 'Ricordi più fluidi',
      desc1:
          'Riscoprire vecchi ricordi è più piacevole, con nuovi feedback aptici e miglioramenti interni.',
      title2: 'Navigazione più veloce',
      desc2:
          'Le tue foto e i tuoi video si caricano più velocemente. Abbiamo aggiornato la nostra infrastruttura, così tutto risulta più reattivo.',
      title3: 'Memory lane migliorata',
      desc3:
          'Le memory lane ora appaiono per più persone nella tua vita, inclusi i bambini dai 3 anni in su. I link condivisi si caricano più rapidamente, con animazioni più fluide.',
    ),
    'ja': ChangeLogStrings(
      title1: 'よりスムーズな思い出',
      desc1: '新しい触覚フィードバックと内部改善により、昔の思い出を振り返る体験がより心地よくなりました。',
      title2: 'より速い閲覧',
      desc2: '写真や動画の読み込みが速くなりました。インフラを更新し、全体がより軽快に感じられます。',
      title3: 'より良いメモリーレーン',
      desc3:
          '3歳以上のお子さまを含め、より多くの大切な人のメモリーレーンが表示されるようになりました。共有リンクの読み込みも速くなり、アニメーションもよりスムーズです。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Soepelere herinneringen',
      desc1:
          'Oude herinneringen herontdekken voelt beter, met nieuwe haptiek en verbeteringen onder de motorkap.',
      title2: 'Sneller bladeren',
      desc2:
          'Je foto’s en video’s laden sneller. We hebben onze infrastructuur bijgewerkt, zodat alles vlotter aanvoelt.',
      title3: 'Betere memory lane',
      desc3:
          'Memory lanes verschijnen nu voor meer mensen in je leven, inclusief kinderen vanaf 3 jaar. Gedeelde links laden sneller, met soepelere animaties.',
    ),
    'no': ChangeLogStrings(
      title1: 'Jevnere minner',
      desc1:
          'Det føles bedre å gjenoppdage gamle minner, med ny haptikk og forbedringer under panseret.',
      title2: 'Raskere blaing',
      desc2:
          'Bildene og videoene dine lastes raskere. Vi har oppdatert infrastrukturen vår, slik at alt føles kvikkere.',
      title3: 'Bedre memory lane',
      desc3:
          'Memory lanes vises nå for flere personer i livet ditt, inkludert barn fra 3 år og oppover. Delte lenker lastes raskere, med jevnere animasjoner.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Płynniejsze wspomnienia',
      desc1:
          'Odkrywanie dawnych wspomnień jest przyjemniejsze dzięki nowym reakcjom haptycznym i ulepszeniom pod spodem.',
      title2: 'Szybsze przeglądanie',
      desc2:
          'Twoje zdjęcia i filmy ładują się szybciej. Zaktualizowaliśmy naszą infrastrukturę, więc wszystko działa sprawniej.',
      title3: 'Lepsza memory lane',
      desc3:
          'Memory lane pojawia się teraz dla większej liczby osób w Twoim życiu, w tym dzieci od 3. roku życia. Udostępnione linki ładują się szybciej, a animacje są płynniejsze.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Memórias mais suaves',
      desc1:
          'Redescobrir memórias antigas ficou melhor, com novos retornos táteis e melhorias internas.',
      title2: 'Navegação mais rápida',
      desc2:
          'Suas fotos e vídeos carregam mais rápido. Atualizamos nossa infraestrutura, então tudo fica mais ágil.',
      title3: 'Memory lane melhor',
      desc3:
          'As memory lanes agora aparecem para mais pessoas na sua vida, incluindo crianças a partir de 3 anos. Links compartilhados carregam mais rápido, com animações mais suaves.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Memórias mais suaves',
      desc1:
          'Redescobrir memórias antigas ficou melhor, com nova resposta háptica e melhorias internas.',
      title2: 'Navegação mais rápida',
      desc2:
          'As suas fotografias e vídeos carregam mais depressa. Atualizámos a nossa infraestrutura, para que tudo pareça mais ágil.',
      title3: 'Memory lane melhor',
      desc3:
          'As memory lanes aparecem agora para mais pessoas na sua vida, incluindo crianças a partir dos 3 anos. As ligações partilhadas carregam mais depressa, com animações mais suaves.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Amintiri mai fluide',
      desc1:
          'Redescoperirea amintirilor vechi se simte mai bine, cu vibrații noi și îmbunătățiri interne.',
      title2: 'Navigare mai rapidă',
      desc2:
          'Fotografiile și videoclipurile tale se încarcă mai rapid. Ne-am actualizat infrastructura, așa că totul pare mai sprinten.',
      title3: 'Memory lane mai bun',
      desc3:
          'Memory lane apare acum pentru mai multe persoane din viața ta, inclusiv copii de 3 ani și peste. Linkurile partajate se încarcă mai rapid, cu animații mai fluide.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Более плавные воспоминания',
      desc1:
          'Возвращаться к старым воспоминаниям стало приятнее благодаря новой тактильной отдаче и внутренним улучшениям.',
      title2: 'Более быстрый просмотр',
      desc2:
          'Ваши фото и видео загружаются быстрее. Мы обновили инфраструктуру, поэтому всё ощущается более отзывчивым.',
      title3: 'Улучшенная memory lane',
      desc3:
          'Memory lane теперь появляется для большего числа людей в вашей жизни, включая детей от 3 лет. Общие ссылки загружаются быстрее, а анимации стали плавнее.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Daha akıcı anılar',
      desc1:
          'Eski anıları yeniden keşfetmek, yeni dokunsal geri bildirimler ve altyapı iyileştirmeleriyle daha iyi hissettiriyor.',
      title2: 'Daha hızlı gezinme',
      desc2:
          'Fotoğraflarınız ve videolarınız daha hızlı yükleniyor. Altyapımızı güncelledik, böylece her şey daha çevik hissettiriyor.',
      title3: 'Daha iyi memory lane',
      desc3:
          'Memory lane artık hayatınızdaki daha fazla kişi için, 3 yaş ve üzeri çocuklar dahil, görünüyor. Paylaşılan bağlantılar daha hızlı yükleniyor ve animasyonlar daha akıcı.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Плавніші спогади',
      desc1:
          'Повертатися до старих спогадів стало приємніше завдяки новій тактильній віддачі та внутрішнім покращенням.',
      title2: 'Швидший перегляд',
      desc2:
          'Ваші фото й відео завантажуються швидше. Ми оновили інфраструктуру, тож усе відчувається жвавішим.',
      title3: 'Краща memory lane',
      desc3:
          'Memory lane тепер з’являється для більшої кількості людей у вашому житті, зокрема дітей від 3 років. Спільні посилання завантажуються швидше, а анімації стали плавнішими.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Kỷ niệm mượt mà hơn',
      desc1:
          'Việc khám phá lại các kỷ niệm cũ nay dễ chịu hơn, với phản hồi rung mới và các cải thiện bên trong.',
      title2: 'Duyệt nhanh hơn',
      desc2:
          'Ảnh và video của bạn tải nhanh hơn. Chúng tôi đã cập nhật hạ tầng để mọi thứ phản hồi nhanh hơn.',
      title3: 'Memory lane tốt hơn',
      desc3:
          'Memory lane nay xuất hiện cho nhiều người hơn trong cuộc sống của bạn, bao gồm cả trẻ từ 3 tuổi trở lên. Liên kết chia sẻ tải nhanh hơn, với hoạt ảnh mượt mà hơn.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '更流畅的回忆',
      desc1: '通过新的触觉反馈和底层改进，重新发现旧回忆的体验更好了。',
      title2: '更快的浏览',
      desc2: '你的照片和视频加载更快。我们更新了基础设施，让一切感觉更迅速。',
      title3: '更好的 memory lane',
      desc3: '现在，memory lane 会为你生活中的更多人显示，包括 3 岁及以上的孩子。共享链接加载更快，动画也更流畅。',
    ),
  };

  static const Map<String, ChangeLogStrings> _offlineTranslations = {
    'en': ChangeLogStrings(
      title1: 'Smoother memories',
      desc1:
          'Rediscovering old memories feels better, with new haptics and under-the-hood improvements.',
      title2: 'Faster browsing',
      desc2:
          "Your photos and videos load faster. We've updated our infrastructure, so everything feels snappier.",
    ),
    'cs': ChangeLogStrings(
      title1: 'Plynulejší vzpomínky',
      desc1:
          'Znovuobjevování starých vzpomínek je příjemnější díky nové haptické odezvě a vylepšením na pozadí.',
      title2: 'Rychlejší prohlížení',
      desc2:
          'Vaše fotky a videa se načítají rychleji. Aktualizovali jsme naši infrastrukturu, takže vše působí svižněji.',
    ),
    'de': ChangeLogStrings(
      title1: 'Flüssigere Erinnerungen',
      desc1:
          'Das Wiederentdecken alter Erinnerungen fühlt sich mit neuer Haptik und Verbesserungen im Hintergrund besser an.',
      title2: 'Schnelleres Browsen',
      desc2:
          'Ihre Fotos und Videos laden schneller. Wir haben unsere Infrastruktur aktualisiert, damit sich alles reaktionsschneller anfühlt.',
    ),
    'es': ChangeLogStrings(
      title1: 'Recuerdos más fluidos',
      desc1:
          'Redescubrir recuerdos antiguos se siente mejor, con nuevas respuestas hápticas y mejoras internas.',
      title2: 'Navegación más rápida',
      desc2:
          'Tus fotos y videos cargan más rápido. Hemos actualizado nuestra infraestructura para que todo se sienta más ágil.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Souvenirs plus fluides',
      desc1:
          'Redécouvrir d’anciens souvenirs est plus agréable, avec de nouvelles vibrations et des améliorations internes.',
      title2: 'Navigation plus rapide',
      desc2:
          'Vos photos et vidéos se chargent plus vite. Nous avons mis à jour notre infrastructure pour rendre l’ensemble plus réactif.',
    ),
    'it': ChangeLogStrings(
      title1: 'Ricordi più fluidi',
      desc1:
          'Riscoprire vecchi ricordi è più piacevole, con nuovi feedback aptici e miglioramenti interni.',
      title2: 'Navigazione più veloce',
      desc2:
          'Le tue foto e i tuoi video si caricano più velocemente. Abbiamo aggiornato la nostra infrastruttura, così tutto risulta più reattivo.',
    ),
    'ja': ChangeLogStrings(
      title1: 'よりスムーズな思い出',
      desc1: '新しい触覚フィードバックと内部改善により、昔の思い出を振り返る体験がより心地よくなりました。',
      title2: 'より速い閲覧',
      desc2: '写真や動画の読み込みが速くなりました。インフラを更新し、全体がより軽快に感じられます。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Soepelere herinneringen',
      desc1:
          'Oude herinneringen herontdekken voelt beter, met nieuwe haptiek en verbeteringen onder de motorkap.',
      title2: 'Sneller bladeren',
      desc2:
          'Je foto’s en video’s laden sneller. We hebben onze infrastructuur bijgewerkt, zodat alles vlotter aanvoelt.',
    ),
    'no': ChangeLogStrings(
      title1: 'Jevnere minner',
      desc1:
          'Det føles bedre å gjenoppdage gamle minner, med ny haptikk og forbedringer under panseret.',
      title2: 'Raskere blaing',
      desc2:
          'Bildene og videoene dine lastes raskere. Vi har oppdatert infrastrukturen vår, slik at alt føles kvikkere.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Płynniejsze wspomnienia',
      desc1:
          'Odkrywanie dawnych wspomnień jest przyjemniejsze dzięki nowym reakcjom haptycznym i ulepszeniom pod spodem.',
      title2: 'Szybsze przeglądanie',
      desc2:
          'Twoje zdjęcia i filmy ładują się szybciej. Zaktualizowaliśmy naszą infrastrukturę, więc wszystko działa sprawniej.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Memórias mais suaves',
      desc1:
          'Redescobrir memórias antigas ficou melhor, com novos retornos táteis e melhorias internas.',
      title2: 'Navegação mais rápida',
      desc2:
          'Suas fotos e vídeos carregam mais rápido. Atualizamos nossa infraestrutura, então tudo fica mais ágil.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Memórias mais suaves',
      desc1:
          'Redescobrir memórias antigas ficou melhor, com nova resposta háptica e melhorias internas.',
      title2: 'Navegação mais rápida',
      desc2:
          'As suas fotografias e vídeos carregam mais depressa. Atualizámos a nossa infraestrutura, para que tudo pareça mais ágil.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Amintiri mai fluide',
      desc1:
          'Redescoperirea amintirilor vechi se simte mai bine, cu vibrații noi și îmbunătățiri interne.',
      title2: 'Navigare mai rapidă',
      desc2:
          'Fotografiile și videoclipurile tale se încarcă mai rapid. Ne-am actualizat infrastructura, așa că totul pare mai sprinten.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Более плавные воспоминания',
      desc1:
          'Возвращаться к старым воспоминаниям стало приятнее благодаря новой тактильной отдаче и внутренним улучшениям.',
      title2: 'Более быстрый просмотр',
      desc2:
          'Ваши фото и видео загружаются быстрее. Мы обновили инфраструктуру, поэтому всё ощущается более отзывчивым.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Daha akıcı anılar',
      desc1:
          'Eski anıları yeniden keşfetmek, yeni dokunsal geri bildirimler ve altyapı iyileştirmeleriyle daha iyi hissettiriyor.',
      title2: 'Daha hızlı gezinme',
      desc2:
          'Fotoğraflarınız ve videolarınız daha hızlı yükleniyor. Altyapımızı güncelledik, böylece her şey daha çevik hissettiriyor.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Плавніші спогади',
      desc1:
          'Повертатися до старих спогадів стало приємніше завдяки новій тактильній віддачі та внутрішнім покращенням.',
      title2: 'Швидший перегляд',
      desc2:
          'Ваші фото й відео завантажуються швидше. Ми оновили інфраструктуру, тож усе відчувається жвавішим.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Kỷ niệm mượt mà hơn',
      desc1:
          'Việc khám phá lại các kỷ niệm cũ nay dễ chịu hơn, với phản hồi rung mới và các cải thiện bên trong.',
      title2: 'Duyệt nhanh hơn',
      desc2:
          'Ảnh và video của bạn tải nhanh hơn. Chúng tôi đã cập nhật hạ tầng để mọi thứ phản hồi nhanh hơn.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '更流畅的回忆',
      desc1: '通过新的触觉反馈和底层改进，重新发现旧回忆的体验更好了。',
      title2: '更快的浏览',
      desc2: '你的照片和视频加载更快。我们更新了基础设施，让一切感觉更迅速。',
    ),
  };
}
