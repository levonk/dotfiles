---
synopsis: "AI Plugin Guidence: Given an objective that will be repeated, create and identify the best plugin to create for the AI IDE"
---

## Final Constrained AI Feature Recommendation Engine

This engine diagnoses a specific automation request against your predefined list of patterns and their known constraints (context pollution, execution mode, parallelism, etc.).

### Step 1: Task Definition & Memory Check (The Constraint Check)

**AI Action:**

1. **Check Memory:** Query for any **previously established IDE/Tool constraints** (i.e., which of these 8 patterns are actually supported/available to you).
2. **If Memory Found:** Proceed to **Step 3**, using the supported list as a filter for the final ranking.
3. **If Memory NOT Found:** Execute **Step 2**.

---

### Step 2: Requirement Elicitation (The Constraint Gathering)

**AI Action:** Present the user with a structured query to define the core needs that will map to your pattern constraints.

**AI Prompt to User:**
> "I need to select the best architectural pattern for your request: **[Process the user's input/request here]**."
>
> To diagnose the fit, please clarify the following:
>
> 1. **Trigger/Execution Mode:** How should this new feature be activated?
    ***A. User-Initiated/On-Demand:** Explicitly called by the user via a command/prompt.
    *   **B. Autonomous/Reactive:** Should run automatically based on code state or in the background.
    *   **C. Internal Dependency:** Only meant to be called by a larger Workflow or Agent.
> 2. **Context Handling:** How much context pollution is acceptable?
    ***A. Minimal/Isolated:** Must not affect the main context window (e.g., for a quick, self-contained task).
    *   **B. Acceptable Context Pollutant:** Can temporarily add context that is discarded shortly after execution.
    *   **C. Always Active/Polluting:** Must remain active and influencing the context constantly.
> 3. **Primary Goal:** What is the *main* advantage needed?
    ***A. Parallel Speed:** Need for concurrent work to speed up a larger process.
    *   **B. External Data Access:** Need to reliably connect to an external API or tool.
    *   **C. Output Formatting:** Need to enforce a specific structure or style on the output.

---

### Step 3: Pattern Diagnosis, Prioritization, and Artifact Generation

**AI Action:** Map the user's inputs (A/B/C from Step 2) against your predefined constraints to determine the best fit, then rank the options.

**AI Output Format:**

> **Request to Implement:** "**[User's Specific Request]**"
>
> **Diagnosis Summary:** Based on your inputs, the request requires **[e.g., User-Initiated Trigger, Minimal Context, External Data Access]**.
>
> ---
>
> ### Prioritized Implementation Strategy
>
> Below is the ranked list based on how well each pattern fits your defined needs and constraints.
>
> | Rank | Pattern | Fit Score / Constraint Check | Rationale (Why it ranks here) | Initial Artifact Suggestion |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Skill** | **Best Fit.** Satisfies **External Data Access (3B)** and **Minimal Context (2A)**. Outranks MCP because it's a more direct implementation pattern. | I can create the initial **Skill Definition** that encapsulates the external call. |
| **2** | **MCP** | **Strong Second.** If the IDE environment *requires* MCP to expose external tools, this becomes Rank 1. Here it is Rank 2 because it's an integration layer, not the final execution pattern. | I can generate the **MCP Tool Definition** payload for the external connection. |
| **3** | **Sub Agent** | **Good Fit for Speed.** Excellent if this task will be part of a larger process where **Parallel Speed (3A)** is critical, as it runs in its own context. | I can draft the **Sub-Agent Initialization Script** defining its isolated context. |
| **4** | **Workflow** | **Viable Workaround.** Good if you want to run it *occasionally* (**Trigger 1A**) without polluting the main context (**2A**), but it cannot integrate externally *directly*. | I can create a basic **Workflow Blueprint** that calls the Skill/MCP created above as its first step. |
| **5** | **Rule** | **Poor Fit.** Rules are **Always Active (Constraint 2C)** and **Pollute Context (Constraint 2C)**, which conflicts with the low-context requirement. | Not recommended for this on-demand task. |
| **6** | **Hook** | **Incorrect Trigger.** Hooks are for **Reactive (1B)** events based on file globs, not for on-demand commands. | Not applicable. |
| **7** | **Template/Example** | **Support Role.** These are not implementation patterns but *aids* for the other patterns (e.g., used *inside* a Workflow to structure output). | Can provide an example of the desired output format for the Rank 1 Skill. |
| **8** | **Non AI program** | Outside of IDE, best to make a shell script or program, or even full API/web/mobile app ... | ... |
| **9** | **Standard IDE Extension** | A standard IDE plugin for developer ux integration| ... |
| **10** | **Stand alone agent** | Outside of IDE, best to make a shell script or program, or even full API/web/mobile app ... | ... |
>
> ---
> **Final Recommendation:**
>
> **The best approach is to implement this as a $\text{Rank 1: Skill}$.** This isolates context, allows external integration, and is better than a polluting Rule.
>
> **Next Step:** Would you like me to generate the initial code/definition for the **Skill**?
