---
name: research-workflow
description: "Research workflow: paper discovery (arXiv, Semantic Scholar), blog/RSS monitoring, knowledge base management, and ML paper writing pipeline."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Research, arXiv, blogs, knowledge-base, paper-writing, ML, AI]
---

# Research Workflow Suite

Unified skill for the complete research lifecycle: discovery, monitoring, knowledge management, and paper writing.

---

## Section A: Paper Discovery (arXiv + Semantic Scholar)

Search and retrieve academic papers from arXiv via REST API. No API key needed.

**Quick search**:
```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:QUERY&max_results=5&sortBy=submittedDate&sortOrder=descending"
```

**Clean output** (parse XML to readable format):
```bash
# Pipe arXiv XML through Python for clean output
curl -s "URL" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom'}
root = ET.parse(sys.stdin).getroot()
for entry in root.findall('a:entry', ns):
    title = entry.find('a:title', ns).text.strip()
    arxiv_id = entry.find('a:id', ns).text.strip().split('/abs/')[-1]
    print(f'[{arxiv_id}] {title}')
"
```

**Search prefixes**: `all:`, `ti:` (title), `au:` (author), `abs:` (abstract), `cat:` (category)

**Semantic Scholar** (citations, related papers, author profiles):
```bash
# Get paper details + citations
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300?fields=title,authors,citationCount,year,abstract"
# Get recommendations based on a paper
curl -s -X POST "https://api.semanticscholar.org/recommendations/v1/papers/" -H "Content-Type: application/json" -d '{"positivePaperIds": ["arXiv:2402.03300"]}'
```

**Common categories**: `cs.AI`, `cs.CL` (NLP), `cs.CV`, `cs.LG`, `cs.CR`, `stat.ML`

**Helper script**: `scripts/search_arxiv.py` — handles XML parsing, search by keyword/author/category/ID.

**Rate limits**: arXiv ~1 req/3s, Semantic Scholar 1 req/s (100/s with API key).

**ID versioning**: `arxiv.org/abs/1706.03762` = latest version; `arxiv.org/abs/1706.03762v1` = specific immutable version. Preserve version suffix in citations.

---

## Section B: Blog/RSS Monitoring (blogwatcher)

Monitor blogs and RSS/Atom feeds via blogwatcher-cli.

**Use when**: User wants to track blog updates, RSS feeds, or news sources.

**Workflow**: Configure feeds → monitor for updates → summarize new content → deliver to user.

---

## Section C: Knowledge Base Management (llm-wiki)

Build and query an interlinked markdown knowledge base using Karpathy's LLM Wiki concept.

**Use when**: User wants to create, query, or maintain a structured knowledge base with linked entries.

**Workflow**: Create entries with links → query by keyword/topic → follow links for deeper context.

---

## Section D: ML Paper Writing Pipeline

End-to-end pipeline for producing publication-ready ML/AI research papers targeting NeurIPS, ICML, ICLR, ACL, AAAI, and COLM.

**Lifecycle**: Experiment design → execution → monitoring → analysis → paper writing → review → revision → submission.

**This is an iterative loop** — results trigger new experiments, reviews trigger new analysis.

**Key stages**:
1. **Experiment Design**: Define hypothesis, methodology, baselines, metrics
2. **Execution**: Run experiments, log results, monitor progress
3. **Analysis**: Statistical analysis, visualization, interpretation
4. **Writing**: Structure paper (abstract, intro, method, results, discussion, conclusion)
5. **Review**: Internal review, rebuttal preparation
6. **Submission**: Format for target venue, submit

**Dependencies**: semanticscholar, arxiv, habanero, requests, scipy, numpy, matplotlib, SciencePlots

---

## Pitfalls

1. **arXiv XML parsing** — use helper script or Python snippet, not raw XML
2. **Withdrawn papers** — check summary field for "withdrawn" or "retracted" before treating as valid
3. **Citation drift** — always preserve version suffix in arXiv citations
4. **Rate limits** — respect arXiv (3s) and Semantic Scholar (1s) rate limits
5. **Semantic Scholar fields** — use `fields=` parameter to limit response size
6. **Research is iterative** — don't treat the pipeline as linear; results drive new experiments