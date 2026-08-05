import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/secrets.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/leaves_device_mark.dart';
import '../../data/content/sos_techniques.dart';
import '../../data/content/specialists.dart';
import '../../data/content/vent_keywords.dart';
import '../../main.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/azure_chat_service.dart';
import '../../services/azure_transcribe_service.dart';
import '../../services/on_device_transcribe_service.dart';
import 'crisis_guard.dart';

/// Голосовой «Выговорись».
/// Принципы (из ресёрча):
/// — hold-to-talk (нажать-говорить-отпустить), не continuous,
/// — транскрипт показываем перед отправкой, даём отредактировать,
/// — двухслойная crisis-detection: regex → если совпало, escalate без LLM.
enum _Stage {
  /// Спрашиваем у платформы, умеет ли она распознавать речь без сети.
  /// Занимает миллисекунды, но от ответа зависит текст про приватность,
  /// поэтому показывать что-либо до него нельзя.
  probing,
  consent,
  intro,
  recording,
  reviewing,
  processing,
  done,
  error,
}

class VoiceVentScreen extends StatefulWidget {
  const VoiceVentScreen({super.key});

  @override
  State<VoiceVentScreen> createState() => _VoiceVentScreenState();
}

class _VoiceVentScreenState extends State<VoiceVentScreen> {
  final _recorder = AudioRecorderService();
  final _transcribe = AzureTranscribeService();
  final _onDevice = OnDeviceTranscribeService();
  final _chat = AzureChatService();
  final _transcriptCtl = TextEditingController();

  _Stage _stage = _Stage.probing;
  double _amplitudeDb = -60;
  StreamSubscription<double>? _ampSub;
  Timer? _maxDurationTimer;
  String? _errorMessage;
  VentResponse? _response;
  VentTopic _topic = VentTopic.general;
  static const _maxRecSeconds = 90;

  /// Умеет ли телефон распознавать речь без сети. От этого зависит и
  /// путь записи, и то, что написано на экране про приватность.
  bool _useOnDevice = false;

