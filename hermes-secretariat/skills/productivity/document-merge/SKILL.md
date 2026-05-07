---
name: document-merge
description: Merge two different authors' documentation for the same project into a unified, coherent document set.
---

Merge two different authors' documentation for the same project into a unified, coherent document set.

## When to Use
- User has two (or more) sets of project documents from different authors covering the same project
- User wants to consolidate into one master document set with specific inclusion/exclusion rules
- Documents differ in structure, depth, and perspective (e.g., product-focused vs engineering-focused)

## Steps

1. **Inventory both document sets**
   - List all files in each directory
   - Get file sizes to understand depth differences
   - Read ALL documents from both sources in full (use `terminal` to `cat` each file, or `read_file`)

2. **Map corresponding content**
   - Identify which documents from source A correspond to source B
   - Note documents that exist in only one source
   - Identify contradictions or differences in the same topic area

3. **Identify merge strategy**
   - Determine which source has the better **framework/structure** (more complete, professional)
   - Determine which source has better **details** in specific areas
   - Note any explicit user instructions (keep X, remove Y, use Z approach)

4. **Execute the merge**
   - Use the better framework's file structure as the base
   - For each document:
     - Start with the framework document's structure
     - Inject missing content from the other source
     - Resolve contradictions (prefer user-specified preference, or the more detailed version)
     - Update revision history with V2.0 noting the merge
   - Remove documents that become redundant after merging
   - Minor adjustments to documents that don't need rewriting (use `patch` for small fixes like removing specific fields or fixing references)

5. **Cross-document consistency check**
   - Ensure no contradictions between documents (e.g., payment methods, timeline, tech stack)
   - Verify all cross-references are consistent
   - Search for any residual references to removed items (`grep` across all files in the target directory)

6. **Summary to user**
   - List which documents were fully rewritten vs minimally changed vs unchanged
   - Highlight key decisions made (what was kept, what was dropped, what was merged)

## Key Principles
- **Preserve structure, enrich content** — don't flatten a well-organized document set
- **Be explicit in revision history** — V2.0 should document what was changed and why
- **Search for residuals** — after removing something (e.g., a platform), grep all files to ensure no lingering references except in revision history
- **Read everything first** — don't skip documents; the best details might be in unexpected places

## Pitfalls
- Don't assume documents with similar names have the same content — they may cover entirely different aspects
- Don't merge blindly — some contradictions are intentional differences in approach; resolve based on user preference
- Watch for cross-document references (e.g., SRS references architecture, plan references SRS) — ensure they stay consistent after merge
