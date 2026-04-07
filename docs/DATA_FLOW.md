The Technical Architecture of Coozila! Studio v4.2: A Professional Framework for AI Cinematic Orchestration
================================================================================

This document provides a comprehensive technical analysis of the Coozila! Studio v4.2 architecture, focusing on its state-driven OTIO manifests, MCP-based agent orchestration, and professional-grade output pipelines. It introduces timestamped data flow to enable traceability, auditability, and real-time visualization in OpenWebUI.

Table of Contents
- 1. The Core Philosophy
- 2. The Mathematical Foundation and 64-Pixel Alignment
- 3. The Core Architecture
- 4. Layered Architecture
- 5. OTIO Model, Box States and Temporal Semantics
- 6. End-to-End Data Flows with Timestamps
- 7. Infrastructure, Deployment, and Communication
- 8. Model Context Protocol (MCP)
- 9. Security, Audit, HITL and Governance
- 10. Examples: OTIO with Timestamps and MCP Messages
- 11. MVP Implementation Plan (with Timestamps)
- 12. Extensions and Future Architecture
- 13. Glossary
- 14. How to Save this Document in a Repo

1) The Core Philosophy
- Precision Over Chaos: Treat AI as a Technical Director, enforcing cinematic standards, identity persistence, and stable lighting/voice cues across shots.
- State-Driven Manifest: The OTIO JSON manifest is the single source of truth; state gates drive progression from creative intent to technical execution.
- Decoupled, Asynchronous Architecture: User/Agent orchestration is decoupled from the Execution Layer via manifest state, enabling resilience and scalability.
- Real-time Visualization: Visualization Layer (OpenWebUI Canvas) mirrors the manifest and provides HITL-friendly interfaces for human review and approval.
- Auditability: Every action (agent edits, user edits, render starts/ends) is timestamped and auditable.

2) The Mathematical Foundation and 64-Pixel Alignment
- Identity persistence and frame-level consistency are enforced at the resolution level: all render outputs use 64-pixel-aligned dimensions.
- Profiles (Landscape, Portrait, Square) are designed to preserve cinematic aspect ratios while respecting 64n divisibility for tile-based NVIDIA tensor-core scheduling.
- This foundation enables deterministic rendering behavior, reduces padding artifacts, and improves GPU efficiency across long sequences.

3) The Core Architecture
- Four-layer orchestration:
  - User Layer: Canvas UI in OpenWebUI for storyboard creation, edits, and visual confirmation.
  - Agent Layer: MCP-enabled AI agents that translate prompts into OTIO metadata and manifest edits.
  - Visualization Layer: Real-time synchronization between OTIO manifests in storage and the UI, including live updates and partial edits.
  - Execution Layer: Worker nodes (mcp-studio) that poll manifests, claim work, execute tasks (rendering, analysis), and update the manifest with progress and results.
- Messaging Backbone: NATS JetStream or alternative (Redis Streams / Postgres NOTIFY) to support low-latency, reliable event-driven updates.
- Storage Backbone: Cloud storage (S3/MinIO) holding OTIO manifests (JSONB) and assets; versioning and audit trails are enabled.

4) Layered Architecture
- User Layer (Canvas UI)
  - Real-time editing of OTIO manifest; edits reflected in storage with updated timestamps.
  - Permission checks enforce field-level editing based on the project state.
- Agent Layer (MCP)
  - Agents expose Tools, Resources, Prompts; act on manifest changes, enrich metadata, and log actions with timestamps.
  - Zero-trust with scoped permissions; HITL for critical actions.
- Visualization Layer (Canvas View)
  - Streaming updates via SSE/WebSocket; shows manifest state, progress bars, and preview data as available.
- Execution Layer (mcp-studio and Workers)
  - Polls for READY manifests, claims boxes, runs analysis/render tasks, and updates the manifest with progress and results.
  - Optional: Temporal.io for durable workflows; GPU-scheduled nodes for rendering.

5) OTIO Model, Box States and Temporal Semantics
- OTIO manifest serves as the state machine for the Box.
- Core Box states (example):
  - DRAFT_DEFINING
  - DRAFT_VISUALIZING
  - READY_FOR_STUDIO
  - TASK_CLAIMED
  - PROCESSING
  - WORK_IN_PROGRESS
  - TASK_FINISHED
  - COMPLETED
  - PENDING_APPROVAL