  /// Черновик распознавания: показываем слова по мере того, как они
  /// появляются. Человеку видно, что его слышат, и видно, что текст
  /// собирается прямо здесь, а не где-то на сервере.
  String _partial = '';

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final onDevice = await _onDevice.supportsOnDevice();
    if (!mounted) return;
    setState(() {
      _useOnDevice = onDevice;
      // Согласие нужно в обоих путях, но за разное. При локальном
      // распознавании — за то, что на сервер уйдёт текст (и человек
      // увидит его перед отправкой). При облачном — ещё и за аудио.
      _stage = settingsStorage.cloudVoiceConsent ? _Stage.intro : _Stage.consent;
    });
  }

  Future<void> _giveConsent() async {
    await settingsStorage.setCloudVoiceConsent(true);
    if (!mounted) return;
    setState(() => _stage = _Stage.intro);
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _maxDurationTimer?.cancel();
    _transcriptCtl.dispose();
    _recorder.dispose();
    _onDevice.cancel();
    super.dispose();
  }

  // ---------------------- Запись ----------------------

  Future<void> _startRecording() async {
    if (_useOnDevice) return _startOnDevice();
    return _startCloudRecording();
  }

  /// Локальный путь: файла записи не возникает вовсе, система отдаёт
  /// сразу текст. Отправлять на расшифровку нечего.
  Future<void> _startOnDevice() async {
    final ready = await _onDevice.prepare(
      onError: (msg) {
        if (!mounted) return;
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'Распознавание сорвалось: $msg. '
              'Можно попробовать ещё раз или написать текстом.';
        });
      },
    );
    if (!mounted) return;
    if (!ready) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Чтобы выслушать голосом, нужно разрешить микрофон '
            'и распознавание речи в настройках телефона.';
      });
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _stage = _Stage.recording;
      _partial = '';
      _errorMessage = null;
    });

    // Страховка: система обычно присылает финальный результат сама, но
    // если по таймауту она этого не сделает, экран останется в записи
    // навсегда. Забираем то, что успело распознаться.
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(
      OnDeviceTranscribeService.maxDuration + const Duration(seconds: 2),
      () {
        if (mounted && _stage == _Stage.recording) _stopOnDevice();
      },
    );

    await _onDevice.listen(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _partial = text);
        if (isFinal) _finishOnDevice(text);
      },
    );
  }

  void _finishOnDevice(String text) {
    if (_stage != _Stage.recording) return;
    _maxDurationTimer?.cancel();
    HapticFeedback.lightImpact();

    if (text.trim().isEmpty) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Не разобрала ни слова. Попробуй ещё раз — '
            'или напиши текстом.';
      });
      return;
    }

    _transcriptCtl.text = text;
    setState(() => _stage = _Stage.reviewing);
  }

  Future<void> _stopOnDevice() async {
    await _onDevice.stop();
    if (!mounted) return;
    // stop() не всегда приводит к финальному результату — добираем
    // тем, что успело распознаться.
    if (_stage == _Stage.recording) _finishOnDevice(_partial);
  }

  Future<void> _startCloudRecording() async {
    // Проверяем облако ДО записи. Раньше проверка стояла после stop(),
    // и человек сначала говорил 90 секунд, а потом узнавал, что зря.
    if (!cloudVoiceEnabled || azureOpenAiApiKey.isEmpty) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Разбор голоса сейчас недоступен. '
            'Можно написать текстом — это работает без облака.';
      });
      return;
    }

    final allowed = await _recorder.hasPermission();
    if (!mounted) return;
    if (!allowed) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Чтобы выслушать голосом, нужно разрешить микрофон '
            'в настройках телефона.';
      });
      return;
    }

    HapticFeedback.lightImpact();
    await _recorder.start();
    if (!mounted) {
      await _recorder.cancel();
      return;
    }

    _ampSub = _recorder.amplitudeStream().listen((db) {
      if (!mounted) return;
      setState(() => _amplitudeDb = db);
    });
    _maxDurationTimer = Timer(
      const Duration(seconds: _maxRecSeconds),
      _stopRecording,
    );
    setState(() {
      _stage = _Stage.recording;
      _amplitudeDb = -60;
      _errorMessage = null;
    });
  }

  Future<void> _stopRecording() async {
    if (_useOnDevice) return _stopOnDevice();

    _maxDurationTimer?.cancel();
    await _ampSub?.cancel();
    HapticFeedback.lightImpact();

    if (_stage != _Stage.recording) return;

    setState(() => _stage = _Stage.processing);

    final bytes = await _recorder.stop();
    final webUrl = _recorder.webBlobUrl;

    final text = await _transcribe.transcribe(
      bytes: bytes,
      webBlobUrl: webUrl,
    );

    if (!mounted) return;
    if (text == null || text.isEmpty) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Не получилось разобрать запись. Попробуй ещё раз — '
            'или напиши текстом.';
      });
      return;
    }

    _transcriptCtl.text = text;
    setState(() => _stage = _Stage.reviewing);
  }

  Future<void> _cancelRecording() async {
    _maxDurationTimer?.cancel();
    await _ampSub?.cancel();
    await _recorder.cancel();
    if (!mounted) return;
    setState(() => _stage = _Stage.intro);
  }

  // ---------------------- Отправка ----------------------

  Future<void> _sendToLlm() async {
    final text = _transcriptCtl.text.trim();
    if (text.isEmpty) return;

    // Слой 1: жёсткая crisis-detection — до любого обращения к LLM.
    if (guardCrisis(context, text)) return;

    final topic = detectTopic(text);
    setState(() {
      _stage = _Stage.processing;
      _topic = topic;
    });

    final options = allTechniques
        .map((t) => (id: t.id, title: t.title))
        .toList();

    final response = await _chat.respond(
      transcript: text,
      topicHint: topic.name,
      techniqueOptions: options,
    );

    if (!mounted) return;
    if (response == null) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Не получилось получить ответ. '
            'Проверь связь — или напиши текстом без облака.';
      });
      return;
    }

    setState(() {
      _response = response;
      _stage = _Stage.done;
    });
  }

  // ---------------------- Build ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Выговорись',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Написать текстом',
            icon: const Icon(Icons.keyboard_rounded),
            color: AppColors.accentPress,
            onPressed: () => context.pushReplacement('/vent/text'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: switch (_stage) {
            // Пустая бумага на те миллисекунды, пока платформа отвечает.
            // Спиннера нет намеренно: он читался бы как «что-то грузится
            // из сети», а мы как раз про обратное.
            _Stage.probing => const SizedBox.shrink(),
            _Stage.consent => _buildConsent(context),
            _Stage.intro => _buildIntro(context),
            _Stage.recording => _buildRecording(context),
            _Stage.reviewing => _buildReview(context),
            _Stage.processing => _buildProcessing(context),
            _Stage.done => _buildDone(context),
            _Stage.error => _buildError(context),
          },
        ),
      ),
    );
  }

  // ---------------------- Sub-views ----------------------

  /// Явное согласие перед первым использованием голоса.
  ///
  /// Текст зависит от того, что на самом деле уйдёт с телефона. Если
  /// система распознаёт речь сама — аудио не покидает устройство вовсе,
  /// и говорить про «отправим запись в облако» было бы враньём в свою
  /// невыгоду. Если не умеет — говорим ровно как есть.
  Widget _buildConsent(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: 8),
        Text('Прежде чем начать', style: theme.textTheme.displayLarge),
        const SizedBox(height: 12),
        if (_useOnDevice) ...[
          Text(
            'Твой голос превращается в текст прямо на телефоне. Запись '
            'никуда не отправляется и нигде не сохраняется.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Чтобы я могла ответить, на сервер уходит только получившийся '
            'текст — и ты увидишь его перед отправкой, сможешь поправить '
            'или стереть лишнее.',
            style: theme.textTheme.bodyMedium,
          ),
        ] else ...[
          Text(
            'Этот телефон не умеет распознавать речь без интернета, '
            'поэтому запись придётся отправить на расшифровку в облако — '
            'сервис Azure OpenAI от Microsoft.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Если включить русскую диктовку в настройках телефона, '
            '«Волна» станет распознавать речь на устройстве, и отправлять '
            'запись будет не нужно.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Ни имени, ни телефона, ни аккаунта приложение не собирает — '
          'связать сказанное с тобой нельзя. Microsoft может хранить '
          'запросы до 30 дней для защиты от злоупотреблений.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Дневник, чек-ины и опросники сюда не попадают никогда — '
          'они остаются на телефоне.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _giveConsent,
          child: Text(
            _useOnDevice ? 'Хорошо, слушай' : 'Согласна, разобрать голос',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.pushReplacement('/vent/text'),
          child: const Text('Лучше напишу текстом'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.push('/privacy'),
            child: const Text('Подробнее про данные'),
          ),
        ),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Я выслушаю', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          _useOnDevice
              ? 'Зажми кнопку и говори. До 90 секунд. Речь превращается '
                  'в текст прямо здесь, на телефоне.'
              : 'Зажми кнопку и говори. До 90 секунд. '
                  'Запись уходит на расшифровку в облако и с телефона '
                  'удаляется.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        // Знак стоит только там, где аудио действительно покидает
        // телефон. При локальном распознавании его нет — иначе он
        // перестанет что-либо значить.
        if (!_useOnDevice)
          const Align(
            alignment: Alignment.centerLeft,
            child: LeavesDeviceMark(),
          ),
        const Spacer(),
        Center(
          child: _MicButton(
            onStart: _startRecording,
            onStop: _stopRecording,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Нажми и держи — или просто нажми',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            'Это не терапия. Если тяжело по-настоящему — $crisisPhoneLabel',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildRecording(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        Text('Слышу тебя', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Говори своим темпом. Можно прерываться — я подожду.',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        // При локальном распознавании показываем сам текст по мере
        // появления: видно, что слова собираются здесь, а не улетают
        // куда-то. Полоски громкости для этого не нужны.
        if (_useOnDevice)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                _partial.isEmpty ? '…' : _partial,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
        else
          _AmplitudeBars(amplitudeDb: _amplitudeDb),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Я закончила'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancelRecording,
          child: const Text('Отменить'),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Так?', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Я расшифровала твою запись. Можешь поправить, если что-то не так.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paperLift,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: TextField(
              controller: _transcriptCtl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _sendToLlm,
          child: const Text('Отправить'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => setState(() => _stage = _Stage.intro),
          child: const Text('Перезаписать'),
        ),
      ],
    );
  }

  Widget _buildProcessing(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Думаю над ответом',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Это занимает несколько секунд',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    if (_response == null) {
      return _buildError(context);
    }
    return _ResponseView(response: _response!, topic: _topic);
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 48,
          color: AppColors.coral,
        ),
        const SizedBox(height: 16),
        Text(
          'Что-то не получилось',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Попробуй ещё раз или напиши текстом.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _stage = _Stage.intro),
          child: const Text('Попробовать ещё'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.pushReplacement('/vent/text'),
          child: const Text('Написать текстом'),
        ),
      ],
    );
  }
}

