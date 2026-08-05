# CLAUDE.md

Рабочие заметки для ИИ-ассистента по проекту «Волна».
Продуктовый контекст и задачи — в `HANDOFF.md`.

## Design System

Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

Практически это значит:

- Цвета — только из `AppColors` (`lib/core/theme/colors.dart`).
  `Color(0x...)` в `lib/features/` быть не должно.
- Радиусы — только `AppRadius.none/sm/md` (0 / 4 / 12).
  Числовой литерал в `BorderRadius.circular()` — ошибка.
- Отступы — `AppSpacing`. Левая ось экрана `AppSpacing.axis`.
- Градиентов и теней в приложении нет. Совсем.
- `Colors.white` не используется: есть `AppColors.paperLift`.
- `AppColors.accent` — заливки и линии. Для **текста** только
  `AppColors.accentPress`: терракота на бумаге даёт 3.0:1 и не проходит AA.
- Ничего, что может уменьшиться: ни стриков, ни «N из M», ни счётчиков на
  иконках, ни увядающих состояний. См. раздел «Правила» в DESIGN.md — это
  ограничения продукта, а не вкусовщина.

## Навигация

Четыре вкладки (`Главная · Выговориться · Дневник · Ещё`) плюс отдельная
коралловая кнопка «Плохо» — `lib/core/widgets/app_bottom_bar.dart`.

- Оболочка — `StatefulShellRoute.indexedStack` в `lib/app/router.dart`.
  **В ветках лежат только корни вкладок.** Всё остальное пушится поверх
  оболочки и бар прячет — это намеренно, а не недоделка.
- Новый раздел добавляется в `MoreScreen.groups`, а не иконкой в шапку
  главной. Пятая вкладка не добавляется без пересмотра всей навигации.
- Счётчиков и точек на вкладках быть не может, см. DESIGN.md.
- Бар и кнопка «Плохо» берут безопасную зону через
  `MediaQuery.paddingOf(context).bottom`, а не `SafeArea`.

## Приватность

Дневник, чек-ины и записи «выговориться» хранятся только на устройстве.
Единственный внешний вызов — Azure OpenAI в «выговориться»; в интерфейсе он
помечен `LeavesDeviceMark`. Не добавляй сетевых вызовов в другие разделы без
явного согласования.

## Тексты

На русском, в мягком тоне, на «ты», без канцелярита. Контент утверждён
психологом — правки формулировок согласовываются, а не вносятся по ходу.

## Проверка перед сдачей

```bash
flutter analyze                                    # без замечаний
flutter test                                       # все зелёные
grep -rn "Color(0x" lib/features/ | wc -l          # 0
grep -rn "Colors.white" lib/features/ | wc -l      # 0
grep -rn "Gradient\|BoxShadow" lib/ | grep -v core/theme | wc -l   # 0
grep -rho "circular([0-9]" lib/features/ | wc -l   # 0
```
