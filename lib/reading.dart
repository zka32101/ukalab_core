/// 読み物・説明ページ関連の公開 API を1か所にまとめた入口。Flutter が要る。
///
/// `ukalab_core.dart`・`ui.dart`・`answer_feedback.dart` に分かれていた名前を再エクスポートする
/// （既存の入口の公開名は変更しない）。ほかの名前は含めないので、独自の同名型を持つアプリとも
/// 衝突しにくい。
library;

export 'content/chapter_reading_validator.dart' show validateChapterReadings;
export 'experience/chapter_reading.dart'
    show
        ChapterReading,
        ContentLink,
        ReadingFigure,
        ReadingSection,
        ReadingTable,
        kReadingSectionFigure,
        kReadingSectionKinds,
        kReadingSectionSteps,
        kReadingSectionTable,
        kReadingSectionText,
        linksOfKind,
        readingsForLevel;
export 'experience/explanation_parts.dart'
    show ExplanationParts, kExplanationOtherSceneMarker, readingsForQuestion;
export 'ui/answer_feedback/explanation_card.dart';
export 'ui/answer_feedback/related_readings_card.dart';
export 'ui/reading/reading_question_links.dart';
export 'ui/reading/reading_section_content.dart';
