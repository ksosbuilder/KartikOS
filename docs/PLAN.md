# Kartik OS — Build Plan

Source of truth: `docs/PRD.md` (34k words, full product spec).
This file is the ONLY thing that should be re-read at the start of a session.
Never re-paste or re-load the full PRD — reference specific section names below
and grep/read only that section when a phase needs detail.

How to use this file with Claude Code:
- Start a session with: "Read PLAN.md. We're working on Phase X."
- When a phase is done, check its box, commit, and `/clear` before starting the next.
- If Claude needs spec detail for a phase, tell it which PRD section name to grep,
  e.g. `grep -n "PRD Section — XP Chassis" docs/PRD.md` then read that range.

Note: the PRD itself never defines a build order (it says a "Development Roadmap"
should exist but stops short of writing one) — that's what this file is.

---

## Phase 0 — Foundation & Stack Decision
The PRD deliberately avoids prescribing a tech stack ("that's Claude's job").
This phase is about locking that down once, so every later phase builds on the
same assumptions instead of re-litigating it.

- [ ] Decide stack (web app first; PRD's cross-platform/offline goals are
      long-term, not MVP — see "Technical Architecture" section for the
      full ambition, but don't build for it yet)
- [ ] Recommended default: Next.js + TypeScript + Postgres (via Supabase or
      Prisma) + Tailwind — good fit for the "modular engines sharing one data
      layer" philosophy described in PRD Section — Technical Architecture
- [ ] Repo scaffold, linting, CI, deploy target
- [ ] `CLAUDE.md` written (stack, conventions, folder layout)
- [ ] Auth (single user is fine for MVP — PRD explicitly says architecture
      should just *not block* multi-user later, not support it now)

## Phase 1 — Core Data Layer
Everything in the app is "just a different visualization" of these objects —
PRD Section 4 ("Core Data Architecture") and PRD Section 12 ("Database
Architecture") define them. Build the schema before any UI.

- [ ] Entities: User, Semester, Course, Lecture, Assignment (with subtasks:
      Research/Outline/Draft/Revision/Proofreading/Submission/Reflection),
      Exam, Study Session, Grade, Goal, Habit
- [ ] XP Transactions modeled as an event log, not a stored counter
      (explicit in PRD: "Don't store XP. Store XP events.")
- [ ] Relationships wired per the tree in PRD Section 4
      (User → Semesters → Courses → {Lectures, Assignments, Exams, Grades})
- [ ] Seed/test data for local dev

## Phase 2 — Academic Engine (MVP core loop)
This is where most user interaction happens (PRD Section 2 "Academics").
This phase makes the app *useful* before it's *alive*.

- [ ] Courses tab — course workspace page (grade, breakdown, professor,
      attendance, assignments, resources, notes, past performance)
- [ ] Assignments tab — table view (Assignment, Course, Due Date, Weight,
      Status, Grade, Progress), sortable
- [ ] Exams tab — countdown, topics, confidence, practice scores
- [ ] Basic CRUD for all of the above, no gamification yet

## Phase 3 — Study Session Logging → Analytics Foundation
Ship the mechanism described explicitly in the PRD: a post-session card that
captures session detail and auto-propagates to every downstream system.

- [ ] Study session logging flow (duration, course, topic, type, focus,
      enjoyment, energy, difficulty, notes)
- [ ] On save, auto-update: course progress, GPA inputs, momentum inputs
      (this "single source of truth, no duplicate data" rule is core —
      see PRD Section — Technical Architecture)
- [ ] Analytics Engine v1: Analytics are computed, never manually entered
      (Academic, Productivity, Personal Growth, Momentum analytics —
      PRD Section 5/6)

## Phase 4 — Dashboard v1
The homepage — "if I only spend 30 seconds in the app, what should I know?"

- [ ] Hero section (greeting, semester, week, GPA current/target/predicted,
      XP, level, momentum score)
- [ ] Today's Mission (user-selected, manually chosen)
- [ ] Academic Snapshot (course cards: grade, confidence, next assessment)
- [ ] Momentum Snapshot (weekly momentum, streak, study hours, completion,
      focus score)
- [ ] Quick Analytics previews (GPA graph, weekly study graph, heatmap,
      timeline) — can be static/simple charts at this stage

## Phase 5 — XP, Levels, Momentum (gamification core)
Minimum gamification needed to make Phase 4's hero section real, before
building the full "Spider-Man Engine."

- [ ] XP transaction → level calculation
- [ ] Momentum score algorithm (first pass — PRD Section — Consistency
      Chassis has the philosophy: "rhythm over rigidity," recovery-aware)
- [ ] Streaks

## Phase 6 — Analytics Page (full)
- [ ] GPA trends, semester timeline, study distribution
- [ ] Heatmap Chassis (see PRD Section — Heatmap Chassis for categories,
      time scales, colour scaling — build 2-3 heatmap types first, not all 16)
- [ ] Confidence Chassis (calibration over magnitude — separate from grades)

## Phase 7 — Reflection & Weekly Summary
- [ ] Daily/weekly Reflection entity (mood, energy, wins, challenges, lessons)
- [ ] Weekly Summary Chassis — auto-generated narrative from the week's data
      (PRD gives an example narrative format — follow that tone, not a bullet
      list of stats)
- [ ] Historical archive (searchable past summaries)

## Phase 8 — Life Balance & Habits
- [ ] Habit tracking (streaks, completion %)
- [ ] Goals across non-academic categories (Fitness, Music, Reading, Cycling,
      Personal)
- [ ] Life Snapshot cards on dashboard
- [ ] Life Balance Chassis (seasons, gentle awareness — PRD is explicit this
      should never shame; keep tone in mind here especially)

## Phase 9 — Full Gamification ("Spider-Man Engine")
The most speculative/highest-effort subsystem — sequence it after the app is
already useful daily, not before.

- [ ] Skill Tree Chassis
- [ ] Boss Battle Chassis
- [ ] Achievement Chassis (rarity, cross-life-area coverage)
- [ ] Side Quest Generation Chassis (variety, autonomy — PRD Section — Quest
      Generation Chassis)

## Phase 10 — Insight Engine
- [ ] Pattern detection across existing data (needs Phases 3-8 data to exist
      first — this is why it's sequenced late)
- [ ] Insight generation following PRD's "Evidence First / Explain don't
      command / small insights compound" principles

## Phase 11 — Grade Simulator
- [ ] "What-if" grade calculator using existing Grade entities
      (PRD notes this becomes easy once grades are individual objects —
      confirms Phase 1's data model choice)

## Phase 12 — Visual Language & Polish
Do this once the underlying features exist — skinning empty features wastes
the density/animation work described in PRD Section — Visual Language and
Design System.

- [ ] Design system tokens (colors, spacing, visual metaphors: growth→trees,
      journey→paths, mastery→skill trees)
- [ ] Empty states (never "No Data" — always forward-looking copy per PRD)
- [ ] Motion: progress bars, animated charts, heatmap fill-in

## Phase 13 — Non-functional Hardening
- [ ] Offline support + sync
- [ ] Performance pass (instant dashboard load, smooth scroll w/ years of data)
- [ ] Cross-platform pass (PRD lists web/desktop/tablet/mobile as targets —
      confirm with Kartik which of these matter for v1 vs later)

## Phase 14 — Stretch / Explicitly Future (PRD says "not now")
Only touch these if everything above is done and stable:
- [ ] Multi-user / shared workspaces
- [ ] Research Tracker, Internship Tracker, Finance Dashboard, Travel
      Planner, Knowledge Graph, AI Study Coach (PRD's own "future modules" list)

---

## Open questions to resolve before/during Phase 0
(the PRD is a vision document, not a spec for these — decide with Kartik)
- [ ] Web-only MVP, or cross-platform from day one?
- [ ] Single user only for now — confirmed acceptable per PRD?
- [ ] Which analytics/chassis get a real algorithm vs. a simple placeholder
      in v1 (Confidence Chassis, Momentum, Life Balance all describe
      *philosophy* more than *formula* — formulas need to be defined)
