# MemDoping — Master Project

Status: product direction and implementation brief; final curriculum, efficacy, pricing, and brand clearance remain unverified. Synthesized from the full “Havuz Eğitimleri” conversation and the latest requirements. Earlier 100–200-level references are superseded by the 150–200-level target. Implementation details below are proposed specifications, not completed features.

## 1. Identity and purpose

MemDoping is a global learning game platform that turns science-based memory and learning techniques into short, adaptive, and personalized game experiences. Don't add games to education. Turn education into the game.

- Brand: **MemDoping**. Turkish concept: **Hafıza Dopingi**. Supporting line: “Memory Training, Turned Into a Game.”
- Build a mobile-first game for App Store and Google Play: learn through actions, challenges, feedback, and progression; resume anywhere without scheduled classes.
- Global audience: children, teens, adults. Share one learning architecture while adapting language, presentation, session length, accessibility, and social safeguards to each audience.
- Core loop: **Play → Learn → Remember → Level Up**. Each session offers a short mission, practice through play, recall, useful feedback, rewards, and a clear stopping point.
- Long-term ambition: expand from memory techniques into a broader global learning game platform; validate the initial experience first.

### Name rationale

“Mem” signals memory; “Doping” is a metaphor for a motivating boost and a curiosity hook. Keep XP inside the product as **MemDoping XP**, not part of the brand name. Use an approachable, distinctive identity that suits children and adults.

The name does not imply drugs, medical treatment, or biological enhancement. Test cultural associations and comprehension by market. **Trademark/legal review is pending**, including possible similarity to “Doping Hafıza”; wording or game positioning alone does not establish clearance. Recheck trademarks, domains, social handles, and store listings before launch. Prior conversation claims about availability, registrations, or absence of competitors are not verified findings.

## 2. Game mechanics and progression

| System | Purpose and rules |
|---|---|
| MemDoping XP | Reward completed learning actions, effort, review, and milestones. Keep reward rules transparent; prevent repetitive farming. XP is progression, not proof of cognitive improvement. |
| Memory Score | Show in-game recall performance and trends using comparable tasks, accuracy, delayed recall, difficulty, and hint use. Define and validate the formula before release; show insufficient-data states. Not an IQ, clinical, or universal memory score. |
| Levels | Unlock through demonstrated readiness and prerequisite mastery; allow review and supportive retries. Exact thresholds require testing. |
| Daily missions | Offer manageable choices, short routines, milestones, and optional streaks with forgiving recovery. |
| Feedback | Explain mistakes, demonstrate a strategy, and let the player retry without shame. Favor learning quality over speed. |

## 3. Learning Engine and 150–200-level architecture

**Architecture only: do not generate or represent a final 150–200-level curriculum yet.** Reserve 150 core level slots and up to 50 extension slots. Determine exact counts, assignments, age suitability, objectives, and prerequisites after evidence and materials review.

Provisional progression, simple → complex:

1. Orientation, accessible baseline, one rule at a time, highly guided practice.
2. Practice one approved technique with gradual reduction of hints.
3. Increase task complexity and introduce delayed recall and spaced review.
4. Combine approved techniques across varied contexts and mixed challenges.
5. Independent strategy selection, cumulative missions, and measured application to new tasks.

These are design stages, not fixed level ranges or an approved academic sequence. Review activities may recur across stages; harder must mean greater learning demand, not merely tighter timers.

**Research candidates, not approved curriculum:** attention and encoding, association and imagery, chunking, retrieval practice/active recall, spaced practice, interleaving, elaboration, story linking, method of loci/memory palace, peg systems, number systems, Major System, and PAO. Evaluate evidence and age/context fit for each; do not imply equal support or broad transfer.

**Required inputs:** academic studies and reviews; university/open educational resources; relevant open-source resources with checked licenses; future user-supplied materials, potentially including Doping Hafıza/Mega Hafıza materials when supplied and usable. Sources named earlier—MIT OpenCourseWare, Stanford, Art of Memory, StretchLearn—are research leads, not verified endorsements or cleared content. No course attachments were available in the retrieved conversation.

