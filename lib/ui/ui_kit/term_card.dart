import 'package:flutter/material.dart';

import 'lab_strings.dart';

/// 用語カードの「関連用語」1件。タップで該当の用語カードへ移動する。
class RelatedTermRef {
  const RelatedTermRef({required this.termId, required this.label});

  final String termId;
  final String label;
}

/// 用語カードの「関連問題」1件。タップで該当の問題を出題する。
class RelatedQuestionRef {
  const RelatedQuestionRef({required this.questionId, required this.label});

  final String questionId;
  final String label;
}

/// 専門用語の解説カード（決定50「専門用語の解説（全アプリ共通）」）。
///
/// ①ひとことで言うと([headline])→②正確な意味([definition])→③たとえ話
/// ([analogy])→④よくある間違い([commonMistake])→⑤関連用語→⑥関連問題の
/// 順に表示する。[onRelatedTermTap] が渡されなければ関連用語は非活性。
class TermCard extends StatelessWidget {
  const TermCard({
    super.key,
    required this.term,
    required this.headline,
    required this.definition,
    this.analogy,
    this.commonMistake,
    this.relatedTerms = const [],
    this.relatedQuestions = const [],
    this.diagram,
    this.onRelatedTermTap,
    this.onRelatedQuestionTap,
  });

  final String term;
  final String headline;
  final String definition;
  final String? analogy;
  final String? commonMistake;
  final List<RelatedTermRef> relatedTerms;
  final List<RelatedQuestionRef> relatedQuestions;

  /// 図が役立つ用語に添える、コード描画（SVGなど）の図。
  final Widget? diagram;
  final ValueChanged<String>? onRelatedTermTap;
  final ValueChanged<String>? onRelatedQuestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(term, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            headline,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(definition, style: theme.textTheme.bodyLarge),
          if (diagram != null) ...[const SizedBox(height: 16), diagram!],
          if (analogy != null && analogy!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _TermSection(label: LabStrings.of(context).termAnalogy, body: analogy!),
          ],
          if (commonMistake != null && commonMistake!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _TermSection(label: LabStrings.of(context).termCommonMistake, body: commonMistake!),
          ],
          if (relatedTerms.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(LabStrings.of(context).termRelatedTerms, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in relatedTerms)
                  ActionChip(
                    label: Text(r.label),
                    onPressed: onRelatedTermTap == null
                        ? null
                        : () => onRelatedTermTap!(r.termId),
                  ),
              ],
            ),
          ],
          if (relatedQuestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(LabStrings.of(context).termRelatedQuestions, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final r in relatedQuestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRelatedQuestionTap == null
                        ? null
                        : () => onRelatedQuestionTap!(r.questionId),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(r.label),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// [TermCard] をボトムシートで開く（決定50「タップでボトムシートに用語カードを
/// 開く。問題の途中でも開け、閉じれば元の画面に戻る」）。
Future<void> showTermCard(
  BuildContext context, {
  required String term,
  required String headline,
  required String definition,
  String? analogy,
  String? commonMistake,
  List<RelatedTermRef> relatedTerms = const [],
  List<RelatedQuestionRef> relatedQuestions = const [],
  Widget? diagram,
  ValueChanged<String>? onRelatedTermTap,
  ValueChanged<String>? onRelatedQuestionTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // 下部のナビゲーションバーに隠れないようにする
    showDragHandle: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: TermCard(
        term: term,
        headline: headline,
        definition: definition,
        analogy: analogy,
        commonMistake: commonMistake,
        relatedTerms: relatedTerms,
        relatedQuestions: relatedQuestions,
        diagram: diagram,
        onRelatedTermTap: onRelatedTermTap,
        onRelatedQuestionTap: onRelatedQuestionTap,
      ),
    ),
  );
}
