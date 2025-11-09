# Virginia CHR Client Survey — Evaluation (Oct 2024)

> A lightweight, reproducible public-health evaluation using **SAS/GRAPH automation** to clean, standardize, and report on Virginia’s **Comprehensive Harm Reduction (CHR)** client survey.  
> This public example ships with **synthetic data**, a single example **SAS program**, and a sample **PDF report**—all privacy-safe with **no PHI/PII**.

> **Repository:** https://github.com/isaacbmichael/vdh-chr-evaluation  
> This repository is a neutral demo for portfolio/teaching purposes and is **not an official VDH system**.

---

## ✨ What this public example includes

- `data/synthetic/vdh_chr_survey_synthetic.csv` — **synthetic** dataset that mimics the structure and distributions of the original client survey.  
- `code/sas/vdh_chr_totals.sas` — a single, reproducible SAS program that produces an executive-friendly **vector PDF** with demographics, program reach, and 20 question-by-demographic charts.  
- `reports/vdh_chr_survey_totals.pdf` — sample output generated from the synthetic dataset.

**Why synthetic?** Every figure and statistic in the sample PDF is generated from synthetic data only. No real survey responses or client-confidential information are included.

**Licensing (unchanged):** **MIT** for code and **CC BY 4.0** for reports/documentation.

---

## 📌 Latest highlights · 2025-11-08

- Public example simplified around a single program: `vdh_chr_totals.sas`.  
- Fonts **session-proofed** (SWISSB titles; SWISS body) with `goptions reset=all` to prevent bold/size drift between runs.  
- Clear, one-page cover with provenance, timeframe, and licensing.  
- Macro-controlled styling for consistent axes, legends, titles, and annotation callouts.

---

## 🚀 Quick start

1. **Clone** the repository:

   `git clone https://github.com/isaacbmichael/vdh-chr-evaluation.git`  
   `cd vdh-chr-evaluation`

2. **Open** `code/sas/vdh_chr_totals.sas` in **SAS 9.4** (SAS/GRAPH required; tested on 9.4M7).

3. In the **USER CONFIG** section of the program, set:
   - `IN_CSV_PATH` → path to the synthetic CSV (or your own file with the same schema)  
   - `OUT_PDF_PATH` → where to save the output PDF  
   - optional `REPO_URL` → prints a clickable repo link on the cover page

4. **Run** the entire program. The output will be a crisp, vector PDF at the path you specified.

**Outputs appear under:** `reports/`

---

## 📂 Repository contents

- `code/sas/` — SAS program(s)  
  - `vdh_chr_totals.sas` — program-wide Totals analysis and charts
- `data/synthetic/` — fabricated demo dataset (no PHI/PII)  
  - `vdh_chr_survey_synthetic.csv`
- `reports/` — sample outputs  
  - `vdh_chr_survey_totals.pdf`
- `LICENSE` — MIT license (code)  
- `LICENSE-docs.md` — CC BY 4.0 license (reports & documentation)  
- `README.md` — this file

---

## 🔐 Data & privacy

- The packaged CSV is **synthetic** and matches the expected column names/types used by the program.  
- If you substitute real data, obtain approvals and follow all privacy safeguards. Publishing results from real data may require additional review.

---

## 🛠 Requirements

- **SAS 9.4** with **SAS/GRAPH** and ODS PDF available.

---

## 🎨 Customize it

- **Labels & recodes:** edit the data-step arrays in the program to match your instrument.  
- **Legends/notes:** adjust legend placement via `LEG_*` macros and the annotation box via `NOTE_*`/`ANNO_*`.  
- **Inside counts:** toggle `SHOW_INSIDE_LABELS` (1 = show, 0 = hide).  
- **Cover page:** set `REPO_URL` to print a clickable reference.

---

## ⚠️ Disclaimer

This repository is for educational and demonstration purposes related to public-health analytics. It is **not medical or clinical advice**, and it is **not an official VDH publication**. Results depend on data quality and methods and may not generalize without independent validation. No PHI/PII is included; public artifacts use de-identified or synthetic data. Code and documentation are provided **“as is”** without warranty.

> Additionally, this repository is a **neutral demo** for portfolio/teaching purposes. It is **not affiliated** with VDH beyond the authorized evaluation release.

---

## 📝 License

- **Code:** MIT — see `LICENSE`.  
- **Reports & documentation:** Creative Commons **CC BY 4.0** — see `LICENSE-docs.md`.

---

## 📮 Contact

© 2025 Isaac B. Michael • Email: isaac.b.michael@gmail.com • LinkedIn: https://www.linkedin.com/in/isaacbmichael • GitHub: https://github.com/isaacbmichael
