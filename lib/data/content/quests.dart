/// Квесты «Волны» из ТЗ — утренние и вечерние.
/// Источник: документ ПРИЛОЖЕНИЕ.docx, разделы «УТРЕННИЕ КВЕСТЫ» и «ВЕЧЕРНИЕ КВЕСТЫ».
library;

enum QuestSlot { morning, evening }

enum QuestDifficulty { easy, medium, hard }

class Quest {
  const Quest({
    required this.id,
    required this.slot,
    required this.title,
    required this.description,
    required this.duration,
    required this.afterPhrase,
    this.difficulty = QuestDifficulty.easy,
  });

  final String id;
  final QuestSlot slot;
  final String title;
  final String description;
  final String duration;
  final String afterPhrase;
  final QuestDifficulty difficulty;
}

const morningQuests = <Quest>[
  Quest(
    id: 'm_strokes',
    slot: QuestSlot.morning,
    title: 'Три поглаживания',
    description: 'Найди три предмета в комнате, до которых можно дотянуться рукой. '
        'Погладь их медленно — кота, плед, стену, книгу. '
        'Затем погладь себя по голове и скажи: «Я здесь. Я начинаю день».',
    duration: '2 минуты',
    afterPhrase: 'Ты сделал первый шаг. Этого достаточно.',
  ),
  Quest(
    id: 'm_window',
    slot: QuestSlot.morning,
    title: 'Стоп-кадр у окна',
    description: 'Подойди к окну. Замри на 5 секунд. '
        'Найди один движущийся объект — птицу, ветку, машину, облако. '
        'Смотри на него, пока он не исчезнет.',
    duration: '1 минута',
    afterPhrase: 'Ты синхронизировал зрение и дыхание. Это уже практика.',
  ),
  Quest(
    id: 'm_password',
    slot: QuestSlot.morning,
    title: 'Зарядка-пароль',
    description: 'Сегодняшний пароль — три хлопка над головой. Сделай их. '
        'Затем топни левой ногой. Поморгай как бабочка. Обними себя.',
    duration: '3 минуты',
    afterPhrase: 'Одно маленькое действие лучше, чем сто мыслей о большом.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'm_taste',
    slot: QuestSlot.morning,
    title: 'Вкус утра',
    description: 'Выбери один микро-вкус: кусочек яблока, ложку йогурта, '
        'глоток тёплой воды. Назови вкус одним словом — кислый, сладкий, никакой. '
        'Не оценивай — просто заметь.',
    duration: '1 минута',
    afterPhrase: 'Я не обязана быть идеальной. Моя любовь уже достаточна.',
  ),
  Quest(
    id: 'm_mood',
    slot: QuestSlot.morning,
    title: 'Фоторобот настроения',
    description: 'Выбери цвет, как ты сейчас:\n\n'
        '🟢 Спокоен  🟡 Вялый\n🔴 Раздражён  🔵 Грусть\n\n'
        'Не исправляй, не оценивай. Просто отметь. Вечером сравним с утренним.',
    duration: '1 минута',
    afterPhrase: 'Ты заметил себя. Это уже забота.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'm_warm',
    slot: QuestSlot.morning,
    title: 'Тепло в ладонях',
    description: 'Подыши на ладони 3 раза, как будто согреваешь их. '
        'Затем приложи их к своим щекам. Закрой глаза. '
        'Почувствуй тепло своих рук. Ты можешь согреть себя сам.',
    duration: '2 минуты',
    afterPhrase: 'Моя усталость — не провал, а сигнал, что пора восстановиться.',
  ),
  Quest(
    id: 'm_anchor',
    slot: QuestSlot.morning,
    title: 'Первая фраза',
    description: 'Сегодняшняя фраза-якорь:\n\n'
        '«Я делаю только одно дело за раз».\n\n'
        'Повтори её трижды шёпотом, пока чистишь зубы или варишь кофе. '
        'Пусть она будет с тобой до вечера.',
    duration: '2 минуты',
    afterPhrase: 'Я уже прошёл через многое. Это доказывает мою силу, а не слабость.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'm_alarm',
    slot: QuestSlot.morning,
    title: 'Сонный будильник',
    description: 'Включи одну короткую мелодию (30 секунд) — '
        'звон ложек, шум дождя, мяуканье. '
        'Задача — встать до того, как мелодия закончится.',
    duration: '1 минута',
    afterPhrase: 'Ты сделал маленький вызов и победил. Это хорошее начало дня.',
  ),
  Quest(
    id: 'm_silly',
    slot: QuestSlot.morning,
    title: 'Квест-путаница',
    description: 'Надень носок на руку (или тапок на голову). '
        'Пройди три шага и скажи: «Это я так утром одеваюсь. А как правильно?»\n\n'
        'Смех снижает утренний кортизол.',
    duration: '2 минуты',
    afterPhrase: 'Ты позволил себе лёгкость. Даже если день будет тяжёлым.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'm_unimportant',
    slot: QuestSlot.morning,
    title: 'Пять неважных дел',
    description: 'Запиши или проговори 5 дел, которые НЕ надо делать сегодня:\n\n'
        '— не вытирать пыль\n— не отвечать на грубые сообщения\n'
        '— не сравнивать с другими детьми\n\n'
        'Парадоксальное разрешение снимает давление.',
    duration: '3 минуты',
    afterPhrase: 'Я выбираю сделать сегодня ровно столько, сколько могу. И это уже прогресс.',
    difficulty: QuestDifficulty.hard,
  ),
];

