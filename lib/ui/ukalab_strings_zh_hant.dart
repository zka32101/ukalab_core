import 'ukalab_strings.dart';

// 繁体字中国語（台湾・香港向け）。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=本命 / 学習コイン=學習幣 / 合格=通過。

String _coinBalance(int b) => '學習幣 $b';
String _wardrobePurchased(String n) => '已購買$n';
String _wardrobePrice(int p) => '$p 學習幣';
String _lockedNotPurchased(int p) => '花 $p 學習幣即可購買';
String _passAskTitle(String c) => '請告訴我們$c的結果';
String _passCoin(int a) => '學習幣 +$a';
String _passOutfit(String n) => '現在可以穿上「$n」了';
String _mockRecordCert(String c) => '$c 模擬考試';
String _shareDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

/// 繁体字中国語（`zh-Hant`）。
const ukalabStringsZhHant = UkalabStrings(
  coinTotal: '合計',
  coinBreakdownTitle: '本次獲得的學習幣',
  coinEventLabels: {
    'newQuestion': '新題目',
    'coverageStep': '涵蓋率提升',
    'accuracyMilestone': '達成正確率',
    'accuracyBest': '刷新個人最佳',
    'reviewCorrected': '複習後攻克',
    'dailyConsult': '今日諮詢',
    'mockDone': '完成模擬考試',
    'mockPass': '模擬考試達到及格分',
    'mockBest': '模擬考試個人最佳',
    'streak': '連續學習',
    'passReport': '通過回報',
  },
  passAskBody: '您告知的內容僅會在這台裝置內使用。',
  passNotYet: '還沒有・等待結果',
  passNotPassed: '這次沒有通過',
  passPassed: '通過了',
  passEncourageTitle: '辛苦了',
  passEncourageBody: '複習弱點後再來挑戰吧。學習幣和服裝都會保留。',
  passCongrats: '恭喜通過',
  passPrivacy: '分享的卡片中不會包含姓名等個人資訊。',
  passShare: '分享',
  wardrobeTitle: '換裝・商店',
  wardrobeNote: '學習幣透過學習獲得。服裝只是外觀，不影響學習內容。',
  wardrobeInsufficient: '學習幣不足。學習即可獲得',
  wardrobeAlreadyOwned: '已擁有',
  wardrobeUnknown: '無法購買',
  wardrobeCannotWear: '目前無法穿上這件服裝',
  wardrobeWear: '穿上',
  wardrobeWearing: '穿著中',
  wardrobeCanWear: '可以穿上',
  lockedNotPassed: '通過考試後解鎖',
  lockedNoExamDate: '設定考試日期後即可穿上',
  lockedNotReady: '達成備考目標後解鎖',
  oshiMenuTooltip: '本命選單',
  oshiChoose: '選擇本命',
  oshiPassReport: '回報考試結果',
  oshiDisplayNormal: '正常',
  oshiDisplaySmall: '縮小顯示',
  oshiDisplayHidden: '不顯示',
  oshiName: '本命',
  oshiHiddenNote: '本命已隱藏',
  oshiYours: '你的本命',
  oshiTapHint: '點一下本命，牠會說句話',
  coinBalance: _coinBalance,
  wardrobePurchased: _wardrobePurchased,
  wardrobePrice: _wardrobePrice,
  lockedNotPurchased: _lockedNotPurchased,
  passAskTitle: _passAskTitle,
  passCoin: _passCoin,
  passOutfit: _passOutfit,
  characterNames: {},
  characterRoles: {
    'standard': '燒瓶助手',
    'kai': '可靠的前輩',
    'mio': '開朗的後輩',
    'moka': '悠閒的夥伴（狗）',
    'mike': '細心的講解員（貓）',
    'circa': '愛研究原理的電路貓',
    'noda': '擅長串連知識的章魚',
    'sheru': '認真守護的烏龜',
    'hirari': '憑靈感飛翔的蝴蝶',
    'soro': '一步步數清的刺蝟',
    'sala': '謹慎可靠的火蜥蜴',
    'tatsu': '愛墨與毛筆的小龍',
  },
  characterQualificationHeading: '考試專屬角色',
  characterPremiumNote: '進階版可用',
  characterPreviewNote: '預覽中。選擇此角色需要進階版',
  characterPurchaseAction: '查看進階版',
  tabLabels: ['首頁', '學習', '模擬', '紀錄', '設定'],
  mockRecordTitle: '學習紀錄卡',
  mockRecordNote: '這是模擬考試的紀錄，並非正式考試通過。不包含姓名等個人資訊。',
  mockRecordMessage: '超過及格分了！',
  mockRecordCert: _mockRecordCert,
  shareCardBrand: 'Qualab',
  shareCardPassed: '通過了！',
  shareDate: _shareDate,
  medalTitle: '推的獎牌卡片',
  medalNote: '可以儲存或分享為圖片。不包含姓名等個人資訊。',
  medalDisclaimer: '個人記錄・非官方',
  medalSave: '儲存圖片',
  close: '關閉',
);
