# GSD × Superpowers 통합 에이전트 방법론 연구 프로젝트

## 배경

2026년 4월 Anthropic 정책 변경으로 OpenClaw 등 서드파티 하네스에서 Claude 구독 모델 사용이 불가해졌다. Claude Code, Agent SDK 등 Anthropic 자체 제품만 구독으로 사용 가능하다. 이 프로젝트는 Claude Code 네이티브 환경에서 동작하는 궁극의 AI 에이전트 개발 방법론을 연구하고 만든다.

두 개의 검증된 오픈소스 시스템을 Fork한 뒤 분석·이식·병합한다:
- **GSD (Get Shit Done)** — https://github.com/gsd-build/get-shit-done.git
- **Superpowers** — https://github.com/obra/superpowers.git

## 프로젝트 목표

두 시스템의 장점을 연구 분석하고, 최선의 조합을 설계하여 Claude Code 네이티브에서 돌아가는 통합 에이전트 방법론을 만든다. 이것은 하네스가 아니라 **방법론 + 스킬 + 에이전트 정의 + 워크플로우**의 결합체다.

## 소스 분석 요약

### GSD (Get Shit Done) v1.32.0
- **철학**: "복잡성은 시스템 안에, 워크플로우는 단순하게"
- **아키텍처**: 4계층 (Commands → Workflows → Agents → CLI Tools → File System)
- **에이전트**: 21개 특화 서브에이전트
  - gsd-executor (실행), gsd-verifier (검증), gsd-planner (계획), gsd-phase-researcher (리서치)
  - gsd-plan-checker (계획 검증), gsd-debugger (디버그), gsd-codebase-mapper (코드맵)
  - gsd-integration-checker (통합 검증), gsd-nyquist-auditor (커버리지 감사)
  - gsd-security-auditor (보안), gsd-ui-researcher/checker/auditor (UI 3종)
  - gsd-doc-writer/verifier (문서 2종), gsd-user-profiler, gsd-assumptions-analyzer
  - gsd-research-synthesizer, gsd-roadmapper, gsd-advisor-researcher
- **워크플로우**: 60+ XML 기반 워크플로우 정의
  - 핵심: new-project → discovery → discuss → research → plan → execute → verify → ship
  - 자율모드: autonomous (--from N, --to N, --only N, --interactive)
  - Wave 기반 병렬실행: 의존관계 그래프 → 웨이브 그룹핑 → 워크트리 격리 병렬
- **상태관리**: STATE.md + ROADMAP.md + config.json + 페이즈별 추적
- **컨텍스트 엔지니어링**: 
  - context-budget.md (4단계 열화 티어: PEAK/GOOD/DEGRADING/POOR)
  - agent-contracts.md (에이전트간 완료마커 + 핸드오프 스키마)
  - continuation-format.md (세션 중단/재개 프로토콜)
- **참조문서**: 25개 reference (verification-patterns, tdd, model-profiles, gate-prompts 등)
- **템플릿**: 33개 (프로젝트, 마일스톤, 리서치, 검증보고서, UAT, 보안, UI-SPEC 등)
- **CLI 도구**: gsd-tools.cjs + 15개 lib 모듈 (state, roadmap, phase, verify, security 등)
- **훅 시스템**: 9개 훅 (context-monitor, prompt-guard, read-guard, workflow-guard 등)
- **테스트**: 90+ 테스트 파일, SDK 포함
- **SDK**: TypeScript SDK (cli-transport, context-engine, phase-runner, prompt-builder 등)
- **멀티 런타임**: Claude Code, Gemini, Codex, Copilot, Cursor, Windsurf, Cline, Augment, Trae, Kilo, OpenCode, Antigravity

