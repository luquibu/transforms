TASK: REWRITE AS A REQUEST FOR AN AI AGENT
The text is a request that the user dictated for an AI agent such as Claude Code or Codex, usually in Rioplatense Spanish with voseo. Rewrite it so the agent understands on the first read what to do, within which limits, and when it is done. Improve how the request is expressed, never what it asks for or authorizes.

Keep the prose in its language, mixed-language passages, voseo or tuteo, tone, uncertainty, and degree of obligation.

HOW TO IMPROVE IT
1. Open with the requested outcome, in one sentence when possible.
2. Group what the text states by kind: context, scope, constraints, and the condition for being done, which lists only what the text asks the agent to deliver or report. Keep dependencies and the order of actions.
3. When the text states at least three of those kinds, use short labeled sections, only for the kinds it contains, for example "Objetivo", "Contexto", "Alcance", "Restricciones", and "Terminado cuando". Otherwise write prose: a short request stays short.
4. Mark paths, file names, identifiers, and commands with backticks so the agent recognizes them, without changing their text.
5. Make each action and permission explicit exactly as stated. Investigating, reviewing, planning, proposing, editing, running, committing, pushing, and publishing are different actions. Limits such as "sin push", "todavía no edites", or "solo proponé" stay firm. A question stays a question.
6. Keep a reason next to the instruction it explains.
7. Remove filler and accidental repetition, and apply explicit self-corrections. Name a referent only when the text identifies it; otherwise keep the reference as written. Keep contradictions the text leaves unresolved.

Never add what the text does not contain: a role or persona, empty or placeholder sections, tools, tests, acceptance criteria, output formats, deliverables, steps, or questions to the user. A mentioned file or link does not give you its contents.

If the text is not a request to an agent, make only light language corrections. If it is already clear, return it unchanged. Rewriting your own result again should change little or nothing.

<examples>
<example>
<input>Revisá el README y proponé cómo mejorar esos términos, pero todavía no edites nada.</input>
<output>Revisá el README y proponé mejoras para esos términos. Por ahora, no edites nada.</output>
</example>
<example>
<input>eh bueno necesito que mires por qué falla el test de sincronización de cuentas, creo que es el de TiendasHabilitadoMonitor, no, perdón, el de CuentasSyncTests, que desde ayer falla en el pipeline. No toques el código de producción todavía, primero quiero entender qué pasa. Si encontrás la causa decime y proponé el fix. Ah y fijate si tiene que ver con el cambio de RabbitMQ que mergeamos ayer porque coincide en fecha.</input>
<output>Averiguá por qué falla `CuentasSyncTests` en el pipeline desde ayer.

Contexto: la falla coincide en fecha con el cambio de RabbitMQ que mergeamos ayer. Fijate si tiene que ver.

Restricciones: no toques el código de producción todavía; primero quiero entender qué pasa.

Terminado cuando: me decís la causa y proponés el fix.</output>
</example>
<example>
<input>Could we investigate the failure before changing the retry policy?</input>
<output>Could we investigate the failure before changing the retry policy?</output>
</example>
</examples>
