import 'ukalab_strings.dart';

// 簡体字中国語。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=本命 / 学習コイン=学习币 / 合格=通过。

String _coinBalance(int b) => '学习币 $b';
String _wardrobePurchased(String n) => '已购买$n';
String _wardrobePrice(int p) => '$p 学习币';
String _lockedNotPurchased(int p) => '花 $p 学习币即可购买';
String _passAskTitle(String c) => '请告诉我们$c的结果';
String _passCoin(int a) => '学习币 +$a';
String _passOutfit(String n) => '现在可以穿上「$n」了';
String _mockRecordCert(String c) => '$c 模拟考试';
String _shareDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

/// 簡体字中国語（`zh`）。
const ukalabStringsZhHans = UkalabStrings(
  coinTotal: '合计',
  coinBreakdownTitle: '本次获得的学习币',
  coinEventLabels: {
    'newQuestion': '新题目',
    'coverageStep': '覆盖率提升',
    'accuracyMilestone': '达成正确率',
    'accuracyBest': '刷新个人最佳',
    'reviewCorrected': '复习后攻克',
    'dailyConsult': '今日咨询',
    'mockDone': '完成模拟考试',
    'mockPass': '模拟考试达到及格分',
    'mockBest': '模拟考试个人最佳',
    'streak': '连续学习',
    'passReport': '通过报告',
  },
  passAskBody: '您告知的内容仅在本设备内使用。',
  passNotYet: '还没有・等待结果',
  passNotPassed: '这次没有通过',
  passPassed: '通过了',
  passEncourageTitle: '辛苦了',
  passEncourageBody: '复习薄弱点，再来挑战吧。学习币和服装都会保留。',
  passCongrats: '恭喜通过',
  passPrivacy: '分享的卡片中不会包含姓名等个人信息。',
  passShare: '分享',
  wardrobeTitle: '换装・商店',
  wardrobeNote: '学习币通过学习获得。服装只是外观，不影响学习内容。',
  wardrobeInsufficient: '学习币不足。学习即可获得',
  wardrobeAlreadyOwned: '已拥有',
  wardrobeUnknown: '无法购买',
  wardrobeCannotWear: '目前无法穿上这件服装',
  wardrobeWear: '穿上',
  wardrobeWearing: '穿着中',
  wardrobeCanWear: '可以穿上',
  lockedNotPassed: '通过考试后解锁',
  lockedNoExamDate: '设置考试日期后即可穿上',
  lockedNotReady: '达成备考目标后解锁',
  oshiMenuTooltip: '本命菜单',
  oshiChoose: '选择本命',
  oshiPassReport: '报告考试结果',
  oshiDisplayNormal: '正常',
  oshiDisplaySmall: '缩小显示',
  oshiDisplayHidden: '不显示',
  oshiName: '本命',
  oshiHiddenNote: '本命已隐藏',
  oshiYours: '你的本命',
  oshiTapHint: '点一下本命，它会说句话',
  coinBalance: _coinBalance,
  wardrobePurchased: _wardrobePurchased,
  wardrobePrice: _wardrobePrice,
  lockedNotPurchased: _lockedNotPurchased,
  passAskTitle: _passAskTitle,
  passCoin: _passCoin,
  passOutfit: _passOutfit,
  characterNames: {},
  characterRoles: {
    'standard': '烧瓶助手',
    'kai': '可靠的前辈',
    'mio': '开朗的后辈',
    'moka': '悠闲的搭档（狗）',
    'mike': '细心的讲解员（猫）',
    'circa': '爱研究原理的电路猫',
    'noda': '善于连接知识的章鱼',
    'sheru': '认真守护的乌龟',
    'hirari': '凭灵感飞翔的蝴蝶',
    'soro': '一步步数清的刺猬',
    'sala': '谨慎可靠的火蜥蜴',
    'tatsu': '爱墨与毛笔的小龙',
  },
  characterQualificationHeading: '考试专属角色',
  characterPremiumNote: '高级版可用',
  characterPreviewNote: '预览中。选择该角色需要高级版',
  characterPurchaseAction: '查看高级版',
  tabLabels: ['首页', '学习', '模拟', '记录', '设置'],
  mockRecordTitle: '学习记录卡',
  mockRecordNote: '这是模拟考试的记录，并非正式考试通过。不包含姓名等个人信息。',
  mockRecordMessage: '超过及格分了！',
  mockRecordCert: _mockRecordCert,
  shareCardBrand: 'Qualab',
  shareCardPassed: '通过了！',
  shareDate: _shareDate,
  medalTitle: '推的奖牌卡片',
  medalNote: '可以保存或分享为图片。不包含姓名等个人信息。',
  medalDisclaimer: '个人记录・非官方',
  medalSave: '保存图片',
  close: '关闭',
);
