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
    bool isLocalGallery = false,
  }) {
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final translations = isLocalGallery ? _offlineTranslations : _translations;
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
    bool isLocalGallery = false,
  }) {
    return maybeForLocale(
          locale,
          isLocalGallery: isLocalGallery,
        ) !=
        null;
  }

  static const Map<String, ChangeLogStrings> _translations = {
    'en': ChangeLogStrings(
      title1: 'Photo picker for 3rd party apps',
      desc1:
          "Want to share a photo on WhatsApp or Signal, but couldn't select from Ente Photos? Got you covered! We have added support for selecting photos to attach to third-party apps.",
      title2: 'View camera photos in Ente',
      desc2:
          'On supported devices, you can now tap the thumbnail in your Camera app to open the photo directly in Ente Photos. One less hop between snapping a shot and seeing it where you want it.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Výběr fotek pro aplikace třetích stran',
      desc1:
          'Chcete sdílet fotku na WhatsAppu nebo Signalu, ale nemohli jste ji vybrat z Ente Photos? Máme to vyřešené! Přidali jsme podporu pro výběr fotek, které můžete připojit v aplikacích třetích stran.',
      title2: 'Prohlížejte fotky z fotoaparátu v Ente',
      desc2:
          'Na podporovaných zařízeních teď můžete klepnout na náhled v aplikaci Fotoaparát a otevřít fotku přímo v Ente Photos. O jeden krok méně mezi pořízením snímku a jeho zobrazením tam, kde ho chcete mít.',
    ),
    'de': ChangeLogStrings(
      title1: 'Fotoauswahl für Drittanbieter-Apps',
      desc1:
          'Möchten Sie ein Foto in WhatsApp oder Signal teilen, konnten es aber nicht aus Ente Photos auswählen? Das ist jetzt möglich! Wir haben Unterstützung hinzugefügt, damit Sie Fotos zum Anhängen in Drittanbieter-Apps auswählen können.',
      title2: 'Kamerafotos in Ente ansehen',
      desc2:
          'Auf unterstützten Geräten können Sie jetzt in Ihrer Kamera-App auf die Miniaturansicht tippen, um das Foto direkt in Ente Photos zu öffnen. Ein Schritt weniger zwischen dem Aufnehmen und dem Anzeigen dort, wo Sie es sehen möchten.',
    ),
    'es': ChangeLogStrings(
      title1: 'Selector de fotos para apps de terceros',
      desc1:
          '¿Quieres compartir una foto en WhatsApp o Signal, pero no podías seleccionarla desde Ente Photos? ¡Ya está cubierto! Hemos añadido soporte para seleccionar fotos y adjuntarlas en apps de terceros.',
      title2: 'Ver fotos de la cámara en Ente',
      desc2:
          'En dispositivos compatibles, ahora puedes tocar la miniatura en tu app de Cámara para abrir la foto directamente en Ente Photos. Un paso menos entre tomar la foto y verla donde quieres.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Sélecteur de photos pour les apps tierces',
      desc1:
          'Vous voulez partager une photo sur WhatsApp ou Signal, mais vous ne pouviez pas la sélectionner depuis Ente Photos ? C’est désormais possible ! Nous avons ajouté la prise en charge de la sélection de photos à joindre dans des apps tierces.',
      title2: 'Voir les photos de l’appareil photo dans Ente',
      desc2:
          'Sur les appareils compatibles, vous pouvez désormais toucher la miniature dans votre app Appareil photo pour ouvrir la photo directement dans Ente Photos. Une étape de moins entre la prise de vue et l’affichage là où vous le souhaitez.',
    ),
    'it': ChangeLogStrings(
      title1: 'Selettore foto per app di terze parti',
      desc1:
          'Vuoi condividere una foto su WhatsApp o Signal, ma non riuscivi a selezionarla da Ente Photos? Ci abbiamo pensato noi! Abbiamo aggiunto il supporto per selezionare foto da allegare alle app di terze parti.',
      title2: 'Visualizza le foto della fotocamera in Ente',
      desc2:
          'Sui dispositivi supportati, ora puoi toccare la miniatura nell’app Fotocamera per aprire la foto direttamente in Ente Photos. Un passaggio in meno tra lo scatto e la visualizzazione dove vuoi.',
    ),
    'ja': ChangeLogStrings(
      title1: 'サードパーティアプリ用の写真ピッカー',
      desc1:
          'WhatsAppやSignalで写真を共有したいのに、Ente Photosから選択できませんでしたか？対応しました！サードパーティアプリに添付する写真を選択できるようになりました。',
      title2: 'カメラの写真をEnteで表示',
      desc2:
          '対応デバイスでは、カメラアプリのサムネイルをタップすると、写真をEnte Photosで直接開けるようになりました。撮影してから見たい場所で表示するまでの手間がひとつ減ります。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Fotokiezer voor apps van derden',
      desc1:
          'Wil je een foto delen via WhatsApp of Signal, maar kon je die niet selecteren vanuit Ente Photos? Dat is nu geregeld! We hebben ondersteuning toegevoegd om foto’s te selecteren en toe te voegen aan apps van derden.',
      title2: 'Camerafoto’s bekijken in Ente',
      desc2:
          'Op ondersteunde apparaten kun je nu op de miniatuur in je Camera-app tikken om de foto direct in Ente Photos te openen. Een stap minder tussen het maken van een foto en die zien waar je wilt.',
    ),
    'no': ChangeLogStrings(
      title1: 'Fotovelger for tredjepartsapper',
      desc1:
          'Vil du dele et bilde på WhatsApp eller Signal, men kunne ikke velge det fra Ente Photos? Det har vi fikset! Vi har lagt til støtte for å velge bilder som vedlegg i tredjepartsapper.',
      title2: 'Se kamerabilder i Ente',
      desc2:
          'På støttede enheter kan du nå trykke på miniatyrbildet i Kamera-appen for å åpne bildet direkte i Ente Photos. Ett steg mindre fra du tar et bilde til du ser det der du vil.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Selektor zdjęć dla aplikacji innych firm',
      desc1:
          'Chcesz udostępnić zdjęcie w WhatsAppie lub Signalu, ale nie dało się go wybrać z Ente Photos? Już to obsługujemy! Dodaliśmy możliwość wybierania zdjęć do załączania w aplikacjach innych firm.',
      title2: 'Wyświetlaj zdjęcia z aparatu w Ente',
      desc2:
          'Na obsługiwanych urządzeniach możesz teraz stuknąć miniaturę w aplikacji Aparat, aby otworzyć zdjęcie bezpośrednio w Ente Photos. O jeden krok mniej między zrobieniem zdjęcia a obejrzeniem go tam, gdzie chcesz.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Seletor de fotos para apps de terceiros',
      desc1:
          'Quer compartilhar uma foto no WhatsApp ou Signal, mas não conseguia selecioná-la no Ente Photos? Resolvido! Adicionamos suporte para selecionar fotos e anexá-las em apps de terceiros.',
      title2: 'Veja fotos da câmera no Ente',
      desc2:
          'Em dispositivos compatíveis, agora você pode tocar na miniatura no app Câmera para abrir a foto diretamente no Ente Photos. Um passo a menos entre tirar a foto e vê-la onde você quer.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Seletor de fotografias para apps de terceiros',
      desc1:
          'Quer partilhar uma fotografia no WhatsApp ou Signal, mas não conseguia selecioná-la no Ente Photos? Está tratado! Adicionámos suporte para selecionar fotografias e anexá-las em apps de terceiros.',
      title2: 'Veja fotografias da câmara no Ente',
      desc2:
          'Em dispositivos compatíveis, pode agora tocar na miniatura na app Câmara para abrir a fotografia diretamente no Ente Photos. Menos um passo entre tirar a fotografia e vê-la onde quer.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Selector de fotografii pentru aplicații terțe',
      desc1:
          'Vrei să partajezi o fotografie pe WhatsApp sau Signal, dar nu o puteai selecta din Ente Photos? Am rezolvat! Am adăugat suport pentru selectarea fotografiilor de atașat în aplicații terțe.',
      title2: 'Vezi fotografiile din cameră în Ente',
      desc2:
          'Pe dispozitivele acceptate, poți acum să atingi miniatura din aplicația Cameră pentru a deschide fotografia direct în Ente Photos. Un pas mai puțin între capturarea imaginii și vizualizarea ei unde dorești.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Выбор фото для сторонних приложений',
      desc1:
          'Хотите поделиться фото в WhatsApp или Signal, но не могли выбрать его из Ente Photos? Теперь это возможно! Мы добавили поддержку выбора фото для прикрепления в сторонних приложениях.',
      title2: 'Просматривайте фото с камеры в Ente',
      desc2:
          'На поддерживаемых устройствах теперь можно нажать миниатюру в приложении Камера, чтобы открыть фото прямо в Ente Photos. На один шаг меньше между съемкой и просмотром там, где вам удобно.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Üçüncü taraf uygulamalar için fotoğraf seçici',
      desc1:
          "WhatsApp veya Signal'de fotoğraf paylaşmak istiyor, ama Ente Photos'tan seçemiyor muydunuz? Artık mümkün! Üçüncü taraf uygulamalara eklemek üzere fotoğraf seçme desteği ekledik.",
      title2: "Kamera fotoğraflarını Ente'de görüntüleyin",
      desc2:
          "Desteklenen cihazlarda artık Kamera uygulamanızdaki küçük resme dokunarak fotoğrafı doğrudan Ente Photos'ta açabilirsiniz. Fotoğraf çekmekten istediğiniz yerde görmeye giden yolda bir adım daha az.",
    ),
    'uk': ChangeLogStrings(
      title1: 'Вибір фото для сторонніх застосунків',
      desc1:
          'Хочете поділитися фото у WhatsApp або Signal, але не могли вибрати його з Ente Photos? Тепер це можливо! Ми додали підтримку вибору фото для прикріплення у сторонніх застосунках.',
      title2: 'Переглядайте фото з камери в Ente',
      desc2:
          'На підтримуваних пристроях тепер можна торкнутися мініатюри в застосунку Камера, щоб відкрити фото безпосередньо в Ente Photos. На один крок менше між знімком і переглядом там, де вам потрібно.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Trình chọn ảnh cho ứng dụng bên thứ ba',
      desc1:
          'Muốn chia sẻ ảnh trên WhatsApp hoặc Signal nhưng không thể chọn từ Ente Photos? Chúng tôi đã hỗ trợ! Chúng tôi đã thêm khả năng chọn ảnh để đính kèm vào các ứng dụng bên thứ ba.',
      title2: 'Xem ảnh chụp từ camera trong Ente',
      desc2:
          'Trên các thiết bị được hỗ trợ, giờ bạn có thể nhấn vào hình thu nhỏ trong ứng dụng Camera để mở ảnh trực tiếp trong Ente Photos. Bớt một bước từ lúc chụp đến khi xem ảnh ở nơi bạn muốn.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '适用于第三方应用的照片选择器',
      desc1:
          '想在 WhatsApp 或 Signal 上分享照片，却无法从 Ente Photos 中选择？现在可以了！我们已支持选择照片并将其附加到第三方应用。',
      title2: '在 Ente 中查看相机照片',
      desc2:
          '在受支持的设备上，现在你可以点按相机应用中的缩略图，直接在 Ente Photos 中打开照片。从拍下照片到在想看的地方查看，又少了一步。',
    ),
  };

  static const Map<String, ChangeLogStrings> _offlineTranslations =
      _translations;
}
