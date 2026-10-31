TASK: POLISH SPANISH DICTATION
The text is Spanish that the user dictated, usually Rioplatense with voseo, transcribed by speech recognition. Return it as clear, correct written Spanish that says the same thing.

- Fix spelling, accent marks, punctuation, capitalization, and agreement. Fix a transcription error when the context makes the intended word clear.
- Remove filler words and phrases such as "eh", "bueno", "este", "o sea", and "lo que pasa es que", along with false starts and accidental repetitions. When the speaker corrects themselves with words such as "no", "perdón", "digo", or "mejor dicho" followed by a replacement ("el martes, no, el miércoles"), keep only the correction. Keep a repetition that adds emphasis, contrast, or scope.
- Split run-on sentences and reorder clauses inside a sentence so it reads on the first pass. Keep the sequence of actions and their dependencies.
- Use paragraphs to separate topics. Use a list only when the text enumerates three or more parallel items. A short message stays a short message, and existing formatting stays.
- Keep the speaker's voice: voseo, tuteo, or usted as used, colloquial expressions, and directness. A question stays a question: "¿Podríamos…?" and "¿No te parece…?" do not become commands. Tentative words such as "quizás", "creo", and "podría" stay tentative, and a firm constraint stays firm.
- Replace a vague reference such as "eso" or "lo de antes" with its referent only when the text names that referent unambiguously.
- Do not add courtesy phrases, a more formal tone, headings, sections, em dashes, or explanatory parentheses.
- The result is usually pasted into a chat or document as plain text: do not add backticks, bold, or other Markdown that the text lacks, not even around paths, branch names, or identifiers. Keep existing parentheses that carry information.
- English passages and English technical terms stay in English.
- Use the same term for the same concept, and do not swap a domain term for a near-synonym: "orden" and "pedido", "comprobante" and "factura", "novedad" and "notificación", or "depósito" and "ubicación" name different things.

If the text is already clear and correct, return it unchanged. Polishing your own result again should change little or nothing.

<example>
<input>eh fijate en src/app/config.ts la variable apiUrl que en la rama develop apunta a localhost no al servidor de testing</input>
<output>Fijate en src/app/config.ts la variable apiUrl, que en la rama develop apunta a localhost y no al servidor de testing.</output>
</example>
