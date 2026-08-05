/// Внешние ресурсы для родителей детей с ОВЗ.
/// Источник: документ ПРИЛОЖЕНИЕ.docx, раздел «БИБЛИО ресурс».
library;

class ResourceCategory {
  const ResourceCategory({
    required this.title,
    required this.resources,
  });

  final String title;
  final List<Resource> resources;
}

class Resource {
  const Resource({
    required this.title,
    required this.url,
    required this.description,
  });

  final String title;
  final String url;
  final String description;
}

const resourceCategories = <ResourceCategory>[
  ResourceCategory(
    title: 'Федеральный уровень',
    resources: [
      Resource(
        title: 'Федеральный реестр примерных программ',
        url: 'https://fgosreestr.ru',
        description: 'Все утверждённые примерные программы, в том числе '
            'адаптированные (АООП) для детей с ОВЗ.',
      ),
      Resource(
        title: 'Госуслуги · Раздел для инвалидов',
        url: 'https://www.gosuslugi.ru/invalidam',
        description: 'Государственные услуги, нормативные документы, '
            'информация о правах на обучение по АООП.',
      ),
    ],
  ),
  ResourceCategory(
    title: 'Дошкольное образование',
    resources: [
      Resource(
        title: 'Реестр АООП дошкольного образования',
        url: 'https://fgosreestr.ru',
        description: 'Программы для детей с ТНР, ЗПР, РАС и другими '
            'особенностями развития.',
      ),
    ],
  ),
  ResourceCategory(
    title: 'Школьное образование',
    resources: [
      Resource(
        title: 'Российское образование',
        url: 'https://edu.ru',
        description: 'Федеральный портал. Нормативные документы, стандарты, '
            'разъяснения по АООП.',
      ),
      Resource(
        title: 'Особое право',
        url: 'https://osoboepravo.ru',
        description: 'Юридические аспекты реализации АООП, разъяснения, '
            'судебная практика.',
      ),
      Resource(
        title: 'Ресурсное образование',
        url: 'https://resobr.ru',
        description: 'Актуальные новости и разъяснения Минпросвещения.',
      ),
    ],
  ),
  ResourceCategory(
    title: 'Психологическая помощь',
    resources: [
      Resource(
        title: 'Телефон доверия для детей и родителей',
        url: 'tel:88002000122',
        description: '8-800-2000-122. Бесплатно, анонимно, круглосуточно. '
            'Можно позвонить, если очень тяжело.',
      ),
    ],
  ),
];
