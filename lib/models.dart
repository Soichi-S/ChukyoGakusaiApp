// festival.json をアプリ内で扱うための型定義。
// JSON の構造は data/README.md を参照。

typedef Json = Map<String, dynamic>;

List<T> _list<T>(Object? raw, T Function(Json) f) =>
    (raw as List? ?? const []).map((e) => f(e as Json)).toList();

List<String> _strings(Object? raw) =>
    (raw as List? ?? const []).map((e) => e.toString()).toList();

class FestivalDay {
  final String date;
  final String label;
  final String open;
  final String close;

  FestivalDay.fromJson(Json j)
      : date = j['date'],
        label = j['label'],
        open = j['open'],
        close = j['close'];

  /// タブ表示用の短いラベル（例: 11/1(土)）
  String get shortLabel {
    final m = RegExp(r'(\d+)月(\d+)日(\(.\))').firstMatch(label);
    return m == null ? label : '${m[1]}/${m[2]}${m[3]}';
  }
}

class Edition {
  final int year;
  final int number;
  final String name;
  final String campus;
  final String themeKanji;
  final String themeReading;
  final String? coverImage;
  final List<FestivalDay> days;

  Edition.fromJson(Json j)
      : year = j['year'],
        number = j['number'],
        name = j['name'],
        campus = j['campus'] ?? '',
        themeKanji = j['theme']?['kanji'] ?? '',
        themeReading = j['theme']?['reading'] ?? '',
        coverImage = j['coverImage'],
        days = _list(j['days'], FestivalDay.fromJson);

  FestivalDay? day(String date) =>
      days.where((d) => d.date == date).firstOrNull;
}

class Notice {
  final String id;
  final String title;
  final String body;
  final List<String> relatedEventIds;

  Notice.fromJson(Json j)
      : id = j['id'],
        title = j['title'],
        body = j['body'],
        relatedEventIds = _strings(j['relatedEventIds']);
}

class Greeting {
  final String role;
  final String name;
  final String body;

  Greeting.fromJson(Json j)
      : role = j['role'],
        name = j['name'],
        body = j['body'];
}

class Rule {
  final String icon;
  final String text;

  Rule.fromJson(Json j)
      : icon = j['icon'],
        text = j['text'];
}

class TimeRange {
  final String date;
  final String start;
  final String end;

  TimeRange.fromJson(Json j)
      : date = j['date'],
        start = j['start'],
        end = j['end'];
}

class GoodsItem {
  final String name;
  final List<({String label, int yen})> prices;
  final String place;
  final String? note;
  final String? image;

  GoodsItem.fromJson(Json j)
      : name = j['name'],
        prices = (j['prices'] as List)
            .map((p) => (label: p['label'] as String, yen: p['yen'] as int))
            .toList(),
        place = j['place'],
        note = j['note'],
        image = j['image'];
}

class Goods {
  final List<TimeRange> hours;
  final List<GoodsItem> items;

  Goods.fromJson(Json j)
      : hours = _list(j['hours'], TimeRange.fromJson),
        items = _list(j['items'], GoodsItem.fromJson);
}

class Venue {
  final String id;
  final String name;
  final String? building;
  final String? floor;
  final String? note;

  /// 詳細画面に「体育館への行き方」への導線を出すか
  final bool showGymDirections;

  Venue.fromJson(Json j)
      : id = j['id'],
        name = j['name'],
        building = j['building'],
        floor = j['floor'],
        note = j['note'],
        showGymDirections = j['showGymDirections'] ?? false;

  String get fullName =>
      [building, floor, name].whereType<String>().join(' ');
}

class Category {
  final String id;
  final String name;

  Category.fromJson(Json j)
      : id = j['id'],
        name = j['name'];
}

class Sns {
  final String type;
  final String handle;

  Sns.fromJson(Json j)
      : type = j['type'],
        handle = j['handle'];

  String get label => switch (type) {
        'instagram' => 'Instagram',
        'x' => 'X',
        _ => type,
      };

  Uri get url => switch (type) {
        'instagram' => Uri.https('www.instagram.com', '/$handle/'),
        'x' => Uri.https('x.com', '/$handle'),
        _ => Uri.parse(handle),
      };
}

class Performer {
  final int? no;
  final String name;
  final String? comment;

  Performer.fromJson(Json j)
      : no = j['no'],
        name = j['name'],
        comment = j['comment'];
}

