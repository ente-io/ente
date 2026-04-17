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
      title1: 'Memories Improvements',
      desc1:
          'We have shipped a bunch of improvements in our memories system, including surfacing better memories with other people, detecting your past trips, and surfacing recent photos from last week and last month.',
      title2: 'View Other Family Members',
      desc2: 'Family members can now view other members on their family plans.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Vylepšení vzpomínek',
      desc1:
          'Přinášíme řadu vylepšení systému vzpomínek, včetně lepšího zobrazování společných momentů s blízkými, rozpoznávání vašich minulých cest a zobrazování nedávných fotek z minulého týdne a minulého měsíce.',
      title2: 'Zobrazit ostatní členy rodiny',
      desc2:
          'Členové rodiny nyní mohou zobrazit ostatní členy ve svých rodinných plánech.',
    ),
    'de': ChangeLogStrings(
      title1: 'Verbesserungen bei Erinnerungen',
      desc1:
          'Wir haben eine Reihe von Verbesserungen an unserem Erinnerungssystem veröffentlicht, darunter bessere Erinnerungen mit anderen Personen, das Erkennen Ihrer vergangenen Reisen sowie aktuelle Fotos von letzter Woche und letztem Monat.',
      title2: 'Andere Familienmitglieder ansehen',
      desc2:
          'Familienmitglieder können jetzt andere Mitglieder in ihren Familienplänen ansehen.',
    ),
    'es': ChangeLogStrings(
      title1: 'Mejoras en Recuerdos',
      desc1:
          'Hemos lanzado varias mejoras en nuestro sistema de recuerdos, incluyendo mejores recuerdos con otras personas, la detección de tus viajes pasados y la aparición de fotos recientes de la semana pasada y del mes pasado.',
      title2: 'Ver a otros miembros de la familia',
      desc2:
          'Los miembros de la familia ahora pueden ver a otros miembros de sus planes familiares.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Améliorations des souvenirs',
      desc1:
          'Nous avons déployé de nombreuses améliorations de notre système de souvenirs, notamment de meilleurs souvenirs avec d\'autres personnes, la détection de vos voyages passés et l\'affichage de photos récentes de la semaine dernière et du mois dernier.',
      title2: 'Voir les autres membres de la famille',
      desc2:
          'Les membres de la famille peuvent désormais voir les autres membres de leur abonnement familial.',
    ),
    'it': ChangeLogStrings(
      title1: 'Miglioramenti ai ricordi',
      desc1:
          'Abbiamo introdotto diversi miglioramenti al nostro sistema dei ricordi, tra cui la possibilità di rivivere momenti condivisi con altre persone, il rilevamento dei tuoi viaggi passati e la comparsa di foto recenti della scorsa settimana e del mese scorso.',
      title2: 'Visualizza gli altri membri della famiglia',
      desc2:
          'I membri della famiglia ora possono visualizzare gli altri membri del proprio piano familiare.',
    ),
    'ja': ChangeLogStrings(
      title1: '思い出の改善',
      desc1:
          '思い出機能に多数の改善を加えました。他の人と一緒の思い出をより良く表示し、過去の旅行を検出し、先週や先月の最近の写真も表示します。',
      title2: 'ほかの家族メンバーを表示',
      desc2: 'ファミリープランのメンバーは、ほかのメンバーを表示できるようになりました。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Verbeteringen aan Herinneringen',
      desc1:
          'We hebben een aantal verbeteringen doorgevoerd in ons herinneringssysteem, waaronder betere herinneringen met andere mensen, het herkennen van je eerdere reizen en het tonen van recente foto\'s van vorige week en vorige maand.',
      title2: 'Andere gezinsleden bekijken',
      desc2:
          'Gezinsleden kunnen nu andere leden in hun gezinsabonnement bekijken.',
    ),
    'no': ChangeLogStrings(
      title1: 'Forbedringer i minner',
      desc1:
          'Vi har lansert en rekke forbedringer i minnene våre, blant annet bedre minner med andre personer, gjenkjenning av tidligere reiser og visning av nylige bilder fra forrige uke og forrige måned.',
      title2: 'Se andre familiemedlemmer',
      desc2:
          'Familiemedlemmer kan nå se andre medlemmer i familieabonnementet sitt.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Ulepszenia wspomnień',
      desc1:
          'Wprowadziliśmy szereg ulepszeń w systemie wspomnień, w tym lepsze wspomnienia z innymi osobami, wykrywanie Twoich dawnych podróży oraz wyświetlanie ostatnich zdjęć z zeszłego tygodnia i zeszłego miesiąca.',
      title2: 'Wyświetl innych członków rodziny',
      desc2:
          'Członkowie rodziny mogą teraz wyświetlać innych członków w swoich planach rodzinnych.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Melhorias nas memórias',
      desc1:
          'Lançamos várias melhorias no nosso sistema de memórias, incluindo melhores momentos compartilhados com outras pessoas, detecção das suas viagens passadas e exibição de fotos recentes da semana passada e do mês passado.',
      title2: 'Ver outros membros da família',
      desc2:
          'Os membros da família agora podem ver outros membros em seus planos familiares.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Melhorias nas memórias',
      desc1:
          'Lançámos várias melhorias no nosso sistema de memórias, incluindo melhores memórias com outras pessoas, deteção das suas viagens passadas e apresentação de fotografias recentes da semana passada e do mês passado.',
      title2: 'Ver outros membros da família',
      desc2:
          'Os membros da família podem agora ver outros membros nos seus planos familiares.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Îmbunătățiri ale amintirilor',
      desc1:
          'Am lansat o serie de îmbunătățiri pentru sistemul nostru de amintiri, inclusiv amintiri mai bune cu alte persoane, detectarea călătoriilor tale din trecut și afișarea fotografiilor recente din săptămâna trecută și luna trecută.',
      title2: 'Vezi alți membri ai familiei',
      desc2:
          'Membrii familiei pot acum vedea ceilalți membri din planurile lor de familie.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Улучшения воспоминаний',
      desc1:
          'Мы выпустили множество улучшений в системе воспоминаний: теперь лучше подбираются совместные моменты с близкими, распознаются ваши прошлые поездки и показываются недавние фотографии за прошлую неделю и месяц.',
      title2: 'Просмотр других членов семьи',
      desc2:
          'Теперь участники семейных планов могут просматривать других участников.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Anılar için iyileştirmeler',
      desc1:
          'Anılar sistemimizde birçok iyileştirme yayınladık. Artık başkalarıyla paylaştığınız anları daha iyi bir şekilde öne çıkarıyor, geçmiş seyahatlerinizi algılıyor ve geçen hafta ile geçen aydan son fotoğraflarınızı gösteriyoruz.',
      title2: 'Diğer aile üyelerini görüntüleyin',
      desc2:
          'Aile üyeleri artık aile planlarındaki diğer üyeleri görüntüleyebilir.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Покращення спогадів',
      desc1:
          'Ми випустили низку покращень у нашій системі спогадів, зокрема кращі спогади з іншими людьми, розпізнавання ваших минулих подорожей і показ недавніх фотографій за минулий тиждень і минулий місяць.',
      title2: 'Перегляд інших членів сімʼї',
      desc2: 'Тепер члени сімейних планів можуть переглядати інших учасників.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Cải thiện Kỷ niệm',
      desc1:
          'Chúng tôi đã phát hành nhiều cải tiến cho hệ thống kỷ niệm, bao gồm hiển thị những kỷ niệm tốt hơn với người khác, nhận diện các chuyến đi trước đây của bạn và hiển thị các ảnh gần đây từ tuần trước và tháng trước.',
      title2: 'Xem các thành viên khác trong gia đình',
      desc2:
          'Các thành viên gia đình giờ đây có thể xem những thành viên khác trong gói gia đình của mình.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '回忆改进',
      desc1: '我们对回忆系统进行了多项改进，包括展示与他人相关的更好回忆、识别你过去的旅行，以及展示上周和上个月的近期照片。',
      title2: '查看其他家庭成员',
      desc2: '家庭成员现在可以查看其家庭计划中的其他成员。',
    ),
  };

  static const Map<String, ChangeLogStrings> _offlineTranslations = {
    'en': ChangeLogStrings(
      title1: 'QR Code Detection',
      desc1:
          'Long-press any photo containing a QR code to instantly reveal and share the content behind it.',
      title2: 'New Text Selection',
      desc2:
          'That same long-press gesture works for text too - use it to detect and select text in any photo.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Detekce QR kódů',
      desc1:
          'Dlouhým stisknutím na jakékoli fotce s QR kódem okamžitě zobrazíte a sdílíte obsah za ním.',
      title2: 'Nový výběr textu',
      desc2:
          'Stejné gesto dlouhého stisknutí funguje i pro text – použijte ho k detekci a výběru textu na jakékoli fotce.',
    ),
    'de': ChangeLogStrings(
      title1: 'QR-Code-Erkennung',
      desc1:
          'Drücken Sie lange auf ein Foto mit einem QR-Code, um den Inhalt dahinter sofort anzuzeigen und zu teilen.',
      title2: 'Neue Textauswahl',
      desc2:
          'Die gleiche Geste des langen Drückens funktioniert auch für Text – erkennen und markieren Sie Text in jedem Foto.',
    ),
    'es': ChangeLogStrings(
      title1: 'Detección de códigos QR',
      desc1:
          'Mantén pulsada cualquier foto que contenga un código QR para revelar y compartir instantáneamente el contenido detrás de él.',
      title2: 'Nueva selección de texto',
      desc2:
          'El mismo gesto de pulsación larga también funciona para texto: úsalo para detectar y seleccionar texto en cualquier foto.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Détection de codes QR',
      desc1:
          'Appuyez longuement sur n\'importe quelle photo contenant un code QR pour révéler et partager instantanément le contenu qu\'il renferme.',
      title2: 'Nouvelle sélection de texte',
      desc2:
          'Le même geste d\'appui long fonctionne aussi pour le texte – utilisez-le pour détecter et sélectionner du texte dans n\'importe quelle photo.',
    ),
    'it': ChangeLogStrings(
      title1: 'Rilevamento codici QR',
      desc1:
          'Tieni premuto su qualsiasi foto contenente un codice QR per rivelare e condividere istantaneamente il contenuto dietro di esso.',
      title2: 'Nuova selezione del testo',
      desc2:
          'Lo stesso gesto di pressione prolungata funziona anche per il testo: usalo per rilevare e selezionare testo in qualsiasi foto.',
    ),
    'ja': ChangeLogStrings(
      title1: 'QRコード検出',
      desc1: 'QRコードが含まれる写真を長押しすると、その内容を即座に表示・共有できます。',
      title2: '新しいテキスト選択',
      desc2: '同じ長押しジェスチャーはテキストにも対応しています。写真内のテキストを検出・選択できます。',
    ),
    'nl': ChangeLogStrings(
      title1: 'QR-codedetectie',
      desc1:
          'Houd een foto met een QR-code lang ingedrukt om de inhoud erachter direct te onthullen en te delen.',
      title2: 'Nieuwe tekstselectie',
      desc2:
          'Hetzelfde gebaar van lang indrukken werkt ook voor tekst – gebruik het om tekst in elke foto te detecteren en te selecteren.',
    ),
    'no': ChangeLogStrings(
      title1: 'QR-kodegjenkjenning',
      desc1:
          'Trykk og hold på et bilde som inneholder en QR-kode for å umiddelbart vise og dele innholdet bak den.',
      title2: 'Ny tekstvelging',
      desc2:
          'Den samme langtrykk-bevegelsen fungerer også for tekst – bruk den til å oppdage og velge tekst i et hvilket som helst bilde.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Wykrywanie kodów QR',
      desc1:
          'Przytrzymaj dowolne zdjęcie zawierające kod QR, aby natychmiast wyświetlić i udostępnić ukrytą treść.',
      title2: 'Nowe zaznaczanie tekstu',
      desc2:
          'Ten sam gest przytrzymania działa również dla tekstu – użyj go do wykrywania i zaznaczania tekstu na dowolnym zdjęciu.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Detecção de código QR',
      desc1:
          'Pressione e segure qualquer foto contendo um código QR para revelar e compartilhar instantaneamente o conteúdo por trás dele.',
      title2: 'Nova seleção de texto',
      desc2:
          'O mesmo gesto de pressionar e segurar também funciona para texto – use-o para detectar e selecionar texto em qualquer foto.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Deteção de código QR',
      desc1:
          'Prima longamente qualquer fotografia que contenha um código QR para revelar e partilhar instantaneamente o conteúdo por detrás dele.',
      title2: 'Nova seleção de texto',
      desc2:
          'O mesmo gesto de pressão longa também funciona para texto – utilize-o para detetar e selecionar texto em qualquer fotografia.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Detectare coduri QR',
      desc1:
          'Apasă lung pe orice fotografie care conține un cod QR pentru a dezvălui și partaja instantaneu conținutul din spatele acestuia.',
      title2: 'Nouă selecție de text',
      desc2:
          'Același gest de apăsare lungă funcționează și pentru text – folosește-l pentru a detecta și selecta text din orice fotografie.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Распознавание QR-кодов',
      desc1:
          'Нажмите и удерживайте любое фото с QR-кодом, чтобы мгновенно просмотреть и поделиться содержимым за ним.',
      title2: 'Новое выделение текста',
      desc2:
          'Тот же жест долгого нажатия работает и для текста — используйте его для распознавания и выделения текста на любом фото.',
    ),
    'tr': ChangeLogStrings(
      title1: 'QR Kod Algılama',
      desc1:
          'QR kod içeren herhangi bir fotoğrafa uzun basarak arkasındaki içeriği anında görüntüleyin ve paylaşın.',
      title2: 'Yeni Metin Seçimi',
      desc2:
          'Aynı uzun basma hareketi metin için de çalışır – herhangi bir fotoğraftaki metni algılamak ve seçmek için kullanın.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Розпізнавання QR-кодів',
      desc1:
          'Натисніть і утримуйте будь-яке фото з QR-кодом, щоб миттєво переглянути та поділитися вмістом за ним.',
      title2: 'Нове виділення тексту',
      desc2:
          'Той самий жест довгого натискання працює і для тексту – використовуйте його для розпізнавання та виділення тексту на будь-якому фото.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Nhận diện mã QR',
      desc1:
          'Nhấn giữ bất kỳ ảnh nào chứa mã QR để hiển thị và chia sẻ ngay nội dung đằng sau nó.',
      title2: 'Chọn văn bản mới',
      desc2:
          'Cử chỉ nhấn giữ tương tự cũng hoạt động với văn bản – sử dụng nó để phát hiện và chọn văn bản trong bất kỳ ảnh nào.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '二维码检测',
      desc1: '长按任何包含二维码的照片，即可立即查看和分享其背后的内容。',
      title2: '全新文字选择',
      desc2: '同样的长按手势也适用于文字——用它来检测和选择任何照片中的文字。',
    ),
  };
}