const eveningQuests = <Quest>[
  Quest(
    id: 'e_shake',
    slot: QuestSlot.evening,
    title: 'Сбросить шум',
    description: 'Встань. Потряси кистями рук 10 секунд, как будто стряхиваешь воду. '
        'Затем пятками об пол — 5 раз. Скажи: «Дневной шум ушёл в пол».',
    duration: '2 минуты',
    afterPhrase: 'Ты справился с этим днём. Отдыхай без вины.',
  ),
  Quest(
    id: 'e_second',
    slot: QuestSlot.evening,
    title: 'Одна хорошая секунда',
    description: 'Вспомни один миг за день, который был не ужасным. '
        'Может, 3 секунды тишины. Может, ребёнок улыбнулся. '
        'Может, ты успел выпить чай горячим.\n\n'
        'Назови эту секунду: «Сегодня хорошая секунда была в …».',
    duration: '2 минуты',
    afterPhrase: 'Маленькие победы накапливаются. Завтра будет легче, чем вчера.',
  ),
  Quest(
    id: 'e_silent',
    slot: QuestSlot.evening,
    title: 'Спальня без слов',
    description: 'За 10 минут до сна — никаких инструкций и вопросов к ребёнку. '
        'Только: погладить, поправить одеяло, помолчать. Ты тоже молчишь. '
        'Это квест на выдержку.',
    duration: '10 минут',
    afterPhrase: 'Тишина — это тоже забота. И о нём, и о себе.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'e_backpack',
    slot: QuestSlot.evening,
    title: 'Рюкзак усталости',
    description: 'Представь, что за плечами тяжёлый рюкзак. '
        'В нём — все тревоги, чувство вины, усталость, диагнозы, очереди. '
        'Сделай движение — сними рюкзак. Положи его на стул. '
        'Скажи: «Я оставляю это здесь до завтра».',
    duration: '3 минуты',
    afterPhrase: 'Перерыв — это не побег. Это подготовка к новому шагу.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'e_sounds',
    slot: QuestSlot.evening,
    title: 'Ревизия звуков',
    description: 'Сядь, закрой глаза, назови 3 звука, которые слышны прямо сейчас:\n\n'
        '— гул батареи\n— дыхание ребёнка\n— своё сердцебиение\n\n'
        'Если ни одного — создай: пошурши простынёй.',
    duration: '2 минуты',
    afterPhrase: 'Сейчас я в безопасности. Моё тело и мой дом — здесь.',
  ),
  Quest(
    id: 'e_envelope',
    slot: QuestSlot.evening,
    title: 'Конверт для тревоги',
    description: 'Напиши на бумаге одну самую липкую мысль: '
        '«Завтра не справлюсь на занятии». '
        'Закрой её в конверт, папку или коробку.\n\n'
        'Скажи: «Эта мысль подождёт до завтра в 10 утра».',
    duration: '4 минуты',
    afterPhrase: 'Я отпускаю потребность в определённости. Неопределённость — часть жизни.',
    difficulty: QuestDifficulty.hard,
  ),
  Quest(
    id: 'e_stretch',
    slot: QuestSlot.evening,
    title: 'Растяжка-идиот',
    description: 'Ляг на спину. '
        'Подними правую ногу и помаши ей «пока-пока». '
        'Левой рукой почеши левую пятку. '
        'Покрути головой, как будто говоришь «нет». '
        'Глубоко выдохни.',
    duration: '3 минуты',
    afterPhrase: 'Ты имеешь право на лёгкость. Даже если день был тяжёлым.',
  ),
  Quest(
    id: 'e_thanks',
    slot: QuestSlot.evening,
    title: 'Три спасибо телу',
    description: 'Скажи вслух или про себя:\n\n'
        '«Спасибо, сердце, что бьёшься».\n'
        '«Спасибо, спина, что держала ребёнка».\n'
        '«Спасибо, глаза, что видели его улыбку».\n\n'
        'Если не чувствуешь благодарности — скажи иронично. Это тоже работает.',
    duration: '3 минуты',
    afterPhrase: 'Твоё тело — твой дом. Оно заслуживает уважения.',
    difficulty: QuestDifficulty.medium,
  ),
  Quest(
    id: 'e_water',
    slot: QuestSlot.evening,
    title: 'Правило одного стакана',
    description: 'Выпей один стакан воды медленно — 30 секунд. '
        'Не чай, не сок — именно воду.\n\n'
        'Это физиологический триггер для снижения ночного кортизола.',
    duration: '1 минута',
    afterPhrase: 'Мой сон, еда, вода и тишина — это базовая гигиена психики.',
  ),
  Quest(
    id: 'e_chaos',
    slot: QuestSlot.evening,
    title: 'Сонный хаос',
    description: 'Выбери одно из трёх:\n\n'
        '— прочитать 2 абзаца любой ерунды (инструкция к стиральной машине)\n'
        '— погладить кота или плед ровно 20 раз\n'
        '— посмотреть в потолок 1 минуту и назвать 3 пятна\n\n'
        'Цель — не уснуть быстрее, а остановить внутренний монолог.',
    duration: '3 минуты',
    afterPhrase: 'Я разрешаю себе ничего не делать столько, сколько нужно. Тишина лечит.',
    difficulty: QuestDifficulty.medium,
  ),
];
