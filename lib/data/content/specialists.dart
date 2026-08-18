/// Контакты профессиональной помощи.
/// Принципы:
/// — экстренная линия первой,
/// — указываем только проверенные общероссийские сервисы,
/// — региональные/именные специалисты — отдельный блок, заполняется заказчицей-психологом.
///
/// ВАЖНО: При обновлении проверять актуальность номеров и адресов.
library;

class SpecialistContact {
  const SpecialistContact({
    required this.title,
    required this.description,
    required this.url,
    required this.kind,
    this.note,
  });

  final String title;
  final String description;
  final String url;
  final ContactKind kind;
  final String? note;
}

enum ContactKind {
  /// Звонок (tel:).
  phone,
  /// Внешняя ссылка.
  link,
  /// Telegram-бот / чат.
  telegram,
}

/// Экстренная линия. Одна константа на всё приложение — номер показывается
/// на кризисном экране, в опроснике, в настройках и в «Выговорись»,
/// и расходиться эти места не должны.
const crisisPhoneLabel = '8-800-2000-122';
const crisisPhoneUrl = 'tel:88002000122';

const emergencyContacts = <SpecialistContact>[
  SpecialistContact(
    title: 'Телефон доверия',
    description: '8-800-2000-122. Бесплатно, анонимно, круглосуточно. '
        'Для детей и родителей в трудной ситуации.',
    url: 'tel:88002000122',
    kind: ContactKind.phone,
    note: 'Если нет сил говорить — можно молчать в трубку. Психолог дождётся.',
  ),
  SpecialistContact(
    title: 'Экстренная психологическая помощь МЧС',
    description: '+7 (495) 989-50-50. Круглосуточно, для всех.',
    url: 'tel:+74959895050',
    kind: ContactKind.phone,
  ),
];

const onlineTherapy = <SpecialistContact>[
  SpecialistContact(
    title: 'Ясно',
    description: 'Подбор психолога онлайн, видеосессии. Есть фильтр '
        '«семейный психолог», «работа с травмой».',
    url: 'https://yasno.live',
    kind: ContactKind.link,
  ),
  SpecialistContact(
    title: 'Alter',
    description: 'Каталог психологов с подбором под запрос. Можно отметить '
        '«опыт работы с особенными детьми».',
    url: 'https://alter.ru',
    kind: ContactKind.link,
  ),
  SpecialistContact(
    title: 'B17',
    description: 'Большой каталог психологов России с возможностью '
        'фильтрации по специализации и городу.',
    url: 'https://www.b17.ru',
    kind: ContactKind.link,
  ),
];

/// Пока пусто: единственная запись, «Я Могу» (imozhem.ru), убрана
/// 18.08.2026 — у домена нет A-записи, он не существует вовсе.
/// Экран помощи раздел с пустым списком не рисует.
const supportCommunities = <SpecialistContact>[];