- Temporal fields in OTIO metadata (recommended):
  - created_at, updated_at, state_changed_at
  - render_started_at, render_completed_at
  - preview_available_at
  - manifest_version
  - trace_id
- Pertinent OTIO metadata for each clip/track:
  - scenography: user_prompt, tags, prompt_relay
  - workflow_state: visual_scenography, timing, identity_anchor
  - timestamps: per-clip or per-element edit timestamps
- All modifications to OTIO should carry timestamp metadata to enable traceability and replay.

6) End-to-End Data Flows with Timestamps
- Flow 1: Canvas Edit
  - User edits OTIO in Canvas; updated_at is set; an event_log entry with timestamp and actor is created.
- Flow 2: MCP Agent Edit
  - Agent processes a prompt, updates manifest with new scenography/prompt_relay; updates state_changed_at and per-change timestamps.
- Flow 3: READY Gate
  - User marks READY_FOR_STUDIO; state_changed_at is updated; a manifest event is emitted to the execution layer.
- Flow 4: Execution
  - mcp-studio monitors for READY; render_started_at is set; job runs; on completion, render_completed_at and progress_metadata (e.g., render_uri) are written; state_changed_at updates.
- Flow 5: Visualization
  - UI subscribes to manifest events; canvas re-renders with new state, progress, and previews; user may request more edits (subject to ACL).
- Flow 6: Validation and Audit
  - All events are timestamped and logged for audit; if necessary, users or agents can view the history with associated timestamps and actor identity.

7) Infrastructure, Deployment and Communication
- Orchestration: Docker Swarm (or Kubernetes if scale requires) with services:
  - agent-mcp
  - mcp-proxy
  - mcp-studio
  - canvas-ui
  - storage-service (OTIO manifests in S3/MinIO)
- Messaging: NATS JetStream for event-driven updates; optional alternatives as needed.
- Compute: GPU-enabled workers for render tasks; nvidia-container-runtime configuration on worker nodes.
- Real-time UI: SSE/WebSocket channel for manifest updates; CRDT-based collaboration (Yjs) for multi-user canvas participation.
- Durable Execution: Temporal.io (optional) for long-running tasks, retries, and durable state.
- Security: Zero-Trust for MCP connectors; ACL-based editing; thorough audit trail with timestamps.

8) Model Context Protocol (MCP)
- Tools: standard actions agents can call (e.g., update_manifest, set_state, add_scenography).
- Resources: read/write access to OTIO manifest, assets, and metadata with scoped permissions.
- Prompts: reusable templates mapping to manifest actions; structured prompts guide agent behavior.
- Governance: prompt injection safeguards, auditability, and HITL gating for sensitive operations.

9) Security, Audit, HITL and Governance
- Zero-Trust: authenticated connectors between UI, agents, and execution nodes.
- Field-level permissions: edit permissions tied to project state to avoid conflicts during processing.
- Auditability: immutable logs for every action by agent or user; timestamped events for traceability.
- HITL: explicit human approval required for expensive or high-risk steps (e.g., long renders, final approvals).

10) Examples: OTIO with Timestamps and MCP Messages
- OTIO snippet with timestamps (simplified)
  ```json
  {
    "STUDIO_SCHEMA": "Timeline.1",
    "name": "Storyboard Box 01",
    "metadata": {
      "created_at": "2026-04-07T12:00:00Z",
      "updated_at": "2026-04-07T12:05:10Z",
      "state_changed_at": "2026-04-07T12:05:10Z",
      "manifest_version": "v1.0.3",
      "trace_id": "tracebox-0001"
    },
    "tracks": [
      {
        "STUDIO_SCHEMA": "Track.1",
        "name": "Video",
        "clips": [
          {
            "STUDIO_SCHEMA": "Clip.2",
            "name": "Shot_0001",
            "source_range": {
              "STUDIO_SCHEMA": "TimeRange.1",
              "start_time": {"STUDIO_SCHEMA": "RationalTime.1", "rate": 24.0, "value": 0.0},
              "duration": {"STUDIO_SCHEMA": "RationalTime.1", "rate": 24.0, "value": 96.0}
            },
            "metadata": {
              "scenography": { "user_prompt": "...", "tags": [], "prompt_relay": "..." },
              "workflow_state": { "timing": "LOCKED", "identity_anchor": "LOCKED", "visual_scenography": "EDITABLE" },
              "timestamps": {
                "created_at": "2026-04-07T12:00:00Z",
                "updated_at": "2026-04-07T12:05:00Z"
              }
            }
          }
        ]
      }
    ]
  }
  ```