class FestivalEvent {
  final String id;
  final String category;
  final String? series;
  final String date;
  final String start;
  final String? end;
  final String? doorsOpen;
  final String venueId;
  final String title;
  final String? description;
  final List<Sns> sns;
  final List<Performer> performers;
  final String? status;
  final String? noticeId;
  final String? reservation;
  final TimeRange? merch;
  final String? ticketText;
  final String? image;
  final bool notify;

  FestivalEvent.fromJson(Json j)
      : id = j['id'],
        category = j['category'],
        series = j['series'],
        date = j['date'],
        start = j['start'],
        end = j['end'],
        doorsOpen = j['doorsOpen'],
        venueId = j['venueId'],
        title = j['title'],
        description = j['description'],
        sns = _list(j['sns'], Sns.fromJson),
        performers = _list(j['performers'], Performer.fromJson),
        status = j['status'],
        noticeId = j['noticeId'],
        reservation = j['reservation'],
        merch = j['merch'] == null
            ? null
            : TimeRange.fromJson({...j['merch'], 'date': j['date']}),
        ticketText = j['ticket'] == null
            ? null
            : '${j['ticket']['type']}：${j['ticket']['distributedAt']}〜 ${j['ticket']['place']}で配布',
        image = j['image'],
        notify = j['notify'] ?? false;

  bool get isCancelled => status == 'cancelled';

  String get timeLabel => end == null ? '$start〜' : '$start〜$end';
}

class ProjectSession {
  final String date;
  final String start;
  final String end;
  final String? lastEntry;
  final String? lastOrder;
  final String? note;

  ProjectSession.fromJson(Json j)
      : date = j['date'],
        start = j['start'],
        end = j['end'],
        lastEntry = j['lastEntry'],
        lastOrder = j['lastOrder'],
        note = j['note'];

  String get label {
    final extras = [
      if (lastEntry != null) '最終受付 $lastEntry',
      if (lastOrder != null) 'ラストオーダー $lastOrder',
      ?note,
    ];
    return extras.isEmpty
        ? '$start〜$end'
        : '$start〜$end（${extras.join('・')}）';
  }
}

class Project {
  final String id;
  final String category;
  final String title;
  final String building;
  final String? floor;
  final List<String> rooms;
  final String? locationExtra;

  /// 会場が venues にある場合（体育館など）の ID
  final String? venueId;
  final List<ProjectSession> schedule;
  final String? description;
  final List<String> highlights;
  final String? price;
  final String? reservation;
  final bool fukubiki;
  final List<String> targets;

  Project.fromJson(Json j)
      : id = j['id'],
        category = j['category'],
        title = j['title'],
        building = j['location']?['building'] ?? '',
        floor = j['location']?['floor'],
        rooms = _strings(j['location']?['rooms']),
        locationExtra = j['location']?['extra'],
        venueId = j['location']?['venueId'],
        schedule = _list(j['schedule'], ProjectSession.fromJson),
        description = j['description'],
        highlights = _strings(j['highlights']),
        price = j['price'],
        reservation = j['reservation'],
        fukubiki = j['fukubiki'] ?? false,
        targets = _strings(j['targets']);

  String get locationLabel {
    final base = [
      building,
      ?floor,
      if (rooms.isNotEmpty) rooms.join('・'),
    ].where((s) => s.isNotEmpty).join(' ');
    if (locationExtra == null) return base;
    return rooms.isEmpty ? locationExtra! : '$base／$locationExtra';
  }

  ProjectSession? sessionOn(String date) =>
      schedule.where((s) => s.date == date).firstOrNull;
}

class BoothArea {
  final String id;
  final String name;
  final String? map;
  final String? note;

  BoothArea.fromJson(Json j)
      : id = j['id'],
        name = j['name'],
        map = j['map'],
        note = j['note'];
}

class Booth {
  final String areaId;
  final String no;
  final String? floor;
  final String group;
  final String shop;
  final String items;
  final String type;
  final String? note;

  Booth.fromJson(Json j)
      : areaId = j['areaId'],
        no = j['no'],
        floor = j['floor'],
        group = j['group'],
        shop = j['shop'],
        items = j['items'],
        type = j['type'],
        note = j['note'];

  String get typeLabel => switch (type) {
        'food' => 'フード・ドリンク',
        'shop' => '販売',
        'experience' => '体験',
        'exhibit' => '展示',
        'performance' => '演奏・公演',
        _ => type,
      };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [no, group, shop, items].any((s) => s.toLowerCase().contains(q));
  }
}

