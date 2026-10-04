// Authored synthetic diagnostics, not independent labels or user research.
// Freeze this file before the first native run. Do not tune on its results.
const retrievalRecords = [
  'I followed a popular trader without checking the claim. Later I found no primary source. My lesson is to verify evidence before trusting a crowd.',
  'I sent money to help a friend pay a shared dinner bill. We confirmed the amount together. Check the recipient address before paying.',
  'I moved tokens between my own wallets for storage. I compared the destination carefully. Keep savings separate from daily spending.',
  'I entered a trade because I feared missing a fast price rise. I ignored my limit and regretted the rush. Pause before acting on excitement.',
  'I reviewed a planned investment with a strict budget. I kept the amount within my limit. Recheck the plan before changing exposure.',
  'I was tired and skipped my usual checks. The next morning I saw the missing information. Wait until rested before making a decision.',
  'I cooked vegetable soup for lunch. I used too much salt. Taste the soup before seasoning again.',
  'I scheduled a short walk before starting work. It helped me concentrate. Put a break on the calendar.',
];
// (language, expected record index, query); two themes in eight languages.
const retrievalQueries = [
  (
    'en',
    0,
    'Everyone online recommends it, but I have not verified the evidence.',
  ),
  (
    'en',
    3,
    'The price is jumping and I feel pressure to act before it is too late.',
  ),
  ('ko', 0, '다들 좋다고 하는데 근거가 되는 원문은 아직 확인하지 않았다.'),
  ('ko', 3, '가격이 급등해서 나만 기회를 놓칠까 봐 조급하게 결정하려 한다.'),
  ('ja', 0, 'みんなが勧めているが、根拠となる一次情報はまだ確認していない。'),
  ('ja', 3, '価格が急騰し、自分だけ機会を逃すのが怖くて焦っている。'),
  ('zh', 0, '大家都在推荐，但我还没有核实原始证据。'),
  ('zh', 3, '价格突然上涨，我怕错过机会而急着行动。'),
  ('hi', 0, 'सब इसकी सलाह दे रहे हैं, लेकिन मैंने मूल सबूत अभी नहीं जाँचे।'),
  (
    'hi',
    3,
    'कीमत तेजी से बढ़ रही है और मौका छूटने के डर से मैं जल्दबाजी कर रहा हूँ।',
  ),
  (
    'es',
    0,
    'Todos lo recomiendan, pero todavía no he comprobado la fuente original.',
  ),
  (
    'es',
    3,
    'El precio se dispara y temo perder la oportunidad si no actúo ya.',
  ),
  (
    'pt',
    0,
    'Todos recomendam, mas ainda não verifiquei as provas na fonte original.',
  ),
  (
    'pt',
    3,
    'O preço está disparando e tenho medo de perder a oportunidade se não agir agora.',
  ),
  (
    'fr',
    0,
    'Tout le monde le recommande, mais je n’ai pas encore vérifié les preuves à la source.',
  ),
  (
    'fr',
    3,
    'Le prix grimpe vite et j’ai peur de rater l’occasion si je n’agis pas maintenant.',
  ),
];
