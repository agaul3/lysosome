# Milestone 9 acceptance — Knowledge Interface

Spec: `docs/design/medical_school_rpg_spec.md` §31, §32 and §42 (Milestone 9). Acceptance criterion: **displayed statistics match question history.**

| Requirement | Implementation | Evidence (`knowledge_test.gd`) |
|---|---|---|
| Accuracy = correct ÷ attempted | `education/knowledge/knowledge.gd` `accuracy()` (0 attempts → shown as "—", never divides by zero) | "Zero-attempt state is safe" |
| Pharmacology └ Pharmacodynamics (and subtopics) | `Knowledge.tree()` builds discipline → topic → subtopic from the question bank's taxonomy plus recorded statistics | hierarchy and lecture-order subtopic checks |
| Attempted/correct increment after each question; percentages recalculate | `AcademicSession.topic_statistics` (updated on every `QuestionBank.submit`); the page refreshes on `answer_recorded` and whenever it becomes visible | increment and recalculation checks |
| Knowledge menu | New **Knowledge** tab in the player menu (Today · Calendar · Knowledge · Settings): overall summary, an accuracy row with a bar for each level, and the six most recent answers | menu tab and row checks |
| Displayed statistics match question history | `Knowledge.from_history()` recounts from the raw attempt history; the test compares every displayed row to that recount | "Displayed statistics match question history at every level" |
| Architecture supports future disciplines and subtopics | The tree is data-driven: any new discipline, topic or subtopic in the bank or the statistics appears without code changes | "Architecture supports further disciplines and subtopics" |

**Taxonomy:** subtopics now follow the lecture: Receptors and ligands, Agonists, Antagonists, Competitive antagonism, Noncompetitive antagonism, Potency, Efficacy, Dose-response, Clinical application. Three seed questions were reassigned from "Dose-response" and "Antagonism" to their specific subtopics.

**Deferred per spec:**
- A mastery algorithm using recency, difficulty, forgetting or confidence.
- The Overview, Campus Map, Lecture Notes, Achievements and Inventory menu pages (Milestone 10).
- Save/load.