### Superpowers (obra/superpowers)
- **철학**: "스킬이 자동으로 트리거되어 에이전트에게 초능력을 부여"
- **아키텍처**: 스킬 기반 (SKILL.md가 로드되면 에이전트 행동이 바뀜)
- **핵심 파이프라인**: brainstorm → write-plan → execute-plan (3개 명령)
- **스킬 12개**:
  1. **brainstorming** — 아이디어 → 디자인 (HARD GATE: 스펙 승인 전 코드 금지)
     - 한 번에 하나의 질문, 2-3개 접근법 제안, 섹션별 승인
     - 비주얼 컴패니언 (브라우저 기반 목업/다이어그램)
     - 스펙 셀프리뷰 (placeholder scan, consistency, scope, ambiguity)
  2. **writing-plans** — 스펙 → 구현 계획
     - "컨텍스트 제로, 취향 없는 엔지니어" 가정
     - 2-5분 단위 바이트사이즈 태스크
     - 모든 스텝에 완전한 코드 (placeholder 절대 불가)
     - DRY, YAGNI, TDD 구조적 강제
  3. **subagent-driven-development** — 핵심 실행 스킬
     - 태스크당 신선한 서브에이전트 (컨텍스트 오염 방지)
     - 2단계 리뷰: 스펙 준수 → 코드 품질
     - 구현자 4가지 상태: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED
     - 모델 선택: 기계적 → 저비용, 통합 → 표준, 아키텍처 → 최고급
     - 전용 프롬프트 템플릿 3개 (implementer, spec-reviewer, quality-reviewer)
  4. **executing-plans** — 인라인 실행 (서브에이전트 없이)
  5. **verification-before-completion** — 철의 법칙 (Iron Law)
     - "검증 없이 완료 선언은 거짓말"
     - IDENTIFY → RUN → READ → VERIFY → CLAIM
     - 합리화 방지 테이블, 레드 플래그 목록
     - 24개 실패 기억으로부터 도출
  6. **test-driven-development** — TDD 강제 + 테스트 안티패턴 가이드
  7. **systematic-debugging** — 체계적 디버깅
     - root-cause-tracing, defense-in-depth, condition-based-waiting
     - 3단계 압력 테스트 (pressure test)
  8. **using-git-worktrees** — 격리된 작업공간
  9. **dispatching-parallel-agents** — 병렬 에이전트 디스패치
  10. **requesting-code-review** / **receiving-code-review** — 코드 리뷰 요청/수신
  11. **finishing-a-development-branch** — 브랜치 완료 절차
  12. **writing-skills** — 스킬 작성 방법 (메타스킬)
      - anthropic-best-practices, persuasion-principles
      - 서브에이전트로 스킬 테스트
- **using-superpowers 스킬** (메타 컨트롤러):
  - "1%라도 스킬이 적용될 가능성이 있으면 반드시 호출"
  - 합리화 방지 (Red Flags), 우선순위 체계 (User > Skills > System)
- **훅**: SessionStart에서 세션 초기화
- **플러그인 지원**: Claude Code 마켓플레이스, Cursor, Codex, OpenCode
- **제로 의존성**: 순수 마크다운, npm 패키지 없음, 빌드 도구 없음

## 두 시스템의 핵심 차이

| 영역 | GSD | Superpowers |
|------|-----|-------------|
| 복잡도 | 풍부하고 복잡 (21 에이전트, 60+ 워크플로우) | 간결하고 깊음 (12 스킬, 3 명령) |
| 실행 모델 | Wave 기반 병렬 → 오케스트레이터 → 워크트리 격리 | 태스크별 서브에이전트 → 2단계 리뷰 |
| 설계 단계 | discuss-phase + assumptions-analyzer | brainstorming HARD GATE + 시각적 컴패니언 |
| 검증 | 전문 검증 에이전트 (verifier, nyquist-auditor) | Iron Law: 모든 스킬에 내장된 검증 마인드셋 |
| 상태관리 | STATE.md + ROADMAP.md + CLI 도구 | 경량 (git worktree + plan 체크박스) |
| 계획 품질 | planner-reviews, planner-gap-closure, revision-loop | "placeholder 절대 불가", 모든 스텝에 실제 코드 |
| 컨텍스트 관리 | context-budget 4단계 + continuation protocol | 태스크당 fresh subagent = 깨끗한 컨텍스트 |
| 보안 | security-auditor 에이전트 + prompt-guard 훅 | 없음 (범위 밖) |
| UI/UX | ui-researcher/checker/auditor 3종 에이전트 | 비주얼 컴패니언 (브라우저 목업) |

