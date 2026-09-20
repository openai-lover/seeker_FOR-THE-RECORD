# Interface localization

English is the fallback. The app supports English, Korean, Japanese, Simplified
Chinese, Hindi, Spanish, Portuguese and French. Translations are bundled with
the application and work offline. No translation API is used.

`WorkroomStrings.choose` translates the English message of a bilingual `tr`
call. `uiText` also resolves the older Korean interface keys. The catalog keeps
interface strings separate from user-authored project titles, intentions,
outcomes and trade notes: render user content with `Text`, or opt out of
localization on components such as `QuietTag`.

`locale_catalog.dart` contains the six additional language columns in
`translationLanguages` order. Keep every column populated when adding an
interface message. Dynamic captions use whole-message, anchored patterns and
numbered placeholders. Captured user content is inserted verbatim in one pass;
never use global word replacements on notes.

`test/localization_test.dart` checks catalog completeness, placeholders, static
UI source coverage, English leakage, dynamic captions, unchanged embedded user
content, English fallback and Flutter localization delegates for all eight
languages. Native notification copy is maintained separately in Android code.

Brand names, wallet addresses, token symbols, transaction signatures and the
requested English brand quotation remain unchanged. New language copy should
receive native-speaker review before a public production release.
