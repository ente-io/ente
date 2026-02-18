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

  const ChangeLogStrings({
    required this.title1,
    required this.desc1,
    required this.desc1Item1,
    required this.desc1Item2,
    required this.title2,
    required this.desc2,
    required this.title3,
    required this.desc3,
  });

  static ChangeLogStrings forLocale(Locale locale) {
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    return _translations[key] ??
        _translations[locale.languageCode] ??
        _translations['en']!;
  }

  static const Map<String, ChangeLogStrings> _translations = {
    'en': ChangeLogStrings(
      title1: 'Faster search and discovery',
      desc1:
          'Search is now even faster. We have done some improvements on our embeddings DB to make it feel instant',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Shared photos in feed',
      desc2:
          'Photos added to shared albums would now appear in your feed, making it easier to find recently shared photos and comment on them',
      title3: '',
      desc3: '',
    ),
    'cs': ChangeLogStrings(
      title1: 'Rychlejší vyhledávání a objevování',
      desc1: 'Vyhledávání je nyní ještě rychlejší díky vylepšením na pozadí.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Sdílené fotky v kanálu',
      desc2:
          'Fotky přidané do sdílených alb se nyní zobrazí ve vašem kanálu, takže snáze najdete nedávno sdílené fotky a můžete je komentovat.',
      title3: '',
      desc3: '',
    ),
    'de': ChangeLogStrings(
      title1: 'Schnellere Suche und Entdeckung',
      desc1:
          'Die Suche ist jetzt noch schneller dank Verbesserungen im Hintergrund.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Geteilte Fotos im Feed',
      desc2:
          'Fotos, die zu geteilten Alben hinzugefügt werden, erscheinen jetzt in Ihrem Feed. So finden Sie kürzlich geteilte Fotos leichter und können sie kommentieren.',
      title3: '',
      desc3: '',
    ),
    'es': ChangeLogStrings(
      title1: 'Búsqueda y descubrimiento más rápidos',
      desc1: 'La búsqueda ahora es aún más rápida gracias a mejoras internas.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Fotos compartidas en el feed',
      desc2:
          'Las fotos añadidas a álbumes compartidos ahora aparecerán en tu feed, lo que facilita encontrar fotos compartidas recientemente y comentarlas.',
      title3: '',
      desc3: '',
    ),
    'fr': ChangeLogStrings(
      title1: 'Recherche et découverte plus rapides',
      desc1:
          'La recherche est désormais encore plus rapide grâce à des améliorations internes.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Photos partagées dans le fil',
      desc2:
          'Les photos ajoutées aux albums partagés apparaissent désormais dans votre fil, ce qui facilite la recherche des photos récemment partagées et leur commentaire.',
      title3: '',
      desc3: '',
    ),
    'it': ChangeLogStrings(
      title1: 'Ricerca e scoperta più veloci',
      desc1:
          'La ricerca ora è ancora più veloce grazie a miglioramenti interni.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Foto condivise nel feed',
      desc2:
          'Le foto aggiunte agli album condivisi ora appariranno nel tuo feed, così è più facile trovare le foto condivise di recente e commentarle.',
      title3: '',
      desc3: '',
    ),
    'ja': ChangeLogStrings(
      title1: '検索と発見がさらに高速に',
      desc1: '検索がさらに高速になりました。内部的な改善により、ほぼ瞬時に結果が表示されます。',
      desc1Item1: '',
      desc1Item2: '',
      title2: '共有写真がフィードに表示',
      desc2: '共有アルバムに追加された写真がフィードに表示されるようになり、最近共有された写真を見つけてコメントしやすくなりました。',
      title3: '',
      desc3: '',
    ),
    'nl': ChangeLogStrings(
      title1: 'Sneller zoeken en ontdekken',
      desc1:
          'Zoeken is nu nog sneller dankzij verbeteringen achter de schermen.',
      desc1Item1: '',
      desc1Item2: '',
      title2: "Gedeelde foto's in je feed",
      desc2:
          "Foto's die aan gedeelde albums worden toegevoegd, verschijnen nu in je feed. Zo vind je recent gedeelde foto's makkelijker en kun je erop reageren.",
      title3: '',
      desc3: '',
    ),
    'no': ChangeLogStrings(
      title1: 'Raskere søk og oppdagelse',
      desc1: 'Søk er nå enda raskere takket være forbedringer i bakgrunnen.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Delte bilder i feeden',
      desc2:
          'Bilder som legges til i delte album vises nå i feeden din, slik at det blir enklere å finne nylig delte bilder og kommentere dem.',
      title3: '',
      desc3: '',
    ),
    'pl': ChangeLogStrings(
      title1: 'Szybsze wyszukiwanie i odkrywanie',
      desc1:
          'Wyszukiwanie jest teraz jeszcze szybsze dzięki usprawnieniom działającym w tle.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Udostępnione zdjęcia w kanale',
      desc2:
          'Zdjęcia dodane do udostępnionych albumów będą teraz pojawiać się w Twoim kanale, dzięki czemu łatwiej znajdziesz ostatnio udostępnione zdjęcia i je skomentujesz.',
      title3: '',
      desc3: '',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Busca e descoberta mais rápidas',
      desc1: 'A busca está ainda mais rápida graças a melhorias internas.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Fotos compartilhadas no feed',
      desc2:
          'As fotos adicionadas a álbuns compartilhados agora aparecem no seu feed, facilitando encontrar fotos compartilhadas recentemente e comentá-las.',
      title3: '',
      desc3: '',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Pesquisa e descoberta mais rápidas',
      desc1:
          'A pesquisa está agora ainda mais rápida graças a melhorias internas.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Fotos partilhadas no feed',
      desc2:
          'As fotos adicionadas a álbuns partilhados passam agora a aparecer no seu feed, facilitando encontrar fotos partilhadas recentemente e comentá-las.',
      title3: '',
      desc3: '',
    ),
    'ro': ChangeLogStrings(
      title1: 'Căutare și descoperire mai rapide',
      desc1:
          'Căutarea este acum și mai rapidă datorită îmbunătățirilor din culise.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Fotografii partajate în flux',
      desc2:
          'Fotografiile adăugate în albume partajate apar acum în fluxul tău, ceea ce face mai ușor să găsești fotografiile partajate recent și să le comentezi.',
      title3: '',
      desc3: '',
    ),
    'ru': ChangeLogStrings(
      title1: 'Более быстрый поиск и просмотр',
      desc1: 'Поиск стал ещё быстрее благодаря внутренним улучшениям.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Общие фото в ленте',
      desc2:
          'Фотографии, добавленные в общие альбомы, теперь появляются в вашей ленте, поэтому недавние общие фото легче найти и прокомментировать.',
      title3: '',
      desc3: '',
    ),
    'tr': ChangeLogStrings(
      title1: 'Daha hızlı arama ve keşif',
      desc1:
          'Arama artık daha da hızlı; bunun için arka planda iyileştirmeler yaptık.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Akışta paylaşılan fotoğraflar',
      desc2:
          'Paylaşılan albümlere eklenen fotoğraflar artık akışınızda görünecek; böylece yakın zamanda paylaşılan fotoğrafları bulup yorum yapmak daha kolay olacak.',
      title3: '',
      desc3: '',
    ),
    'uk': ChangeLogStrings(
      title1: 'Швидший пошук і відкриття',
      desc1: 'Пошук став ще швидшим завдяки внутрішнім покращенням.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Спільні фото у стрічці',
      desc2:
          'Фото, додані до спільних альбомів, тепер з’являються у вашій стрічці, тож нещодавно поширені фото легше знайти й прокоментувати.',
      title3: '',
      desc3: '',
    ),
    'vi': ChangeLogStrings(
      title1: 'Tìm kiếm và khám phá nhanh hơn',
      desc1: 'Tìm kiếm giờ đây còn nhanh hơn nữa nhờ các cải tiến ở phía sau.',
      desc1Item1: '',
      desc1Item2: '',
      title2: 'Ảnh chia sẻ trong bảng tin',
      desc2:
          'Ảnh được thêm vào album chia sẻ giờ sẽ xuất hiện trong bảng tin của bạn, giúp bạn dễ tìm ảnh mới được chia sẻ và bình luận hơn.',
      title3: '',
      desc3: '',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '更快的搜索与发现',
      desc1: '搜索现在更快了，这得益于我们在后台所做的优化。',
      desc1Item1: '',
      desc1Item2: '',
      title2: '动态中显示共享照片',
      desc2: '添加到共享相册的照片现在会显示在你的动态中，让你更容易找到最近共享的照片并进行评论。',
      title3: '',
      desc3: '',
    ),
  };
}
