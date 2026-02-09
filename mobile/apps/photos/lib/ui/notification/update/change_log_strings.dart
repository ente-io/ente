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
      title1: 'Clean up hidden',
      desc1:
          'Two new actions are available for managing hidden files on mobile',
      desc1Item1:
          'Clean up hidden files: Removes hidden files from any non-hidden albums they also belong to, so they only live in Hidden.',
      desc1Item2:
          'Delete hidden files from device: Removes local copies of hidden files from your device to free up space.',
      title2: 'Hide shared albums',
      desc2: 'You can now hide albums that have been shared with you.',
      title3: 'Device album search',
      desc3: 'Now easily search within your device folders.',
    ),
    'cs': ChangeLogStrings(
      title1: 'Vyčistit skryté',
      desc1: 'Dvě nové akce pro správu skrytých souborů na mobilním zařízení',
      desc1Item1:
          'Vyčistit skryté soubory: Odebere skryté soubory ze všech neskrytých alb, ve kterých se také nacházejí, takže zůstanou pouze ve složce Skryté.',
      desc1Item2:
          'Smazat skryté soubory ze zařízení: Odstraní místní kopie skrytých souborů z vašeho zařízení a uvolní tak místo.',
      title2: 'Skrýt sdílená alba',
      desc2: 'Nyní můžete skrýt alba, která s vámi byla sdílena.',
      title3: 'Hledání v albech zařízení',
      desc3: 'Nyní můžete snadno vyhledávat ve složkách zařízení.',
    ),
    'de': ChangeLogStrings(
      title1: 'Versteckte aufräumen',
      desc1:
          'Zwei neue Aktionen zur Verwaltung versteckter Dateien auf dem Mobilgerät',
      desc1Item1:
          'Versteckte Dateien aufräumen: Entfernt versteckte Dateien aus allen nicht versteckten Alben, in denen sie sich ebenfalls befinden, sodass sie nur noch unter "Versteckt" vorhanden sind.',
      desc1Item2:
          'Versteckte Dateien vom Gerät löschen: Entfernt lokale Kopien versteckter Dateien von Ihrem Gerät, um Speicherplatz freizugeben.',
      title2: 'Geteilte Alben ausblenden',
      desc2: 'Sie können jetzt Alben ausblenden, die mit Ihnen geteilt wurden.',
      title3: 'Suche in Gerätealben',
      desc3: 'Durchsuchen Sie jetzt ganz einfach Ihre Geräteordner.',
    ),
    'es': ChangeLogStrings(
      title1: 'Limpiar ocultos',
      desc1:
          'Dos nuevas acciones disponibles para gestionar archivos ocultos en el móvil',
      desc1Item1:
          'Limpiar archivos ocultos: Elimina los archivos ocultos de cualquier álbum no oculto al que también pertenezcan, de modo que solo permanezcan en Ocultos.',
      desc1Item2:
          'Eliminar archivos ocultos del dispositivo: Elimina las copias locales de los archivos ocultos de tu dispositivo para liberar espacio.',
      title2: 'Ocultar álbumes compartidos',
      desc2: 'Ahora puedes ocultar álbumes que han sido compartidos contigo.',
      title3: 'Búsqueda en álbumes del dispositivo',
      desc3: 'Ahora busca fácilmente dentro de las carpetas de tu dispositivo.',
    ),
    'fr': ChangeLogStrings(
      title1: 'Nettoyer les masqués',
      desc1:
          'Deux nouvelles actions pour gérer les fichiers masqués sur mobile',
      desc1Item1:
          "Nettoyer les fichiers masqués : Retire les fichiers masqués de tous les albums non masqués auxquels ils appartiennent également, afin qu'ils ne restent que dans Masqués.",
      desc1Item2:
          "Supprimer les fichiers masqués de l'appareil : Supprime les copies locales des fichiers masqués de votre appareil pour libérer de l'espace.",
      title2: 'Masquer les albums partagés',
      desc2:
          'Vous pouvez désormais masquer les albums qui ont été partagés avec vous.',
      title3: "Recherche dans les albums de l'appareil",
      desc3: 'Recherchez facilement dans les dossiers de votre appareil.',
    ),
    'it': ChangeLogStrings(
      title1: 'Pulisci nascosti',
      desc1:
          'Due nuove azioni disponibili per gestire i file nascosti su dispositivo mobile',
      desc1Item1:
          'Pulisci file nascosti: Rimuove i file nascosti da qualsiasi album non nascosto a cui appartengono, in modo che restino solo nella sezione Nascosti.',
      desc1Item2:
          'Elimina file nascosti dal dispositivo: Rimuove le copie locali dei file nascosti dal dispositivo per liberare spazio.',
      title2: 'Nascondi album condivisi',
      desc2: 'Ora puoi nascondere gli album che sono stati condivisi con te.',
      title3: 'Ricerca negli album del dispositivo',
      desc3: 'Ora puoi cercare facilmente nelle cartelle del dispositivo.',
    ),
    'ja': ChangeLogStrings(
      title1: '非表示を整理',
      desc1: 'モバイルで非表示ファイルを管理するための2つの新しい操作が利用可能になりました',
      desc1Item1: '非表示ファイルを整理: 非表示ファイルが属している非表示以外のアルバムから削除し、「非表示」にのみ残るようにします。',
      desc1Item2: '非表示ファイルをデバイスから削除: 非表示ファイルのローカルコピーをデバイスから削除し、空き容量を確保します。',
      title2: '共有アルバムを非表示',
      desc2: '共有されたアルバムを非表示にできるようになりました。',
      title3: 'デバイスアルバム検索',
      desc3: 'デバイスのフォルダ内を簡単に検索できるようになりました。',
    ),
    'nl': ChangeLogStrings(
      title1: 'Verborgen opruimen',
      desc1:
          'Twee nieuwe acties zijn beschikbaar voor het beheren van verborgen bestanden op mobiel',
      desc1Item1:
          'Verborgen bestanden opruimen: Verwijdert verborgen bestanden uit alle niet-verborgen albums waar ze ook in staan, zodat ze alleen in Verborgen staan.',
      desc1Item2:
          'Verborgen bestanden van apparaat verwijderen: Verwijdert lokale kopieën van verborgen bestanden van je apparaat om ruimte vrij te maken.',
      title2: 'Gedeelde albums verbergen',
      desc2: 'Je kunt nu albums verbergen die met je zijn gedeeld.',
      title3: 'Zoeken in apparaatalbums',
      desc3: 'Zoek nu eenvoudig binnen je apparaatmappen.',
    ),
    'no': ChangeLogStrings(
      title1: 'Rydd opp i skjulte',
      desc1:
          'To nye handlinger er tilgjengelige for å administrere skjulte filer på mobil',
      desc1Item1:
          'Rydd opp i skjulte filer: Fjerner skjulte filer fra alle ikke-skjulte album de også tilhører, slik at de kun finnes i Skjult.',
      desc1Item2:
          'Slett skjulte filer fra enheten: Fjerner lokale kopier av skjulte filer fra enheten din for å frigjøre plass.',
      title2: 'Skjul delte album',
      desc2: 'Du kan nå skjule album som har blitt delt med deg.',
      title3: 'Søk i enhetsalbum',
      desc3: 'Søk nå enkelt i enhetsmappene dine.',
    ),
    'pl': ChangeLogStrings(
      title1: 'Porządkowanie ukrytych',
      desc1:
          'Dwie nowe akcje są dostępne do zarządzania ukrytymi plikami na urządzeniu mobilnym',
      desc1Item1:
          'Uporządkuj ukryte pliki: Usuwa ukryte pliki ze wszystkich nieukrytych albumów, do których również należą, tak aby znajdowały się tylko w sekcji Ukryte.',
      desc1Item2:
          'Usuń ukryte pliki z urządzenia: Usuwa lokalne kopie ukrytych plików z urządzenia, aby zwolnić miejsce.',
      title2: 'Ukryj udostępnione albumy',
      desc2: 'Możesz teraz ukryć albumy, które zostały Ci udostępnione.',
      title3: 'Wyszukiwanie w albumach urządzenia',
      desc3: 'Teraz łatwo wyszukuj w folderach urządzenia.',
    ),
    'pt_BR': ChangeLogStrings(
      title1: 'Limpeza de ocultos',
      desc1:
          'Duas novas ações estão disponíveis para gerenciar arquivos ocultos no celular',
      desc1Item1:
          'Limpar arquivos ocultos: Remove os arquivos ocultos de todos os álbuns não ocultos aos quais eles também pertencem, para que fiquem apenas na seção Ocultos.',
      desc1Item2:
          'Excluir arquivos ocultos do dispositivo: Remove as cópias locais dos arquivos ocultos do seu dispositivo para liberar espaço.',
      title2: 'Ocultar álbuns compartilhados',
      desc2:
          'Agora você pode ocultar álbuns que foram compartilhados com você.',
      title3: 'Busca em álbuns do dispositivo',
      desc3: 'Agora pesquise facilmente dentro das pastas do seu dispositivo.',
    ),
    'pt_PT': ChangeLogStrings(
      title1: 'Limpeza de ocultos',
      desc1:
          'Duas novas ações estão disponíveis para gerir ficheiros ocultos no telemóvel',
      desc1Item1:
          'Limpar ficheiros ocultos: Remove os ficheiros ocultos de todos os álbuns não ocultos a que também pertencem, para que fiquem apenas na secção Ocultos.',
      desc1Item2:
          'Eliminar ficheiros ocultos do dispositivo: Remove as cópias locais dos ficheiros ocultos do seu dispositivo para libertar espaço.',
      title2: 'Ocultar álbuns partilhados',
      desc2: 'Agora pode ocultar álbuns que foram partilhados consigo.',
      title3: 'Pesquisa em álbuns do dispositivo',
      desc3: 'Agora pesquise facilmente dentro das pastas do seu dispositivo.',
    ),
    'ro': ChangeLogStrings(
      title1: 'Curățare ascunse',
      desc1:
          'Două acțiuni noi sunt disponibile pentru gestionarea fișierelor ascunse pe mobil',
      desc1Item1:
          'Curățare fișiere ascunse: Elimină fișierele ascunse din toate albumele neascunse din care fac parte, astfel încât să existe doar în secțiunea Ascunse.',
      desc1Item2:
          'Ștergere fișiere ascunse de pe dispozitiv: Elimină copiile locale ale fișierelor ascunse de pe dispozitiv pentru a elibera spațiu.',
      title2: 'Ascundere albume partajate',
      desc2: 'Acum poți ascunde albumele care au fost partajate cu tine.',
      title3: 'Căutare în albumele dispozitivului',
      desc3: 'Acum poți căuta cu ușurință în folderele dispozitivului.',
    ),
    'ru': ChangeLogStrings(
      title1: 'Очистка скрытых',
      desc1:
          'Два новых действия доступны для управления скрытыми файлами на мобильном устройстве',
      desc1Item1:
          'Очистить скрытые файлы: Удаляет скрытые файлы из всех нескрытых альбомов, в которых они также находятся, чтобы они оставались только в разделе «Скрытые».',
      desc1Item2:
          'Удалить скрытые файлы с устройства: Удаляет локальные копии скрытых файлов с вашего устройства для освобождения места.',
      title2: 'Скрытие общих альбомов',
      desc2: 'Теперь вы можете скрывать альбомы, которыми с вами поделились.',
      title3: 'Поиск по альбомам устройства',
      desc3: 'Теперь легко ищите в папках вашего устройства.',
    ),
    'tr': ChangeLogStrings(
      title1: 'Gizlileri temizle',
      desc1:
          'Mobilde gizli dosyaları yönetmek için iki yeni işlem kullanılabilir',
      desc1Item1:
          'Gizli dosyaları temizle: Gizli dosyaları, ait oldukları gizli olmayan albümlerden kaldırır, böylece yalnızca Gizli bölümünde kalırlar.',
      desc1Item2:
          'Gizli dosyaları cihazdan sil: Yer açmak için gizli dosyaların yerel kopyalarını cihazınızdan kaldırır.',
      title2: 'Paylaşılan albümleri gizle',
      desc2: 'Artık sizinle paylaşılan albümleri gizleyebilirsiniz.',
      title3: 'Cihaz albümünde arama',
      desc3: 'Artık cihaz klasörlerinizde kolayca arama yapın.',
    ),
    'uk': ChangeLogStrings(
      title1: 'Керування прихованими',
      desc1: 'Дві нові дії для керування прихованими файлами на мобільному',
      desc1Item1:
          'Очистити приховані файли: Видаляє приховані файли з усіх не прихованих альбомів, до яких вони також належать, щоб вони залишалися лише в розділі «Приховані».',
      desc1Item2:
          'Видалити приховані файли з пристрою: Видаляє локальні копії прихованих файлів з вашого пристрою, щоб звільнити місце.',
      title2: 'Приховування спільних альбомів',
      desc2: 'Тепер ви можете приховувати альбоми, якими з вами поділилися.',
      title3: 'Пошук в альбомах пристрою',
      desc3: 'Тепер легко шукайте у папках вашого пристрою.',
    ),
    'vi': ChangeLogStrings(
      title1: 'Dọn dẹp mục ẩn',
      desc1: 'Hai thao tác mới để quản lý các tệp ẩn trên thiết bị di động',
      desc1Item1:
          'Dọn dẹp tệp ẩn: Xóa các tệp ẩn khỏi mọi album không ẩn mà chúng cũng thuộc về, để chúng chỉ nằm trong mục Ẩn.',
      desc1Item2:
          'Xóa tệp ẩn khỏi thiết bị: Xóa bản sao cục bộ của các tệp ẩn khỏi thiết bị để giải phóng dung lượng.',
      title2: 'Ẩn album được chia sẻ',
      desc2: 'Giờ đây bạn có thể ẩn các album đã được chia sẻ với bạn.',
      title3: 'Tìm kiếm trong album thiết bị',
      desc3:
          'Giờ đây bạn có thể dễ dàng tìm kiếm trong các thư mục trên thiết bị.',
    ),
    'zh_CN': ChangeLogStrings(
      title1: '清理隐藏项',
      desc1: '移动端新增两项操作，用于管理隐藏文件',
      desc1Item1: '清理隐藏文件：将隐藏文件从其所属的所有非隐藏相册中移除，使其仅保留在"已隐藏"中。',
      desc1Item2: '从设备中删除隐藏文件：删除隐藏文件在设备上的本地副本，以释放存储空间。',
      title2: '隐藏共享相册',
      desc2: '您现在可以隐藏他人与您共享的相册。',
      title3: '设备相册搜索',
      desc3: '现在可以轻松搜索设备文件夹中的内容。',
    ),
  };
}