class Facility {
  final String type;
  final String name;
  final List<String> places;

  Facility.fromJson(Json j)
      : type = j['type'],
        name = j['name'],
        places = _strings(j['places']);
}

class DiningSpace {
  final String name;
  final String place;
  final List<TimeRange> hours;
  final String? note;

  DiningSpace.fromJson(Json j)
      : name = j['name'],
        place = j['place'],
        hours = _list(j['hours'], TimeRange.fromJson),
        note = j['note'];
}

class CampusMap {
  final String? image;
  final String? access;
  final List<Facility> facilities;
  final List<DiningSpace> diningSpaces;
  final String? gymDirections;
  final String? gymDirectionsImage;

  CampusMap.fromJson(Json j)
      : image = j['image'],
        access = j['access'],
        facilities = _list(j['facilities'], Facility.fromJson),
        diningSpaces = _list(j['diningSpaces'], DiningSpace.fromJson),
        gymDirections = j['gymDirections'],
        gymDirectionsImage = j['gymDirectionsImage'];
}

class Ad {
  final String id;
  final String name;
  final String size;
  final String? image;
  final String? url;
  final String? coupon;

  Ad.fromJson(Json j)
      : id = j['id'],
        name = j['name'],
        size = j['size'] ?? 'small',
        image = j['image'],
        url = j['url'],
        coupon = j['coupon'];
}

class Sponsors {
  final List<String> donors;
  final List<Ad> ads;

  Sponsors.fromJson(Json j)
      : donors = _strings(j['donors']),
        ads = _list(j['ads'], Ad.fromJson);
}

class About {
  final String publisher;
  final String? afterword;
  final Map<String, String> contact;

  About.fromJson(Json j)
      : publisher = j['publisher'] ?? '',
        afterword = j['afterword'],
        contact = (j['contact'] as Map? ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString()));
}

class Festival {
  final String updatedAt;
  final Edition edition;
  final List<Notice> notices;
  final List<Greeting> greetings;
  final List<Rule> rules;
  final Goods? goods;
  final List<Venue> venues;
  final List<Category> eventCategories;
  final List<FestivalEvent> events;
  final String? merchPlace;
  final List<Category> projectCategories;
  final List<Project> projects;
  final List<BoothArea> boothAreas;
  final List<Booth> booths;
  final CampusMap? campusMap;
  final Sponsors? sponsors;
  final About? about;

  Festival.fromJson(Json j)
      : updatedAt = j['updatedAt'] ?? '',
        edition = Edition.fromJson(j['edition']),
        notices = _list(j['notices'], Notice.fromJson),
        greetings = _list(j['greetings'], Greeting.fromJson),
        rules = _list(j['rules'], Rule.fromJson),
        goods = j['goods'] == null ? null : Goods.fromJson(j['goods']),
        venues = _list(j['venues'], Venue.fromJson),
        eventCategories = _list(j['eventCategories'], Category.fromJson),
        events = _list(j['events'], FestivalEvent.fromJson),
        merchPlace = j['stageInfo']?['merchPlace'],
        projectCategories = _list(j['projectCategories'], Category.fromJson),
        projects = _list(j['projects'], Project.fromJson),
        boothAreas = _list(j['boothAreas'], BoothArea.fromJson),
        booths = _list(j['booths'], Booth.fromJson),
        campusMap =
            j['campusMap'] == null ? null : CampusMap.fromJson(j['campusMap']),
        sponsors =
            j['sponsors'] == null ? null : Sponsors.fromJson(j['sponsors']),
        about = j['about'] == null ? null : About.fromJson(j['about']);

  Venue? venue(String id) => venues.where((v) => v.id == id).firstOrNull;

  String categoryName(String id) =>
      eventCategories.where((c) => c.id == id).firstOrNull?.name ?? id;

  Notice? notice(String? id) => notices.where((n) => n.id == id).firstOrNull;

  List<FestivalEvent> eventsOn(String date) =>
      events.where((e) => e.date == date).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// events と projects の両方から ID で名前を引く（ふくびき対象の表示用）
  String? titleOf(String id) =>
      projects.where((p) => p.id == id).firstOrNull?.title ??
      events.where((e) => e.id == id).firstOrNull?.title;
}
