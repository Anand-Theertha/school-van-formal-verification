# TechRxiv submission package

This folder contains a preprint-ready source file for [TechRxiv](https://www.techrxiv.org/). TechRxiv accepts unpublished technical work in English (engineering, computing, and related fields). It is **not** peer-reviewed; moderators screen for scope, plagiarism, and policy compliance.

## Files to upload

| File | Role |
|------|------|
| `School_Van_Tracking_Preprint.tex` | Source (edit here, then rebuild PDF) |
| `School_Van_Tracking_Preprint.pdf` | **Required for readers** — generate before submit (see below) |

Optional supplementary (same submission or linked in metadata):

- GitHub release **v1.2.0**: https://github.com/Anand-Theertha/school-van-formal-verification  
- Zenodo archive: https://doi.org/10.5281/zenodo.23567441  

Do **not** submit the repository alone; TechRxiv declines stand-alone code/dataset posts without a manuscript.

## Build the PDF (no local LaTeX on this machine)

**Overleaf (recommended)**

1. Create account at https://www.overleaf.com  
2. **New Project → Upload Project** — zip `School_Van_Tracking_Preprint.tex` or upload the file.  
3. Set compiler to **pdfLaTeX**, click **Recompile**.  
4. Download **PDF** and keep the `.tex` for upload.

**Local (if you install TeX Live / MiKTeX)**

```text
pdflatex School_Van_Tracking_Preprint.tex
pdflatex School_Van_Tracking_Preprint.tex
```

Run twice for stable references/citations.

Each uploaded file must be **≤ 10 MB**.

## Suggested metadata (submission form)

Use text consistent with the PDF title and abstract.

| Field | Suggested value |
|-------|-----------------|
| **Title** | School Van Tracking: Ordering Guarantees Under Unreliable Networks |
| **Category** | **Transportation** or **Computing and Processing** (pick the best fit) |
| **Keywords** | formal verification; TLA+; model checking; GPS telemetry; message ordering; mobile networks; school transportation |
| **Description** | One paragraph — copy from the PDF abstract (first ~1500 characters if limited). |
| **License** | **CC BY 4.0** is a common choice for preprints (you retain copyright; others must attribute). |

Add co-authors, funding, and ORCID on the form if applicable. Notify all co-authors before submitting.

## Before you click Submit

- [ ] Affiliation and author list on the PDF match the submission form.  
- [ ] Abstract and keywords match the PDF.  
- [ ] PDF proofread (equations, tables, URLs).  
- [ ] Zenodo/GitHub links in the paper point to the **same** release you cite.  
- [ ] Work is **unpublished** elsewhere as a final version (conference/journal).  
- [ ] You have rights to any non-original material (figures, quoted logs).  

## Screening timeline

TechRxiv typically posts within **four business days** after moderation. You receive email when the submission is received and when it is accepted or declined.

## Policy notes (summary)

- English only.  
- Include a **PDF** alongside source when possible so you can proof the rendered version.  
- Content must be technical research, not opinion-only or commercial marketing.  
- Read current terms: https://www.techrxiv.org/about and https://techrxiv.figshare.com/f/submission-guidelines  

## Relation to repo draft

`School_Van_Tracking-Report-Draft.md` is the working markdown report (draft v0.5). The LaTeX preprint here is the submission-shaped version: introduction with contributions, index terms, formal references, data availability, and appendix log excerpt. After TechRxiv posting, add the TechRxiv DOI/URL to `README.rst` and the Zenodo record if you mint a new artifact version.