**Content pipeline:** collect → record source/license → evaluate evidence and limitations → extract learning objective → create original game mechanic → map prerequisites → expert review → pilot → revise → publish/version. Access or purchase alone must not be treated as permission to redistribute source content.

Minimum level record:

`id | status | audience | locale | objective | technique | prerequisites | source_ids | evidence_notes | rights_status | mechanic | difficulty_parameters | hints | feedback | mastery_rule | review_rule | version`

Use explicit placeholders: `[RESEARCH REQUIRED]`, `[AWAITING MATERIALS]`, `[EXPERT REVIEW]`, `[VALIDATION REQUIRED]`. A prototype may use clearly labeled sample content; never pass samples off as final curriculum.

## 4. Experience engines

### Sensory Motivation Engine

Use readable visuals, restrained animations, optional sound/haptics, progress reveals, and satisfying completion feedback to support curiosity, competence, and enjoyment. Provide mute, reduced motion, adjustable intensity, and non-color-only cues. Do not infer mental state from interaction patterns or claim that audiovisual effects release dopamine, serotonin, or melatonin. Test comfort and learning alongside return rates.

### Relax & Unwind Engine / Night Doping

Offer an optional calm experience: low-intensity visuals, gentle sound, untimed play, familiar easy activities, minimal competition, and an explicit session ending. Respect quiet hours and user preferences. Position as a way to unwind; make no sleep-treatment, stress-treatment, or hormone claims. Never encourage sacrificing sleep to preserve progress.

## 5. Social systems and economy

- Optional friends, cooperative goals, leagues, seasons, and challenges. Match fairly by relevant performance and progression; protect beginners from punitive comparisons.
- Private profiles and restricted interactions by default for children; age-appropriate parental controls, reporting, blocking, moderation, and limited shared data. Social participation is optional.
- Free introductory experience; subscriptions for expanded content/features; family plan with separate profiles; optional cosmetics with no learning or competitive advantage. Prices, limits, trial terms, and regional tiers remain TBD.
- Careful ads: no interruption during encoding or recall; no ads in Night Doping. Prefer no ads for children; any other ad placement requires age/market review, clear labeling, and limits. Do not trade learning scores or competitive advantage for ad views.
- Avoid pay-to-win, paid score inflation, coercive countdowns, punitive streak loss, and manipulative purchases. Make subscription terms and cancellation clear.

## 6. Retention & Reactivation Engine

Bring users back through value: due reviews, optional reminders, personal progress summaries, achievable daily missions, and welcoming return sessions. Example Turkish copy: “Bugünkü hafıza dopingin 6 dakikanı alır” only when the estimated session supports that claim.

Respect opt-in choices, quiet hours, frequency limits, and easy disabling. After inactivity, offer a light recap and adjust difficulty; preserve earned progression. Optimize useful practice and satisfaction, not compulsive time spent. Evaluate return rate with delayed recall, frustration, notification opt-outs, and session overrun. Experiments must preserve these safeguards.

## 7. Adaptive difficulty and AI personalization

- Inputs: chosen goals, language, age band where needed, accessibility preferences, accuracy, hints, comparable response times, delayed recall, and recent practice. Minimize data and explain its use.
- Start with transparent rules: repeated success permits one small difficulty increase; repeated errors trigger hints, simpler variants, or review. Adjust item count, distractor similarity, retention delay, and scaffolding. Calibrate thresholds through pilots.
- AI may select approved content, sequence missions, suggest strategies, and personalize wording within reviewed constraints. Maintain source provenance and a deterministic fallback; never invent scientific evidence or silently publish generated curriculum.
- Separate XP, performance measurement, content selection, and reminder logic. Payment must not change Memory Score. Do not use vulnerable moments or sensitive inferred traits to target purchases.
- Evaluate personalization against a baseline using held-out/delayed recall, task completion, and user comfort. Do not equate increased engagement with learning efficacy.

## 8. Global growth and store positioning

Design multilingual content and UI from the start, with English and Turkish as initial planning anchors. Localize instructions, audio, examples, cultural references, reading demands, accessibility, and scoring comparability. Choose further languages and launch regions after pilots; do not assume identical tasks work equally across languages.

