```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Enhanced Question Generation Flow                      │
└─────────────────────────────────────────────────────────────────────────────────┘

    START
      │
      ▼
┌─────────────────┐
│  Step 1: Get    │ ─────► User Wrong Words? ─────► Calculate Priorities
│  Revision Words │              │                  (Time + Count + Random)
└─────────────────┘              │                           │
                                 │                           ▼
                                 └─► Random Words ─────► Probability Selection
                                                             │
                                                             ▼
┌─────────────────┐                                  ┌─────────────────┐
│  Step 2: Fetch  │ ◄──────────────────────────────  │  Single DB Query│
│  Questions      │                                  │  (50 per word)  │
└─────────────────┘                                  └─────────────────┘
      │
      ▼
┌─────────────────┐
│  Step 3: Score  │ ─────► Age Factor (exponential decay)
│  & Classify     │ ─────► Random Factor (variety)
│  Questions      │ ─────► Usage Factor (frequency)
└─────────────────┘ ─────► Sigmoid Classification (good/not good)
      │
      ▼
┌─────────────────┐
│  Step 4: Use    │ ────► Enough Questions? ────► YES ────► RETURN
│  Good Questions │                │
└─────────────────┘                │
                                   NO
                                   │
                                   ▼
┌─────────────────┐          ┌─────────────────┐
│  Step 5: AI     │          │  Parallel Gen:  │
│  Generation     │ ────────►│  • COPY_STROKE  │
└─────────────────┘          │  • LISTENING    │
                             │  • FILL_IN_VOCAB│
                             │  • SENTENCES    │
                             └─────────────────┘
                                   │
                                   ▼
                             ┌─────────────────┐
                             │  Batch Save to  │
                             │  Database       │
                             └─────────────────┘
                                   │
                                   ▼
                             Still Need More? ────► NO ────► RETURN
                                   │
                                   YES
                                   │
                                   ▼
┌─────────────────┐          ┌─────────────────┐
│  Step 6:        │          │  Random Choice: │
│  Fallback       │ ────────►│  • AI Retry     │
│  Strategy       │          │  • Recycle      │
└─────────────────┘          └─────────────────┘
                                   │
                                   ▼
                             ┌─────────────────┐
                             │  Final DB       │
                             │  Fallback       │
                             └─────────────────┘
                                   │
                                   ▼
                                RETURN
```

```mermaid
flowchart TD
    A[Start: generate_questions_for_user] --> B[Step 1: Get Revision Words]
    B --> C{User has wrong words?}
    C -->|Yes| D[Calculate priorities<br/>Time + Wrong Count + Random]
    C -->|No| E[Get random words]
    D --> F[Probability-based selection]
    E --> F
    F --> G[Step 2: Fetch Questions<br/>Single DB query with lateral join]
    
    G --> H[Step 3: Score Questions]
    H --> I[Calculate scores:<br/>Age + Random + Usage + Accuracy]
    I --> J[Classify with sigmoid:<br/>Good vs Not Good]
    
    J --> K[Step 4: Collect Good Questions]
    K --> L{Enough good questions?}
    L -->|Yes| Z[Return final questions]
    L -->|No| M[Step 5: Generate AI Questions]
    
    M --> N[Identify words needing questions]
    N --> O[Parallel AI generation]
    O --> P[COPY_STROKE<br/>Synchronous]
    O --> Q[LISTENING<br/>Asynchronous]
    O --> R[FILL_IN_VOCAB<br/>AI-generated]
    O --> S[FILL_IN_SENTENCE<br/>AI-generated]
    
    P --> T[Batch save to database]
    Q --> T
    R --> T
    S --> T
    
    T --> U{Still need more questions?}
    U -->|No| Z
    U -->|Yes| V[Step 6: Fallback Strategy]
    
    V --> W{Random choice}
    W -->|AI Retry| X[Retry AI generation]
    W -->|Recycle| Y[Use not-good questions]
    X --> AA{Still insufficient?}
    Y --> AA
    AA -->|Yes| BB[Final DB fallback:<br/>Any unflagged questions]
    AA -->|No| Z
    BB --> Z
    
    Z --> CC[Validate and return<br/>questions (limited)]
    
    style A fill:#e1f5fe
    style Z fill:#c8e6c9
    style V fill:#fff3e0
    style BB fill:#ffebee
```