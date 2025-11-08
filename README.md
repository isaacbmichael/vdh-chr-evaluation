# Virginia CHR Client Survey — Evaluation (Oct 2024)

> A lightweight, reproducible public-health evaluation using **SAS automation** to clean, standardize, and report on Virginia’s **Comprehensive Harm Reduction (CHR)** client survey. Includes program-wide **Totals** and stratified **Subgroups** reports, a variable dictionary, and **synthetic demo data**—all published with permission and **no PHI/PII**.

> **Repository:** https://github.com/isaacbmichael/vdh-chr-evaluation  
> This repo is a neutral demo for portfolio/teaching purposes and is **not an official VDH system**.

---

## ✨ Features
- **Automated SAS pipeline** (one-command build) for Totals + Subgroups.  
- **Standardized data model:** harmonized site/region, typed variables, labels, and formats.  
- **Quality checks:** missingness scans, type/label validation, and cross-tab diagnostics.  
- **Reusable outputs:** leadership-ready PDFs and CSV exports.  
- **Synthetic data:** structurally faithful example dataset for safe reuse.  
- **Dual licensing:** **MIT** (code) and **CC BY 4.0** (reports & figures).

### Components
- `code/sas/00_formats.sas` — shared formats and labels.  
- `code/sas/01_totals.sas` — program-wide Totals analysis.  
- `code/sas/02_subgroups.sas` — stratified breakdowns (age, gender, race/ethnicity, site/region).  
- `code/sas/run_all.sas` — top-level orchestrator.

---

## 📌 Latest Highlights · 2025-11-07
- Public release of the **VDH CHR Evaluation** repo (MIT + CC BY 4.0).  
- Added **synthetic demo data** and a variable dictionary for reproducibility.  
- Archived the final **Totals** and **Subgroups** PDFs from the Oct 2024 delivery.

---

## 🚀 Quick Start
No special tooling beyond SAS is required.

    # Clone
    git clone https://github.com/isaacbmichael/vdh-chr-evaluation.git
    cd vdh-chr-evaluation

    /* From SAS: run the full build */
    %include "code/sas/run_all.sas";

**Outputs appear under:**
- `reports/` — PDF reports  
- `data/derived/` — CSV summaries

---

## 📂 Repository Contents
- `code/sas/` — modular SAS programs:
  - `00_formats.sas` — shared formats and labels.
  - `01_totals.sas` — program-wide Totals analysis.
  - `02_subgroups.sas` — subgroup breakdowns.
  - `run_all.sas` — one-command build orchestrator.
- `data/synthetic/` — fabricated demo dataset (no PHI/PII).
- `data/dictionary.csv` — variable names, labels, types, and valid values.
- `reports/` — final PDFs:
  - `VDH_CHR_Survey_Totals_Final.pdf`
  - `VDH_CHR_Survey_Subgroups_Final.pdf`
- `instrument/` — blank client survey (for context).
- `docs/` — optional case study or notes for GitHub Pages.
- `LICENSE` — MIT license for code.
- `LICENSE-docs.md` — CC BY 4.0 license for documentation.
- `README.md` — this file.

---

## 🔗 Live Preview (GitHub Pages, optional)
You can publish a short case study from `docs/`:

1. Go to **Settings → Pages**.  
2. Set **Source** to *Deploy from a branch*.  
3. Choose branch **main** and folder **/docs**, then **Save**.

---

## 🎨 Customize It
- **Data inputs:** replace `data/synthetic/` with your raw extracts; update imports if needed.  
- **Formats & labels:** edit `00_formats.sas` to match your instrument.  
- **Subgroups:** adjust panel/group variables in `02_subgroups.sas`.  
- **Exports:** add/remove ODS destinations (PDF/RTF/CSV) in `01_totals.sas` and `02_subgroups.sas`.

---

## 🧭 Glossary
- **CHR** — Comprehensive Harm Reduction program.  
- **Totals** — program-wide results aggregated across sites.  
- **Subgroups** — comparisons by demographics or site/region.  
- **Synthetic data** — artificial records that mimic structure but not real individuals.

---

## ⚠️ Disclaimer
This project is for educational and demonstration purposes only. It does not constitute financial advice. Past performance is not indicative of future results.

> Additionally, this repository is a **neutral demo** for portfolio/teaching purposes. It is **not affiliated** with VDH beyond the authorized evaluation release. No PHI/PII is included.

---

## 📝 License
- **Code:** MIT — see `LICENSE`.  
- **Reports & documentation:** Creative Commons **CC BY 4.0** — see `LICENSE-docs.md`.

---

## 📮 Contact
© 2025 Isaac B. Michael • [Email](mailto:isaac.b.michael@gmail.com) • [LinkedIn](https://www.linkedin.com/in/isaacbmichael) • [GitHub](https://github.com/isaacbmichael)