## 시너지 기회 (병합 시 얻는 것)

| GSD가 가져오는 것 | Superpowers가 가져오는 것 | 병합 결과 |
|------------------|------------------------|----------|
| 21개 전문 에이전트 | 깔끔한 스킬 아키텍처 | 스킬로 조직된 전문 에이전트 |
| Wave 기반 병렬 실행 | 태스크별 2단계 리뷰 | 병렬 + 리뷰드 |
| 자율 모드 (autonomous) | HARD GATE (스펙 승인) | 사람이 디자인 승인한 후 자율 실행 |
| STATE.md 상태 추적 | Iron Law 검증 | 검증된 상태 (가정이 아닌 증거) |
| 컨텍스트 버짓 관리 | Fresh subagent per task | 두 전략 동시 사용 |
| 60+ 워크플로우 | 제로 의존성 스킬 | 스킬이 워크플로우를 트리거 |
| 보안/UI/문서 감사 | TDD-first 규율 | 감사되고 테스트된 결과물 |
| SDK + CLI 도구 | 구현자/리뷰어 프롬프트 템플릿 | 프로그래매틱 + 프롬프트 최적화 |

## 통합 파이프라인 비전

```
Phase 1: BRAINSTORM (Superpowers brainstorming)
  → 한 번에 하나의 질문, 2-3 접근법, HARD GATE
  
Phase 2: RESEARCH (GSD research-phase)  
  → 코드베이스 스카우팅, Don't Hand-Roll, Common Pitfalls
  
Phase 3: PLAN (GSD roadmapper + Superpowers writing-plans)
  → 로드맵 + 마일스톤/페이즈 구조 (GSD)
  → 바이트사이즈 TDD 태스크 + 완전한 코드 (Superpowers)
  → 계획 품질 리뷰 (GSD plan-checker)
  → 의존관계 → 웨이브 그룹핑 (GSD)

Phase 4: EXECUTE (GSD wave execution + Superpowers subagent-driven)
  → Wave 기반 병렬 디스패치 (GSD)
  → 태스크당 fresh subagent (Superpowers)
  → 2단계 리뷰: 스펙 + 품질 (Superpowers)
  → 워크트리 격리 (GSD)
  → 4가지 구현자 상태 (Superpowers)

Phase 5: VERIFY (GSD verifiers + Superpowers Iron Law)
  → Iron Law: 증거 → 주장 (Superpowers)
  → 전문 검증 에이전트 (GSD verifier, nyquist-auditor)
  → 통합 검증 (GSD integration-checker)
  → 보안 감사 (GSD security-auditor)

Phase 6: SHIP (GSD state management)
  → STATE.md 갱신, 마일스톤 완료, 문서 생성
```

## 제약 조건

- **Claude Code 네이티브 전용**: 서드파티 하네스 없이 동작해야 함
- **하네스가 아님**: 방법론 + 스킬 + 에이전트 정의 + 워크플로우의 결합체
- **소스 분석 위치**: `gsd-original/` (GSD 레포), `superpowers-original/` (Superpowers 레포)

## 이 프로젝트에서 만들 것

1. **심층 비교 분석 문서** — 두 시스템의 아키텍처, 패턴, 장단점 체계적 분석
2. **통합 설계 문서** — 병합 아키텍처, 파이프라인, 인터페이스 설계
3. **통합 스킬 세트** — Superpowers 스킬 + GSD 워크플로우 병합
4. **통합 에이전트 정의** — GSD 에이전트를 Superpowers 스킬 체계로 재조직
5. **통합 참조 문서** — 컨텍스트 버짓, 검증 패턴, 에이전트 계약 등
6. **CLAUDE.md** — Claude Code에서 이 방법론을 자동 로드하는 설정
7. **실증 검증** — 실제 프로젝트에서 통합 방법론 적용 테스트
