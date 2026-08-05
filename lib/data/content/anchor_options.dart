/// Якоря рутин — привязки уведомлений к моментам дня вместо часов.
/// На основе исследования: фиксированные часы вызывают усталость от пушей,
/// привязка к рутине («пока закипает чайник») воспринимается как «своё».
library;

class AnchorOption {
  const AnchorOption({
    required this.id,
    required this.text,
    required this.notificationCopy,
    required this.suggestedHour,
  });

  final String id;
  final String text;
  /// Часть фразы, которая войдёт в текст пуша.
  /// Пример: «Пока закипает чайник» → пуш: «Пока закипает чайник — один маленький шаг».
  final String notificationCopy;
  /// Час, когда пуш сработает по умолчанию (можно переопределить вручную).
  final int suggestedHour;
}

const morningAnchors = <AnchorOption>[
  AnchorOption(
    id: 'kettle',
    text: 'Пока закипает чайник',
    notificationCopy: 'Пока закипает чайник',
    suggestedHour: 7,
  ),
  AnchorOption(
    id: 'after_wake',
    text: 'Сразу после пробуждения',
    notificationCopy: 'Пока ещё тихо',
    suggestedHour: 7,
  ),
  AnchorOption(
    id: 'breakfast',
    text: 'Пока готовлю завтрак',
    notificationCopy: 'Пока готовится завтрак',
    suggestedHour: 8,
  ),
  AnchorOption(
    id: 'after_drop',
    text: 'После того как отвёл/отвезла ребёнка',
    notificationCopy: 'После того как отвезла ребёнка',
    suggestedHour: 9,
  ),
];

const eveningAnchors = <AnchorOption>[
  AnchorOption(
    id: 'after_bath',
    text: 'После купания ребёнка',
    notificationCopy: 'После купания',
    suggestedHour: 20,
  ),
  AnchorOption(
    id: 'after_bedtime',
    text: 'После того как уложила',
    notificationCopy: 'Когда дом затих',
    suggestedHour: 21,
  ),
  AnchorOption(
    id: 'kitchen_quiet',
    text: 'Когда осталась одна на кухне',
    notificationCopy: 'Когда осталась одна на кухне',
    suggestedHour: 21,
  ),
  AnchorOption(
    id: 'before_sleep',
    text: 'Перед сном',
    notificationCopy: 'Перед сном',
    suggestedHour: 22,
  ),
];
