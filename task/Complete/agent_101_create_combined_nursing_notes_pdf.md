# Task Assignment: agent_101

## Agent
agent_101

## Objective
Combine all existing BSc Nursing markdown notes into a single, visually appealing, modern-looking PDF document.

## Scope
Use the 11 markdown files already created under `bsc/notes/exam/` and convert them into one PDF with:
- A clean, modern cover page
- A table of contents
- Consistent typography and spacing
- Section headers for LAG, Short Notes, and Very Short Answer
- A professional color scheme (e.g., blue/white or soft healthcare theme)
- Page numbers
- Footer or header with title

## Source Files
- `bsc/notes/exam/long/profession.md`
- `bsc/notes/exam/long/ethics_committee_bioethics_code.md`
- `bsc/notes/exam/long/ethical_committee.md`
- `bsc/notes/exam/short/code_of_ethics.md`
- `bsc/notes/exam/short/tni.md`
- `bsc/notes/exam/short/professional_values_in_nursing.md`
- `bsc/notes/exam/short/ethical_principles.md`
- `bsc/notes/exam/very_short/nursing_criteria.md`
- `bsc/notes/exam/very_short/values_in_nursing.md`
- `bsc/notes/exam/very_short/ethical_dilemma.md`
- `bsc/notes/exam/very_short/professional_value.md`

## Output
- `bsc/notes/BSc_Nursing_Ethics_Notes_Combined.pdf`

## Suggested Tools
Choose any one of the following that is available in the environment:
- `pandoc` + `wkhtmltopdf`
- Python `markdown` + `pdfkit` or `weasyprint`
- Python `fpdf2` or `reportlab`
- `mdpdf` / `markdown-pdf` npm package
- Any other reliable markdown-to-PDF converter

## Constraints
- Do not modify the original `.md` files (only read them).
- Do not expose or commit any secrets, PATs, or credentials.
- Do not modify unrelated files.
- The final PDF must render cleanly and be readable.
- If external tools are missing, install only what is needed and report it.

## Task Lifecycle Files
- `task/Assigned/agent_101_create_combined_nursing_notes_pdf.md` (this file)
- `task/Working/agent_101_create_combined_nursing_notes_pdf.md` (move here when starting)
- `task/Complete/agent_101_create_combined_nursing_notes_pdf.md` (move here after verification)
- `reports/agent_101_combined_nursing_notes_pdf_report.md` (completion report)

## Expected Output
- A single PDF file at `bsc/notes/BSc_Nursing_Ethics_Notes_Combined.pdf`
- A completion report in `reports/agent_101_combined_nursing_notes_pdf_report.md`
- The task assignment file moved to `task/Complete/`
- All changes committed and pushed to `origin/main`

## Verification Requirements
- PDF file exists and is not empty (size > 0 bytes).
- PDF opens/renders without errors.
- PDF contains all 11 topics in a logical order.
- PDF has a cover page, table of contents, and consistent styling.
- Original markdown files are unchanged.
- Repository remains clean and synchronized.
- Git push succeeds.

## Completion Criteria
- PDF generated and saved to the correct path.
- Completion report submitted.
- Task file moved to `task/Complete/`.
- Commit and push successful.

## Important
This task must be executed by **agent_101**, not by task_manager.

## Assigned By
task_manager

## Timestamp
2026-06-28
