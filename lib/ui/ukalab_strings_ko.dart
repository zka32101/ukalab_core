import 'ukalab_strings.dart';

// 韓国語。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=최애 / 学習コイン=학습 코인 / 合格=합격。

String _coinBalance(int b) => '학습 코인 $b';
String _wardrobePurchased(String n) => '$n을(를) 구매했습니다';
String _wardrobePrice(int p) => '$p코인';
String _lockedNotPurchased(int p) => '$p코인으로 구매할 수 있어요';
String _passAskTitle(String c) => '$c 결과를 알려 주세요';
String _passCoin(int a) => '학습 코인 +$a';
String _passOutfit(String n) => '이제 「$n」을(를) 입을 수 있어요';
String _mockRecordCert(String c) => '$c 모의고사';
String _shareDate(DateTime d) => '${d.year}년 ${d.month}월 ${d.day}일';

/// 韓国語（`ko`）。
const ukalabStringsKo = UkalabStrings(
  coinTotal: '합계',
  coinBreakdownTitle: '이번에 모은 학습 코인',
  coinEventLabels: {
    'newQuestion': '새 문제',
    'coverageStep': '커버율 상승',
    'accuracyMilestone': '정답률 달성',
    'accuracyBest': '개인 최고 기록 경신',
    'reviewCorrected': '복습으로 극복',
    'dailyConsult': '오늘의 상담',
    'mockDone': '모의고사 응시',
    'mockPass': '모의고사 합격점',
    'mockBest': '모의고사 개인 최고 기록',
    'streak': '연속 학습',
    'passReport': '합격 보고',
  },
  passAskBody: '알려 주신 내용은 이 기기 안에서만 사용됩니다.',
  passNotYet: '아직・결과 대기 중',
  passNotPassed: '이번에는 합격하지 못했어요',
  passPassed: '합격했어요',
  passEncourageTitle: '수고하셨어요',
  passEncourageBody: '약점을 복습하고 다시 도전해 봐요. 코인과 의상은 그대로예요.',
  passCongrats: '합격을 축하드려요',
  passPrivacy: '공유하는 카드에는 이름 등 개인 정보가 들어가지 않아요.',
  passShare: '공유하기',
  wardrobeTitle: '의상・상점',
  wardrobeNote: '코인은 학습하면 모여요. 의상은 외형만 바뀌며 학습 내용에는 영향이 없어요.',
  wardrobeInsufficient: '코인이 부족해요. 학습하면 모여요',
  wardrobeAlreadyOwned: '이미 가지고 있어요',
  wardrobeUnknown: '구매할 수 없어요',
  wardrobeCannotWear: '지금은 이 의상을 입을 수 없어요',
  wardrobeWear: '입기',
  wardrobeWearing: '입고 있어요',
  wardrobeCanWear: '입을 수 있어요',
  lockedNotPassed: '합격하면 열려요',
  lockedNoExamDate: '시험일을 설정하면 입을 수 있어요',
  lockedNotReady: '준비 완료 목표를 달성하면 열려요',
  oshiMenuTooltip: '최애 메뉴',
  oshiChoose: '최애 고르기',
  oshiPassReport: '시험 결과 보고',
  oshiDisplayNormal: '보통',
  oshiDisplaySmall: '작게 표시',
  oshiDisplayHidden: '표시 안 함',
  oshiName: '최애',
  oshiHiddenNote: '최애가 숨겨져 있어요',
  oshiYours: '나의 최애',
  oshiTapHint: '최애를 누르면 한마디 해요',
  coinBalance: _coinBalance,
  wardrobePurchased: _wardrobePurchased,
  wardrobePrice: _wardrobePrice,
  lockedNotPurchased: _lockedNotPurchased,
  passAskTitle: _passAskTitle,
  passCoin: _passCoin,
  passOutfit: _passOutfit,
  characterNames: {},
  characterRoles: {
    'standard': '플라스크 조수',
    'kai': '믿음직한 선배',
    'mio': '밝은 후배',
    'moka': '느긋한 짝꿍 (강아지)',
    'mike': '친절한 해설 담당 (고양이)',
  },
  tabLabels: ['홈', '풀기', '모의', '기록', '설정'],
  mockRecordTitle: '학습 기록 카드',
  mockRecordNote: '모의고사 기록입니다. 실제 시험 합격이 아닙니다. 이름 등 개인 정보는 들어가지 않아요.',
  mockRecordMessage: '합격점을 넘었어요!',
  mockRecordCert: _mockRecordCert,
  shareCardBrand: 'Qualab',
  shareCardPassed: '합격했어요!',
  shareDate: _shareDate,
  medalTitle: '최애 메달 카드',
  medalNote: '이미지로 저장하거나 공유할 수 있어요. 이름 등 개인 정보는 들어가지 않아요.',
  medalDisclaimer: '자기 기록・비공식',
  medalSave: '이미지 저장',
  close: '닫기',
);
