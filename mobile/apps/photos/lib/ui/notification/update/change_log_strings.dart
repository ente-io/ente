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
      title1: 'Memory Lane',
      desc1:
          'See how you and your loved ones have changed over the years with Memory Lane. Open someone\'s page from the Search tab, then find Memory Lane in the overflow menu. Share the experience by sending a Memory Lane link.',
      title2: 'Share Your Memories',
      desc2:
          'Share any memory as a link with friends and family - they\'ll get the full experience right in their browser. Memory and memory lane links self-destruct after 7 days.',
      title3: 'QR Code Detection',
      desc3:
          'Long-press any photo containing a QR code to instantly reveal and share the content behind it.',
      title4: 'New Text Selection',
      desc4:
          'That same long-press gesture works for text too - use it to detect and select text in any photo.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Cesta vzpomínek',
      desc1:
          'Podívejte se, jak se vy a vaši blízcí měnili v průběhu let s Cestou vzpomínek. Otevřete stránku osoby z karty Hledat a poté najděte Cestu vzpomínek v nabídce. Sdílejte zážitek odesláním odkazu na Cestu vzpomínek.',
      title2: 'Sdílejte své vzpomínky',
      desc2:
          'Sdílejte jakoukoli vzpomínku jako odkaz s přáteli a rodinou – dostanou plný zážitek přímo ve svém prohlížeči. Odkazy na vzpomínky a cesty vzpomínek se automaticky zničí po 7 dnech.',
      title3: 'Detekce QR kódů',
      desc3:
          'Dlouhým stisknutím na jakékoli fotce s QR kódem okamžitě zobrazíte a sdílíte obsah za ním.',
      title4: 'Nový výběr textu',
      desc4:
          'Stejné gesto dlouhého stisknutí funguje i pro text – použijte ho k detekci a výběru textu na jakékoli fotce.',
    ),
    'de': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Sehen Sie, wie sich Sie und Ihre Liebsten im Laufe der Jahre verändert haben – mit Memory Lane. Öffnen Sie die Seite einer Person über den Suchen-Tab und finden Sie Memory Lane im Overflow-Menü. Teilen Sie das Erlebnis, indem Sie einen Memory-Lane-Link senden.',
      title2: 'Teilen Sie Ihre Erinnerungen',
      desc2:
          'Teilen Sie jede Erinnerung als Link mit Freunden und Familie – sie erhalten das vollständige Erlebnis direkt im Browser. Links zu Erinnerungen und Memory Lane werden nach 7 Tagen automatisch gelöscht.',
      title3: 'QR-Code-Erkennung',
      desc3:
          'Drücken Sie lange auf ein Foto mit einem QR-Code, um den Inhalt dahinter sofort anzuzeigen und zu teilen.',
      title4: 'Neue Textauswahl',
      desc4:
          'Die gleiche Geste des langen Drückens funktioniert auch für Text – erkennen und markieren Sie Text in jedem Foto.',
    ),
    'es': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Descubre cómo tú y tus seres queridos han cambiado a lo largo de los años con Memory Lane. Abre la página de alguien desde la pestaña Buscar y luego encuentra Memory Lane en el menú de opciones. Comparte la experiencia enviando un enlace de Memory Lane.',
      title2: 'Comparte tus recuerdos',
      desc2:
          'Comparte cualquier recuerdo como un enlace con amigos y familia: obtendrán la experiencia completa directamente en su navegador. Los enlaces de recuerdos y Memory Lane se autodestruyen después de 7 días.',
      title3: 'Detección de códigos QR',
      desc3:
          'Mantén pulsada cualquier foto que contenga un código QR para revelar y compartir instantáneamente el contenido detrás de él.',
      title4: 'Nueva selección de texto',
      desc4:
          'El mismo gesto de pulsación larga también funciona para texto: úsalo para detectar y seleccionar texto en cualquier foto.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Découvrez comment vous et vos proches avez changé au fil des années avec Memory Lane. Ouvrez la page d\'une personne depuis l\'onglet Rechercher, puis trouvez Memory Lane dans le menu. Partagez l\'expérience en envoyant un lien Memory Lane.',
      title2: 'Partagez vos souvenirs',
      desc2:
          'Partagez n\'importe quel souvenir sous forme de lien avec vos amis et votre famille – ils profiteront de l\'expérience complète directement dans leur navigateur. Les liens de souvenirs et de Memory Lane s\'autodétruisent après 7 jours.',
      title3: 'Détection de codes QR',
      desc3:
          'Appuyez longuement sur n\'importe quelle photo contenant un code QR pour révéler et partager instantanément le contenu qu\'il renferme.',
      title4: 'Nouvelle sélection de texte',
      desc4:
          'Le même geste d\'appui long fonctionne aussi pour le texte – utilisez-le pour détecter et sélectionner du texte dans n\'importe quelle photo.',
    ),
    'it': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Scopri come tu e i tuoi cari siete cambiati nel corso degli anni con Memory Lane. Apri la pagina di una persona dalla scheda Cerca, poi trova Memory Lane nel menu. Condividi l\'esperienza inviando un link Memory Lane.',
      title2: 'Condividi i tuoi ricordi',
      desc2:
          'Condividi qualsiasi ricordo come link con amici e familiari: vivranno l\'esperienza completa direttamente nel loro browser. I link dei ricordi e di Memory Lane si autodistruggono dopo 7 giorni.',
      title3: 'Rilevamento codici QR',
      desc3:
          'Tieni premuto su qualsiasi foto contenente un codice QR per rivelare e condividere istantaneamente il contenuto dietro di esso.',
      title4: 'Nuova selezione del testo',
      desc4:
          'Lo stesso gesto di pressione prolungata funziona anche per il testo: usalo per rilevare e selezionare testo in qualsiasi foto.',
    ),
    'ja': ChangeLogStrings(
      title1: 'メモリーレーン',
      desc1:
          'メモリーレーンで、あなたや大切な人たちが年月とともにどう変わったかを振り返りましょう。検索タブから人物のページを開き、オーバーフローメニューからメモリーレーンを見つけてください。メモリーレーンのリンクを送って体験を共有できます。',
      title2: '思い出を共有',
      desc2:
          'どんな思い出でもリンクとして友人や家族と共有できます。受け取った人はブラウザで完全な体験を楽しめます。思い出やメモリーレーンのリンクは7日後に自動的に削除されます。',
      title3: 'QRコード検出',
      desc3: 'QRコードが含まれる写真を長押しすると、その内容を即座に表示・共有できます。',
      title4: '新しいテキスト選択',
      desc4: '同じ長押しジェスチャーはテキストにも対応しています。写真内のテキストを検出・選択できます。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Bekijk hoe jij en je dierbaren door de jaren heen zijn veranderd met Memory Lane. Open iemands pagina vanuit het tabblad Zoeken en vind Memory Lane in het overflowmenu. Deel de ervaring door een Memory Lane-link te sturen.',
      title2: 'Deel je herinneringen',
      desc2:
          'Deel elke herinnering als link met vrienden en familie – ze krijgen de volledige ervaring direct in hun browser. Links naar herinneringen en Memory Lane worden na 7 dagen automatisch verwijderd.',
      title3: 'QR-codedetectie',
      desc3:
          'Houd een foto met een QR-code lang ingedrukt om de inhoud erachter direct te onthullen en te delen.',
      title4: 'Nieuwe tekstselectie',
      desc4:
          'Hetzelfde gebaar van lang indrukken werkt ook voor tekst – gebruik het om tekst in elke foto te detecteren en te selecteren.',
    ),
    'no': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Se hvordan du og dine kjære har forandret seg gjennom årene med Memory Lane. Åpne noens side fra Søk-fanen, og finn Memory Lane i menyen. Del opplevelsen ved å sende en Memory Lane-lenke.',
      title2: 'Del minnene dine',
      desc2:
          'Del et hvilket som helst minne som en lenke med venner og familie – de får den fulle opplevelsen rett i nettleseren. Lenker til minner og Memory Lane slettes automatisk etter 7 dager.',
      title3: 'QR-kodegjenkjenning',
      desc3:
          'Trykk og hold på et bilde som inneholder en QR-kode for å umiddelbart vise og dele innholdet bak den.',
      title4: 'Ny tekstvelging',
      desc4:
          'Den samme langtrykk-bevegelsen fungerer også for tekst – bruk den til å oppdage og velge tekst i et hvilket som helst bilde.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Zobacz, jak Ty i Twoi bliscy zmieniali się na przestrzeni lat dzięki Memory Lane. Otwórz stronę osoby z zakładki Szukaj, a następnie znajdź Memory Lane w menu. Podziel się doświadczeniem, wysyłając link do Memory Lane.',
      title2: 'Udostępnij swoje wspomnienia',
      desc2:
          'Udostępnij dowolne wspomnienie jako link znajomym i rodzinie – zobaczą pełne doświadczenie bezpośrednio w przeglądarce. Linki do wspomnień i Memory Lane ulegają samozniszczeniu po 7 dniach.',
      title3: 'Wykrywanie kodów QR',
      desc3:
          'Przytrzymaj dowolne zdjęcie zawierające kod QR, aby natychmiast wyświetlić i udostępnić ukrytą treść.',
      title4: 'Nowe zaznaczanie tekstu',
      desc4:
          'Ten sam gest przytrzymania działa również dla tekstu – użyj go do wykrywania i zaznaczania tekstu na dowolnym zdjęciu.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Veja como você e seus entes queridos mudaram ao longo dos anos com o Memory Lane. Abra a página de alguém na aba Pesquisar e encontre o Memory Lane no menu. Compartilhe a experiência enviando um link do Memory Lane.',
      title2: 'Compartilhe suas memórias',
      desc2:
          'Compartilhe qualquer memória como um link com amigos e familiares – eles terão a experiência completa direto no navegador. Links de memórias e Memory Lane se autodestroem após 7 dias.',
      title3: 'Detecção de código QR',
      desc3:
          'Pressione e segure qualquer foto contendo um código QR para revelar e compartilhar instantaneamente o conteúdo por trás dele.',
      title4: 'Nova seleção de texto',
      desc4:
          'O mesmo gesto de pressionar e segurar também funciona para texto – use-o para detectar e selecionar texto em qualquer foto.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Veja como você e os seus entes queridos mudaram ao longo dos anos com o Memory Lane. Abra a página de alguém no separador Pesquisar e encontre o Memory Lane no menu. Partilhe a experiência enviando uma ligação do Memory Lane.',
      title2: 'Partilhe as suas memórias',
      desc2:
          'Partilhe qualquer memória como uma ligação com amigos e família – terão a experiência completa diretamente no navegador. As ligações de memórias e Memory Lane autodestroem-se após 7 dias.',
      title3: 'Deteção de código QR',
      desc3:
          'Prima longamente qualquer fotografia que contenha um código QR para revelar e partilhar instantaneamente o conteúdo por detrás dele.',
      title4: 'Nova seleção de texto',
      desc4:
          'O mesmo gesto de pressão longa também funciona para texto – utilize-o para detetar e selecionar texto em qualquer fotografia.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Memory Lane',
      desc1:
          'Vezi cum tu și cei dragi v-ați schimbat de-a lungul anilor cu Memory Lane. Deschide pagina unei persoane din fila Căutare, apoi găsește Memory Lane în meniul suplimentar. Împărtășește experiența trimițând un link Memory Lane.',
      title2: 'Împărtășește-ți amintirile',
      desc2:
          'Împărtășește orice amintire sub formă de link cu prietenii și familia – vor primi experiența completă direct în browser. Linkurile de amintiri și Memory Lane se autodistrug după 7 zile.',
      title3: 'Detectare coduri QR',
      desc3:
          'Apasă lung pe orice fotografie care conține un cod QR pentru a dezvălui și partaja instantaneu conținutul din spatele acestuia.',
      title4: 'Nouă selecție de text',
      desc4:
          'Același gest de apăsare lungă funcționează și pentru text – folosește-l pentru a detecta și selecta text din orice fotografie.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Дорога воспоминаний',
      desc1:
          'Посмотрите, как вы и ваши близкие менялись с годами с помощью Дороги воспоминаний. Откройте страницу человека на вкладке Поиск, затем найдите Дорогу воспоминаний в меню. Поделитесь впечатлениями, отправив ссылку на Дорогу воспоминаний.',
      title2: 'Делитесь воспоминаниями',
      desc2:
          'Поделитесь любым воспоминанием в виде ссылки с друзьями и близкими — они получат полный опыт прямо в браузере. Ссылки на воспоминания и Дорогу воспоминаний автоматически удаляются через 7 дней.',
      title3: 'Распознавание QR-кодов',
      desc3:
          'Нажмите и удерживайте любое фото с QR-кодом, чтобы мгновенно просмотреть и поделиться содержимым за ним.',
      title4: 'Новое выделение текста',
      desc4:
          'Тот же жест долгого нажатия работает и для текста — используйте его для распознавания и выделения текста на любом фото.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Anı Yolu',
      desc1:
          'Anı Yolu ile siz ve sevdiklerinizin yıllar içinde nasıl değiştiğini görün. Arama sekmesinden birinin sayfasını açın ve taşma menüsünde Anı Yolu\'nu bulun. Bir Anı Yolu bağlantısı göndererek deneyimi paylaşın.',
      title2: 'Anılarınızı paylaşın',
      desc2:
          'Herhangi bir anıyı arkadaşlarınız ve ailenizle bağlantı olarak paylaşın – tam deneyimi doğrudan tarayıcılarında yaşayacaklar. Anı ve Anı Yolu bağlantıları 7 gün sonra otomatik olarak silinir.',
      title3: 'QR Kod Algılama',
      desc3:
          'QR kod içeren herhangi bir fotoğrafa uzun basarak arkasındaki içeriği anında görüntüleyin ve paylaşın.',
      title4: 'Yeni Metin Seçimi',
      desc4:
          'Aynı uzun basma hareketi metin için de çalışır – herhangi bir fotoğraftaki metni algılamak ve seçmek için kullanın.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Стежка спогадів',
      desc1:
          'Подивіться, як ви та ваші рідні змінювалися протягом років завдяки Стежці спогадів. Відкрийте сторінку людини з вкладки Пошук, потім знайдіть Стежку спогадів у меню. Поділіться враженнями, надіславши посилання на Стежку спогадів.',
      title2: 'Діліться спогадами',
      desc2:
          'Поділіться будь-яким спогадом як посиланням з друзями та родиною – вони отримають повний досвід просто у браузері. Посилання на спогади та Стежку спогадів автоматично видаляються через 7 днів.',
      title3: 'Розпізнавання QR-кодів',
      desc3:
          'Натисніть і утримуйте будь-яке фото з QR-кодом, щоб миттєво переглянути та поділитися вмістом за ним.',
      title4: 'Нове виділення тексту',
      desc4:
          'Той самий жест довгого натискання працює і для тексту – використовуйте його для розпізнавання та виділення тексту на будь-якому фото.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Dải ký ức',
      desc1:
          'Xem bạn và những người thân yêu đã thay đổi như thế nào qua năm tháng với Dải ký ức. Mở trang của ai đó từ tab Tìm kiếm, sau đó tìm Dải ký ức trong menu. Chia sẻ trải nghiệm bằng cách gửi liên kết Dải ký ức.',
      title2: 'Chia sẻ kỷ niệm của bạn',
      desc2:
          'Chia sẻ bất kỳ kỷ niệm nào dưới dạng liên kết với bạn bè và gia đình – họ sẽ có trải nghiệm đầy đủ ngay trong trình duyệt. Các liên kết kỷ niệm và Dải ký ức tự hủy sau 7 ngày.',
      title3: 'Nhận diện mã QR',
      desc3:
          'Nhấn giữ bất kỳ ảnh nào chứa mã QR để hiển thị và chia sẻ ngay nội dung đằng sau nó.',
      title4: 'Chọn văn bản mới',
      desc4:
          'Cử chỉ nhấn giữ tương tự cũng hoạt động với văn bản – sử dụng nó để phát hiện và chọn văn bản trong bất kỳ ảnh nào.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '记忆长廊',
      desc1:
          '通过记忆长廊，查看你和挚爱的人这些年来的变化。从搜索标签页打开某人的页面，然后在菜单中找到记忆长廊。发送记忆长廊链接来分享这段体验。',
      title2: '分享你的回忆',
      desc2: '将任何回忆以链接形式分享给朋友和家人——他们可以直接在浏览器中获得完整体验。回忆和记忆长廊链接会在7天后自动销毁。',
      title3: '二维码检测',
      desc3: '长按任何包含二维码的照片，即可立即查看和分享其背后的内容。',
      title4: '全新文字选择',
      desc4: '同样的长按手势也适用于文字——用它来检测和选择任何照片中的文字。',
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