- MCP message: update manifest with timestamp
  ```json
  {
    "type": "update_manifest",
    "manifest_id": "prj_studio_box_01",
    "changes": {
      "tracks[0].clips[0].metadata.scenography": {
        "user_prompt": "Cadru larg cu cetate la apus, detalii texturale",
        "tags": ["wide_shot","medieval","sunset","texture"],
        "prompt_relay": "epic cinematic wide shot..."
      }
    },
    "actor": "StoryboardAgent",
    "timestamp": "2026-04-07T12:06:15Z"
  }
  ```

11) MVP Implementation Plan (with Timestamps)
- Objective: provide a timestamped, auditable, end-to-end MVP that demonstrates all four architectural layers working with OTIO.
- Milestones:
  - M1 (Week 1): Define OTIO timestamp schema; implement basic OTIO manifest with timestamps in metadata.
  - M2 (Week 2): Implement MCP agent with timestamped edits and a minimal MCP proxy; establish a simple UI canvas to view manifest with timestamps.
  - M3 (Week 3): Implement READY gate and a simple mcp-studio worker that marks render_started_at and render_completed_at (mock render).
  - M4 (Week 4): End-to-end test harness; integrate SSE WebSocket streaming of manifest updates; add audit logging.
  - M5 (Week 5+): Extend to real rendering tasks, Temporal-based workflows, and CRDT-based UI collaboration; add security enhancements.
- Deliverables:
  - OTIO manifests with timestamp fields
  - MCP message schemas with timestamp payloads
  - MVP UI canvas for viewing/editing with timestamp indicators
  - Minimal worker that consumes READY manifests and updates state with timestamps

12) Extensions and Future Architecture
- CRDT-based real-time collaboration (Yjs) for multi-user CT canvas edits with conflict resolution and per-edit timestamps.
- Temporal.io integration for durable, retryable workflows across long-running rendering tasks.
- Event-driven, fully decoupled architecture with NATS JetStream and content-addressable storage (IPFS-like) for scalability.
- USD-based data exchange with Maya/Houdini/Unreal integration for pipeline interoperability.
- Advanced security layers: enhanced zero-trust, RC/ACL policy management, and audit dashboards for compliance.

13) Glossary
- OTIO: OpenTimelineIO, the standard for editing timelines and metadata.
- MCP: Model Context Protocol, agent-to-system orchestration protocol.
- Box: an OTIO manifest in a defined production state.
- Canvas UI: OpenWebUI canvas for timeline visualization and editing.
- 64n alignment: 64-pixel divisibility constraint for render dimensions.
- Timeline.1: OTIO schema version used in this architecture.
- SSE/WebSocket: Real-time push/pull mechanisms for UI synchronization.
- HITL: Human-In-The-Loop for critical decision points.
- Temporal.io: Durable workflow orchestration for long-running tasks.
- CRDT: Conflict-free Replicated Data Types for offline/online collaboration.
- trace_id: unique identifier for a session/workflow.

14) How to Save in a Repo
- Recommended file path: docs/coozila_studio_data_flow.md
- Commands (example):
  - git checkout -b add/coozila-data-flow-md
  - mkdir -p docs
  - cat > docs/coozila_studio_data_flow.md <<'MD'
  [paste the Markdown content here]
  MD
  - git add docs/coozila_studio_data_flow.md
  - git commit -m "DOC: Add Coozila Studio Data Flow v4.2 with timestamped OTIO manifest and MCP workflow"
  - git push origin add/coozila-data-flow-md
- If you maintain a specific changelog, append this entry with a version tag (v4.2).

**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved. Licensed under MIT.**