// ============================================================
//   Виджеты экрана
// ============================================================

/// Кнопка микрофона: нажать и держать.
///
/// Экран пишет «Зажми кнопку и говори», но кнопка реагировала на обычный тап —
/// человек отпускал палец и не понимал, почему запись идёт. Тап оставлен как
/// запасной вариант: с тремором или одной рукой удержание даётся тяжело.
class _MicButton extends StatelessWidget {
  const _MicButton({required this.onStart, required this.onStop});
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      onLongPressStart: (_) => onStart(),
      onLongPressEnd: (_) => onStop(),
      child: Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: AppColors.paperLift,
          size: 56,
        ),
      ),
    );
  }
}

class _AmplitudeBars extends StatelessWidget {
  const _AmplitudeBars({required this.amplitudeDb});
  /// Амплитуда в дБ (обычно -60…0).
  final double amplitudeDb;

  @override
  Widget build(BuildContext context) {
    // Нормализуем dB → 0..1.
    final norm = ((amplitudeDb + 50) / 50).clamp(0.0, 1.0);

    return SizedBox(
      width: 220,
      height: 140,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            // Центральный бар самый высокий, по бокам — меньше.
            final centerWeight = 1 - (i - 2).abs() * 0.2;
            final h = 24 + 80 * norm * centerWeight;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                width: 14,
                height: h.clamp(20, 110),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ResponseView extends StatelessWidget {
  const _ResponseView({required this.response, required this.topic});
  final VentResponse response;

  /// Тема по локальному анализу — страховка, если LLM назвала технику,
  /// которой нет в справочнике.
  final VentTopic topic;

  /// LLM возвращает id техники свободным текстом и иногда промахивается.
  /// Раньше в этом случае оставался заголовок «ОДНА ТЕХНИКА, КОТОРАЯ МОЖЕТ
  /// ПОМОЧЬ» и пустота под ним. Теперь падаем на локальный подбор по теме.
  SosTechnique? get _resolvedTechnique {
    final id = response.suggestionTechniqueId;
    final byLlm = id == null ? null : techniqueById(id);
    return byLlm ?? techniqueById(suggestionFor(topic).techniqueId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.peachSoft.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.terracotta.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                response.reflection,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                response.validation,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (response.suggestionType == 'technique') ...[
          _SuggestionTitle('ОДНА ТЕХНИКА, КОТОРАЯ МОЖЕТ ПОМОЧЬ'),
          const SizedBox(height: 10),
          _TechniqueLink(technique: _resolvedTechnique),
        ],
        if (response.suggestionType == 'phrase' &&
            response.suggestionPhrase != null) ...[
          _SuggestionTitle('НА ПАМЯТЬ'),
          const SizedBox(height: 10),
          _PhraseCard(text: response.suggestionPhrase!),
        ],
        if (response.suggestionType == 'question' &&
            response.suggestionQuestion != null) ...[
          _SuggestionTitle('Я ХОЧУ СПРОСИТЬ'),
          const SizedBox(height: 10),
          _QuestionCard(text: response.suggestionQuestion!),
        ],
        const SizedBox(height: 24),
        Material(
          color: AppColors.sage.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: () => context.push('/specialist'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.sageDeep,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Если этого мало — есть живая помощь',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Спасибо, на главную'),
          ),
        ),
      ],
    );
  }
}

class _SuggestionTitle extends StatelessWidget {
  const _SuggestionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.terracotta,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _TechniqueLink extends StatelessWidget {
  const _TechniqueLink({required this.technique});
  final SosTechnique? technique;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tech = technique;
    if (tech == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          context.push(
            tech.routeOverride ?? '/sos/technique/${tech.id}',
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tech.accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(tech.icon, color: tech.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tech.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(tech.duration, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.format_quote_rounded,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.peachSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.help_outline_rounded,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