App Store/Google Play SEO (ASO) direction: distinctive brand plus a clear descriptor. Draft title: **MemDoping: Memory Games**. Supporting phrase: “Play, Learn, Remember.” Turkish concept copy: “Hafıza Dopingi.” Candidate search themes: memory games, memory training, learning games, recall, focus, mnemonic techniques. Use “brain training” only with accurate, limited claims.

Treat titles and keywords as test candidates, not ranking promises or verified demand. Validate current store metadata rules before submission; localize screenshots to show actual gameplay and benefits. Do not imply affiliation with competitors or use their identity to mislead discovery.

## 9. Benefits and evidence boundary

Required benefits disclaimer for website/store/product copy:

> Regular use may support memory performance, focus, and recall. Results vary by person; there is no 100% improvement guarantee.

Turkish equivalent:

> Düzenli kullanım hafıza performansını, odaklanmayı ve hatırlamayı destekleyebilir. Sonuçlar kişiden kişiye değişir; %100 gelişim garantisi yoktur.

This is cautious proposed copy, not proof of MemDoping efficacy. Validate claims against product-specific evidence before publication. Do not promise IQ gains, medical benefits, disease prevention, or general cognitive transfer from in-game improvement. Distinguish trained-task gains, delayed recall, and transfer; report study population, limitations, and uncertainty.

## 10. Developer / AI prompts — simple → complex

Use this document as shared context once. Apply prompts sequentially; preserve established decisions and mark missing evidence instead of filling gaps. Return concise specifications, acceptance criteria, and unresolved inputs for each stage.

### P1 — Core idea

“Define MemDoping for children, teens, and adults using the exact description in §1. Show how Play → Learn → Remember → Level Up makes the learning action the game. Preserve Hafıza Dopingi as the Turkish concept and keep claims within §9.”

### P2 — Playable loop

“Specify one short sample mission: entry, learning action, recall, feedback, retry, MemDoping XP, Memory Score display, and exit. Label sample content. Include accessible controls and age-appropriate variants.”

### P3 — Level framework

“Design a data-driven 150–200-level framework from simple to complex using §3. Define dependencies, content records, review scheduling, and validation gates. Leave final objectives and level assignments pending research and supplied materials.”

### P4 — Experience, social, and economy

“Specify Sensory Motivation Engine, Night Doping, optional social systems, leagues/challenges, subscriptions, family plan, cosmetics, and limited ads. Separate monetization from performance. Include clear stopping points and age-appropriate defaults.”

### P5 — Retention and measurement

“Specify Retention & Reactivation Engine with consent, quiet hours, frequency caps, due-review reminders, and gentle return sessions. Define minimal events and experiments measuring learning, satisfaction, and return behavior together.”

### P6 — Adaptation and AI

“Design rule-based adaptation first, then bounded AI personalization over reviewed content. Define inputs, parameter updates, cold start, provenance, privacy, fallback behavior, and evaluation. Keep generated curriculum in review until approved.”

### P7 — Implementation and global release

“Convert the approved specifications into a phased backlog and modular architecture: profile/consent, content registry, game runtime, Learning Engine, progression, scoring, review scheduler, personalization, sensory/night settings, social, billing, localization, and analytics. Propose stack choices with tradeoffs; do not treat them as decided. Start with a small reviewed vertical slice before expanding to 150–200 levels. Include tests for reward integrity, scoring comparability, adaptive fallback, locale behavior, and notification preferences; flag research, rights, brand, and store-review dependencies.”

## 11. Next inputs and completion gates

- Supply educational materials and complete academic/open-source research; record evidence and reuse rights.
- Select initial audience, pilot locales, session targets, and prototype mechanics; validate learning and usability.
- Establish scoring definitions, progression thresholds, adaptive parameters, and measurable success criteria.
- Confirm brand clearance, launch markets, pricing, child protections, and store metadata requirements.
- Expand only reviewed content; maintain versioned source-to-level traceability. This master brief is complete as a planning artifact; curriculum and implementation are future work.
