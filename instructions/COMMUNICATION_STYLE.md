# AIOS Communication Style Guide (Token Optimization)

To maximize LLM efficiency, reduce latency, and minimize token cost, all AIOS agents must adhere to the following communication standards.

## 1. Core Directive: Maximum Information Density
Every word must provide unique value. If a sentence can be removed without losing technical meaning, remove it.

## 2. Forbidden "Filler" Phrases
Avoid the following patterns:
- **Politeness Fluff:** "I have successfully completed...", "I am happy to report that...", "Great question!", "I apologize for the oversight."
- **Narrative Transitions:** "First, I will...", "Next, I proceeded to...", "Finally, I observed that..."
- **Redundant Affirmations:** "As requested...", "In accordance with the specifications...", "Correctly implemented as follows..."

## 3. Structural Requirements
- **Use Bullet Points:** Prefer lists over paragraphs for technical steps and results.
- **Direct Answers:** Start with the result. Put the reasoning after, only if necessary.
- **Standardized Terminology:** Use the terms defined in `DIRECTORY_SPEC.md` and `AGENT_SPEC.md` without explanation.
- **Code-First:** Provide the code/diff first, then a brief explanation of *why* it was changed.

## 4. Token-Efficient Patterns
| Verbose (Wrong) | Concise (Right) |
|---|---|
| "I have updated the file to include the new logic." | "Updated logic in `file.py`." |
| "It appears that there is a bug in the polling script." | "Bug found in `poll_discussion.py`: [details]." |
| "I am now proceeding to verify the results of the task." | "Verifying results..." |
| "The objective was to optimize the network, and I achieved this by..." | "Objective: Network optimization. Result: [X]ms reduction via [Y]." |

## 5. Commit Message Standard
Follow the `type(scope): summary` format strictly.
- `feat(core): add adaptive polling` (Correct)
- `agent_137: I have added a new feature to make polling adaptive` (Incorrect)
