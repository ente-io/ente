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
    required this.desc1Item1,
    required this.desc1Item2,
    required this.title2,
    required this.desc2,
    required this.title3,
    required this.desc3,
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
      title1: 'Better People Suggestions',
      desc1:
          'We have improved how people suggestions work with big under-the-hood changes. This will lead to higher quality suggestions for you to review and tag your entire library quickly.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'A Richer Feed',
      desc2:
          'You will now see new shared albums and new photos added to shared albums in the feed. Share notifications also redirect to feed so you can quickly check out, like and comment on the photos shared with you.',
      title3: 'Redesigned Help & Support',
      desc3:
          'We have made the help and support pages friendlier to use - report bugs, ask a question or raise a feature request. There is also a new section that takes you to our FAQ pages so you can quickly get answers.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Lepší návrhy osob',
      desc1:
          'Vylepšili jsme fungování návrhů osob pomocí velkých změn na pozadí. Díky tomu získáte kvalitnější návrhy, které můžete rychleji zkontrolovat a označit v celé své knihovně.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Bohatší kanál',
      desc2:
          'Ve svém kanálu nyní uvidíte nová sdílená alba i nové fotky přidané do sdílených alb. Oznámení o sdílení vás také přesměrují do kanálu, abyste si mohli sdílené fotky rychle prohlédnout, označit jako oblíbené a komentovat.',
      title3: 'Přepracovaná nápověda a podpora',
      desc3:
          'Stránky nápovědy a podpory jsme zpříjemnili a zjednodušili. Můžete nahlásit chybu, položit otázku nebo požádat o novou funkci. Přibyla také nová sekce s našimi FAQ, kde rychle najdete odpovědi.',
    ),
    'de': ChangeLogStrings(
      title1: 'Bessere Personenvorschläge',
      desc1:
          'Wir haben die Funktionsweise der Personenvorschläge mit umfassenden Änderungen im Hintergrund verbessert. Dadurch erhalten Sie hochwertigere Vorschläge, um Ihre gesamte Mediathek schneller zu prüfen und zu taggen.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Ein vielseitigerer Feed',
      desc2:
          'Im Feed sehen Sie jetzt neue geteilte Alben und neue Fotos, die zu geteilten Alben hinzugefügt wurden. Benachrichtigungen zum Teilen führen jetzt ebenfalls direkt zum Feed, damit Sie die mit Ihnen geteilten Fotos schnell ansehen, liken und kommentieren können.',
      title3: 'Neu gestaltete Hilfe & Support',
      desc3:
          'Wir haben die Hilfe- und Supportseiten benutzerfreundlicher gestaltet. Melden Sie Fehler, stellen Sie Fragen oder senden Sie einen Funktionswunsch. Außerdem gibt es einen neuen Bereich mit unseren FAQ-Seiten, damit Sie schnell Antworten finden.',
    ),
    'es': ChangeLogStrings(
      title1: 'Mejores sugerencias de personas',
      desc1:
          'Hemos mejorado el funcionamiento de las sugerencias de personas con grandes cambios internos. Esto dará lugar a sugerencias de mayor calidad para que puedas revisar y etiquetar rápidamente toda tu biblioteca.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Un feed más completo',
      desc2:
          'Ahora verás en el feed nuevos álbumes compartidos y nuevas fotos añadidas a álbumes compartidos. Las notificaciones de compartición también te redirigen al feed para que puedas ver, dar me gusta y comentar rápidamente las fotos compartidas contigo.',
      title3: 'Ayuda y soporte rediseñados',
      desc3:
          'Hemos hecho que las páginas de ayuda y soporte sean más fáciles de usar: informa de errores, haz una pregunta o solicita una función. También hay una nueva sección que te lleva a nuestras páginas de preguntas frecuentes para que puedas obtener respuestas rápidamente.',
    ),
    'fr': ChangeLogStrings(
      title1: 'De meilleures suggestions de personnes',
      desc1:
          'Nous avons amélioré le fonctionnement des suggestions de personnes grâce à d\'importants changements internes. Cela vous offrira des suggestions de meilleure qualité pour examiner et identifier rapidement toute votre photothèque.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Un fil plus riche',
      desc2:
          'Vous verrez désormais dans le fil les nouveaux albums partagés ainsi que les nouvelles photos ajoutées aux albums partagés. Les notifications de partage redirigent aussi vers le fil pour que vous puissiez rapidement consulter, aimer et commenter les photos partagées avec vous.',
      title3: 'Aide et support repensés',
      desc3:
          'Nous avons rendu les pages d\'aide et de support plus agréables à utiliser : signalez un bug, posez une question ou demandez une fonctionnalité. Une nouvelle section vous amène aussi vers nos FAQ pour obtenir rapidement des réponses.',
    ),
    'it': ChangeLogStrings(
      title1: 'Suggerimenti sulle persone migliorati',
      desc1:
          'Abbiamo migliorato il funzionamento dei suggerimenti sulle persone con grandi cambiamenti interni. Questo porterà suggerimenti di qualità superiore, così potrai rivedere e taggare rapidamente tutta la tua libreria.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Un feed più ricco',
      desc2:
          'Ora nel feed vedrai nuovi album condivisi e nuove foto aggiunte agli album condivisi. Anche le notifiche di condivisione ora reindirizzano al feed, così puoi vedere rapidamente, mettere mi piace e commentare le foto condivise con te.',
      title3: 'Aiuto e supporto riprogettati',
      desc3:
          'Abbiamo reso le pagine di aiuto e supporto più semplici da usare: segnala bug, fai una domanda o invia una richiesta di funzionalità. C\'è anche una nuova sezione che ti porta alle nostre pagine FAQ per trovare rapidamente le risposte.',
    ),
    'ja': ChangeLogStrings(
      title1: '人物候補がさらに向上',
      desc1:
          '人物候補の仕組みを大幅な内部改善で強化しました。これにより候補の品質が向上し、ライブラリ全体をすばやく確認してタグ付けしやすくなります。',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'さらに充実したフィード',
      desc2:
          'フィードに新しい共有アルバムや、共有アルバムに追加された新しい写真が表示されるようになりました。共有通知からもフィードに移動できるため、共有された写真をすぐに確認し、いいねやコメントがしやすくなります。',
      title3: 'ヘルプとサポートを刷新',
      desc3:
          'ヘルプとサポートのページをより使いやすくしました。不具合の報告、質問、機能リクエストがしやすくなっています。FAQページへ移動できる新しいセクションも追加され、すばやく答えを見つけられます。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Betere suggesties voor personen',
      desc1:
          'We hebben de manier waarop suggesties voor personen werken verbeterd met grote wijzigingen achter de schermen. Daardoor krijg je betere suggesties om je hele bibliotheek snel te controleren en te taggen.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Een rijkere feed',
      desc2:
          'Je ziet nu nieuwe gedeelde albums en nieuwe foto\'s die aan gedeelde albums zijn toegevoegd in je feed. Meldingen over delen sturen je nu ook door naar de feed, zodat je gedeelde foto\'s snel kunt bekijken, liken en erop kunt reageren.',
      title3: 'Opnieuw ontworpen hulp en ondersteuning',
      desc3:
          'We hebben de hulp- en ondersteuningspagina\'s gebruiksvriendelijker gemaakt: meld bugs, stel een vraag of dien een functieverzoek in. Er is ook een nieuwe sectie die je naar onze FAQ-pagina\'s brengt, zodat je snel antwoorden kunt vinden.',
    ),
    'no': ChangeLogStrings(
      title1: 'Bedre personforslag',
      desc1:
          'Vi har forbedret hvordan personforslag fungerer med store endringer under panseret. Dette vil gi deg forslag av høyere kvalitet, slik at du raskt kan gå gjennom og tagge hele biblioteket ditt.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'En rikere feed',
      desc2:
          'Du vil nå se nye delte album og nye bilder lagt til i delte album i feeden. Delingsvarsler tar deg også til feeden, slik at du raskt kan se, like og kommentere bildene som er delt med deg.',
      title3: 'Nydesignet hjelp og støtte',
      desc3:
          'Vi har gjort hjelpe- og støttesidene enklere å bruke. Rapporter feil, still et spørsmål eller send inn et funksjonsønske. Det finnes også en ny seksjon som tar deg til FAQ-sidene våre, slik at du raskt kan finne svar.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Lepsze sugestie osób',
      desc1:
          'Ulepszyliśmy działanie sugestii osób dzięki dużym zmianom pod maską. Dzięki temu otrzymasz trafniejsze sugestie, aby szybciej przejrzeć i oznaczyć całą swoją bibliotekę.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Bogatszy kanał',
      desc2:
          'W kanale zobaczysz teraz nowe udostępnione albumy oraz nowe zdjęcia dodane do udostępnionych albumów. Powiadomienia o udostępnieniu również przekierują Cię do kanału, aby szybko obejrzeć, polubić i skomentować udostępnione Ci zdjęcia.',
      title3: 'Przeprojektowana pomoc i wsparcie',
      desc3:
          'Ułatwiliśmy korzystanie ze stron pomocy i wsparcia: zgłoś błąd, zadaj pytanie lub poproś o nową funkcję. Jest też nowa sekcja prowadząca do naszych stron FAQ, dzięki czemu szybko znajdziesz odpowiedzi.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Melhores sugestões de pessoas',
      desc1:
          'Melhoramos como as sugestões de pessoas funcionam com grandes mudanças internas. Isso resultará em sugestões de maior qualidade para você revisar e marcar toda a sua biblioteca rapidamente.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Um feed mais rico',
      desc2:
          'Agora você verá no feed novos álbuns compartilhados e novas fotos adicionadas a álbuns compartilhados. As notificações de compartilhamento também redirecionam para o feed para que você possa ver, curtir e comentar rapidamente as fotos compartilhadas com você.',
      title3: 'Ajuda e suporte redesenhados',
      desc3:
          'Deixamos as páginas de ajuda e suporte mais fáceis de usar: relate bugs, faça uma pergunta ou envie uma solicitação de recurso. Há também uma nova seção que leva você às nossas páginas de FAQ para encontrar respostas rapidamente.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Melhores sugestões de pessoas',
      desc1:
          'Melhorámos a forma como as sugestões de pessoas funcionam com grandes alterações internas. Isto vai resultar em sugestões de melhor qualidade para rever e etiquetar rapidamente toda a sua biblioteca.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Um feed mais rico',
      desc2:
          'Passará agora a ver no feed novos álbuns partilhados e novas fotografias adicionadas a álbuns partilhados. As notificações de partilha também redirecionam para o feed para que possa ver, gostar e comentar rapidamente as fotografias partilhadas consigo.',
      title3: 'Ajuda e suporte redesenhados',
      desc3:
          'Tornámos as páginas de ajuda e suporte mais fáceis de usar: reporte erros, faça uma pergunta ou peça uma funcionalidade. Existe também uma nova secção que o leva às nossas páginas de FAQ para encontrar respostas rapidamente.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Sugestii mai bune pentru persoane',
      desc1:
          'Am îmbunătățit modul în care funcționează sugestiile pentru persoane prin schimbări majore în culise. Astfel vei primi sugestii de calitate mai bună pentru a revizui și eticheta rapid întreaga bibliotecă.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Un flux mai bogat',
      desc2:
          'Acum vei vedea în flux albume partajate noi și fotografii noi adăugate în albume partajate. Notificările de partajare te redirecționează și ele către flux, ca să poți vedea rapid, aprecia și comenta fotografiile partajate cu tine.',
      title3: 'Ajutor și suport reproiectate',
      desc3:
          'Am făcut paginile de ajutor și suport mai prietenoase și mai ușor de folosit: raportează erori, pune o întrebare sau trimite o cerere de funcționalitate. Există și o secțiune nouă care te duce la paginile noastre FAQ ca să găsești rapid răspunsuri.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Улучшенные подсказки по людям',
      desc1:
          'Мы улучшили работу подсказок по людям с помощью крупных внутренних изменений. Благодаря этому вы будете получать более качественные подсказки, чтобы быстрее просматривать и отмечать тегами всю свою медиатеку.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Более насыщенная лента',
      desc2:
          'Теперь в ленте будут отображаться новые общие альбомы и новые фотографии, добавленные в общие альбомы. Уведомления о совместном доступе также будут перенаправлять в ленту, чтобы вы могли быстро просматривать, лайкать и комментировать фотографии, которыми с вами поделились.',
      title3: 'Обновленные помощь и поддержка',
      desc3:
          'Мы сделали страницы помощи и поддержки более удобными: сообщайте об ошибках, задавайте вопросы или отправляйте запросы на новые функции. Также появился новый раздел, который ведет на страницы FAQ, чтобы вы могли быстро находить ответы.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Daha iyi kişi önerileri',
      desc1:
          'Kişi önerilerinin çalışma şeklini, arka planda yaptığımız büyük değişikliklerle iyileştirdik. Bu sayede tüm arşivinizi hızla gözden geçirip etiketleyebilmeniz için daha kaliteli öneriler göreceksiniz.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Daha zengin bir akış',
      desc2:
          'Artık akışta yeni paylaşılan albümleri ve paylaşılan albümlere eklenen yeni fotoğrafları göreceksiniz. Paylaşım bildirimleri de sizi akışa yönlendirecek, böylece sizinle paylaşılan fotoğrafları hızlıca inceleyebilir, beğenebilir ve yorumlayabilirsiniz.',
      title3: 'Yeniden tasarlanan Yardım ve Destek',
      desc3:
          'Yardım ve destek sayfalarını kullanmayı daha kolay hale getirdik: hata bildirin, soru sorun veya özellik isteğinde bulunun. Ayrıca SSS sayfalarımıza götüren yeni bir bölüm de var, böylece hızlıca yanıt bulabilirsiniz.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Кращі підказки щодо людей',
      desc1:
          'Ми покращили роботу підказок щодо людей завдяки великим внутрішнім змінам. Це дасть вам якісніші підказки, щоб ви могли швидко переглядати й позначати тегами всю свою бібліотеку.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Багатша стрічка',
      desc2:
          'Тепер у стрічці ви бачитимете нові спільні альбоми та нові фото, додані до спільних альбомів. Сповіщення про поширення також перенаправлятимуть до стрічки, щоб ви могли швидко переглядати, вподобати й коментувати фото, якими з вами поділилися.',
      title3: 'Оновлені довідка та підтримка',
      desc3:
          'Ми зробили сторінки довідки та підтримки зручнішими: повідомляйте про помилки, ставте запитання або надсилайте запити на нові функції. Також з\'явився новий розділ, який веде до наших сторінок FAQ, щоб ви могли швидко знаходити відповіді.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Gợi ý nhận diện người tốt hơn',
      desc1:
          'Chúng tôi đã cải thiện cách hoạt động của gợi ý người bằng những thay đổi lớn ở phía sau. Điều này sẽ mang lại các gợi ý chất lượng cao hơn để bạn nhanh chóng xem lại và gắn thẻ toàn bộ thư viện của mình.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Bảng tin phong phú hơn',
      desc2:
          'Giờ đây bạn sẽ thấy các album chia sẻ mới và các ảnh mới được thêm vào album chia sẻ trong bảng tin. Thông báo chia sẻ cũng sẽ chuyển hướng đến bảng tin để bạn có thể nhanh chóng xem, thích và bình luận về những ảnh được chia sẻ với mình.',
      title3: 'Trợ giúp và hỗ trợ được thiết kế lại',
      desc3:
          'Chúng tôi đã làm cho các trang trợ giúp và hỗ trợ thân thiện hơn khi sử dụng: báo lỗi, đặt câu hỏi hoặc gửi yêu cầu tính năng. Ngoài ra còn có một mục mới đưa bạn tới các trang FAQ để nhanh chóng tìm câu trả lời.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '更好的人物建议',
      desc1: '我们通过大量底层改进优化了人物建议的工作方式。这将带来更高质量的建议，帮助你快速查看并标记整个资料库。',
      desc1Item1: '',
      desc1Item2: '',
      title2: '更丰富的动态',
      desc2:
          '现在你会在动态中看到新的共享相册，以及添加到共享相册中的新照片。共享通知也会跳转到动态，方便你快速查看、点赞和评论分享给你的照片。',
      title3: '重新设计的帮助与支持',
      desc3:
          '我们让帮助与支持页面变得更易用，你可以在那里报告问题、提出疑问或提交功能请求。我们还新增了一个版块，带你前往常见问题页面，方便你快速找到答案。',
    ),
  };

  static const Map<String, ChangeLogStrings> _offlineTranslations = {
    'en': ChangeLogStrings(
      title1: '',
      desc1: '',
      desc1Item1: '',
      desc1Item2: '',
      title2: '',
      desc2: '',
      title3: '',
      desc3: '',
    ),
  };
}
