/*****************************************************************************************
 * Virginia Department of Health - CHR Survey Analysis
 * Public Example Package (Synthetic Data) - PDF and SAS/GRAPH Output
 *-----------------------------------------------------------------------------------------
 * AUTHOR:    Isaac B. Michael, PhD, MS, MApSt
 * CREATED:   2024-10-20  REVISED:   2025-11-08
 *
 * PURPOSE
 *   This repository contains a reproducible SAS program that mirrors the structure and
 *   analyses used in the Comprehensive Harm Reduction (CHR) program's actual report.
 *   To protect privacy, every figure and statistic in the public PDF is generated from a
 *   SYNTHETIC dataset that mimics realistic distributions. No real survey responses are
 *   included in this package or its outputs.
 *
 * WHAT YOU GET
 *   - One SAS program that renders an executive-friendly PDF with crisp text and graphics.
 *   - Demographic pies, program reach charts, and 20 question-by-demographic bar charts.
 *   - A cover page explaining provenance, timeframe, and licensing.
 *
 * QUICK START (manual paths - recommended)
 *   1) Download ZIP -> Extract All -> open code/vdh_chr_totals.sas in SAS 9.4 (with SAS/GRAPH).
 *   2) In the section "USER CONFIG", set BOTH lines (each on a single line):
 *        %let IN_CSV_PATH=C:\path\to\vdh_chr_survey_synthetic.csv;
 *        %let OUT_PDF_PATH=C:\path\to\reports\vdh_chr_survey_totals.pdf;
 *      Windows backslashes or forward slashes are both OK. Do not add quotes.
 *   3) Run the program. The PDF is written to OUT_PDF_PATH. The "reports" folder will be
 *      created if needed.
 *
 * IF YOU SEE "Input CSV not found"
 *   - Check that IN_CSV_PATH points to an existing CSV.
 *   - Paths with spaces are OK. Avoid % or & in folder names.
 *   - Optional: instead of the two lines above, you may set one root folder:
 *        %let PROJECT_ROOT=%str(C:\Users\you\Downloads\vdh-chr-evaluation-main);
 *     If PROJECT_ROOT is set, the program will derive both paths automatically.
 *
 * DATA NOTES
 *   - The included CSV (or your own) should follow the column schema expected below.
 *   - If you replace the synthetic CSV with real data, ensure approvals and privacy
 *     protections are satisfied. Publishing real results may require review.
 *
 * LICENSING
 *   - Code: MIT License (c) 2025 Isaac B. Michael.
 *   - Reports and Documentation: Creative Commons Attribution 4.0 (CC BY 4.0).
 *   - Please credit "Isaac B. Michael" and include links to both licenses.
 *
 * CONTRIBUTING / ISSUES
 *   - Open an Issue or Pull Request on GitHub. The repository URL is printed on the cover page.
 *
 * TECHNICAL NOTES IN THIS VERSION
 *   - Fonts are session-proofed: titles use SWISSB; all other text uses SWISS (non-bold).
 *     We call: goptions reset=all, ftitle=swissb, ftext=swiss; and set font=swiss on
 *     AXIS/LEGEND/annotate LABELs to prevent bold creep on later runs.
 *   - Vector PDF output for crisp text and lines (device=PDF with ODS PDF).
 *   - Safe arrays: all Q* variables are coerced to character before mapping and labeling.
 *   - Cover page spacing tuned to keep everything on one page.
 *
 * HOW TO CUSTOMIZE
 *   - Change legend placement via LEG_* macros; adjust annotation box via NOTE_* and ANNO_*.
 *   - Set SHOW_INSIDE_LABELS=0 to hide counts inside bars.
 *   - Replace REPO_URL to print a clickable reference on the cover page.
 ******************************************************************************************/

/* ===============================================================================
   USER CONFIG: set BOTH absolute paths below (each on ONE line). These are the only
   manual edits most users need. If you prefer auto-detect, set PROJECT_ROOT instead.
   =============================================================================== */

%let IN_CSV_PATH=; 
%let OUT_PDF_PATH=;

/* ===============================================================================
   PATH RESOLUTION AND PREFLIGHT CHECKS
   - If PROJECT_ROOT is set and both paths are blank, derive defaults.
   - Validate that IN_CSV_PATH exists.
   - Ensure the OUT_PDF_PATH folder exists (create it if possible).
   =============================================================================== */

/* Optional: user can set this; leave blank by default */
%let PROJECT_ROOT=;
%let REPO_URL=;

/* Derive defaults from PROJECT_ROOT only when both are blank */
%macro _derive_from_root;
  %if %superq(PROJECT_ROOT) ne %then %do;
    %if %superq(IN_CSV_PATH)= and %superq(OUT_PDF_PATH)= %then %do;
      %let IN_CSV_PATH=%superq(PROJECT_ROOT)/data/synthetic/vdh_chr_survey_synthetic.csv;
      %let OUT_PDF_PATH=%superq(PROJECT_ROOT)/reports/vdh_chr_survey_totals.pdf;
    %end;
  %end;
%mend;
%_derive_from_root;

/* Pretty error and abort helper */
%macro _die(msg);
  %put ERROR: &msg;
  %abort cancel;
%mend;

/* Require both paths */
%macro _require_paths;
  %if %superq(IN_CSV_PATH)= %then %_die(Set IN_CSV_PATH in USER CONFIG.);
  %if %superq(OUT_PDF_PATH)= %then %_die(Set OUT_PDF_PATH in USER CONFIG.);
%mend;
%_require_paths;

/* Make sure CSV exists */
%macro _require_csv;
  %if not %sysfunc(fileexist(%superq(IN_CSV_PATH))) %then
    %_die(Input CSV not found at IN_CSV_PATH: %superq(IN_CSV_PATH));
%mend;
%_require_csv;

/* Ensure the output directory exists (best-effort mkdir) */
%macro _ensure_dir_from_file(fullpath);
  %local outdir rc did parent leaf mk;
  /* strip filename: keep everything before the last / or \ */
  %let outdir=%sysfunc(prxchange(s/[\/\\][^\/\\]+$//,1,%superq(fullpath)));
  %let rc=%sysfunc(filename(_d,"&outdir"));
  %let did=%sysfunc(dopen(_d));
  %if &did=0 %then %do;
    /* try to create last folder */
    %let parent=%sysfunc(prxchange(s/[\/\\]([^\/\\]+)$//,1,&outdir));
    %let leaf=%sysfunc(prxchange(s/.*[\/\\]([^\/\\]+)$/$1/,1,&outdir));
    %let mk=%sysfunc(dcreate(&leaf,&parent));
    %let rc=%sysfunc(filename(_d,"&outdir"));
    %let did=%sysfunc(dopen(_d));
    %if &did=0 %then %put WARNING: Could not create output folder &outdir.. Create it manually if needed.;
    %else %let rc=%sysfunc(dclose(&did));
  %end;
  %else %let rc=%sysfunc(dclose(&did));
  %let rc=%sysfunc(filename(_d));
%mend;
%_ensure_dir_from_file(&OUT_PDF_PATH);

/* ===============================================================================
   STYLE DEFAULTS - NO USER ACTION NEEDED
   -------------------------------------------------------------------------------
   These settings keep the charts and text consistent with prior reports.
   Most users can ignore this section.
   =============================================================================== */

/* Axis/label style (keep your x-axis angle) */
%let XAXIS_ANGLE   = 330;   /* slight clockwise, reads down left-to-right */
%let XAXIS_H       = 1.0;   /* x-axis tick label size (cell units)        */
%let XAXIS_OFFSET  = 4;     /* reduce overlap warnings                     */

/* Unified text sizing (cell units) - same visual size, crisp */
%let TITLE_H       = 1.75;  /* chart titles (not the cover page)          */
%let LEGEND_H      = 1.2;
%let YTICK_H       = 1.0;
%let YLABEL_H      = 1.2;
%let ANNO_NOTE_H   = 1.0;
%let ANNO_BIG_H    = 2.0;

/* Canvas size - match prior style */
%let HSIZE_IN      = 9;
%let VSIZE_IN      = 6;

/* Inside bar counts? (prior style showed inside FREQ) */
%let SHOW_INSIDE_LABELS = 1;

/* ------- Legend placement (match prior style: bottom-left or bottom-center) ------- */
/* Bars (VBAR3D) */
%let LEG_BAR_POS      = (bottom left);
%let LEG_BAR_OFF_X    = 0;
%let LEG_BAR_OFF_Y    = 0;

/* Pies (PIE3D) - prior style at bottom center, single column */
%let LEG_PIE_POS      = (bottom center);
%let LEG_PIE_OFF_X    = 0;
%let LEG_PIE_OFF_Y    = 0;

/* ------- Percent-high / note box placement ------- */
%let ANNO_BAR_X1      = 4;
%let ANNO_BAR_X2      = 20;
%let ANNO_BAR_YTOP    = 83;
%let ANNO_BAR_YBOT    = 69;
%let ANNO_BAR_TEXT_X  = 12;
%let ANNO_BAR_LINE2_Y = 75;

%let NOTE_X1          = 4;
%let NOTE_X2          = 20;
%let NOTE_YTOP        = 83;
%let NOTE_YBOT        = 69;
%let NOTE_TEXT_X      = 12;

/* ===============================================================================
   PRELIMINARY STATEMENTS (session-proof fonts + vector output)
   =============================================================================== */
%let TIMER_START = %sysfunc(datetime());

dm "log; clear";
dm "odsresults; clear";
options nodate nonumber pageno=1;

ods _all_ close;
options orientation=landscape;
goptions reset=all;
ods pdf file="&OUT_PDF_PATH";

/* SAS/GRAPH device + fonts */
goptions device=pdf
         hsize=&HSIZE_IN.in vsize=&VSIZE_IN.in
         gunit=cell htext=1
         ftitle=swissb ftext=swiss
         cback=white;

%macro bigtitle(text);
  title1 f=swissb h=&TITLE_H "&text";
%mend;

/* ===============================================================================
   DATA IMPORT (CSV)
   =============================================================================== */
proc import datafile="&IN_CSV_PATH"
            out=work.vdh_chr_data1
            dbms=csv replace;
  guessingrows=32767;
  getnames=yes;
run;

/* ===============================================================================
   VARIABLE LABELS + TYPE NORMALIZATION (make ALL Q* character)
   =============================================================================== */
data work.vdh_chr_data1;
  set work.vdh_chr_data1;

  label
    record_id                 = "Record ID"
    residence                 = "What city or county do you live in?"
    age                       = "Age"
    dob_y                     = "What year were you born?"
    program_length            = "How long in program?"
    site_location             = "Sub-grantee Site location/Local Org."
    gender                    = "Gender"
    race_white                = "White, non-Hispanic"
    race_black                = "Black/African American, non-Hispanic"
    ethn_hisp                 = "Hispanic/Latino (all races)"
    race_bi_multi             = "Biracial/Multi-racial"
    race_other                = "Other"
    race_other_spec           = "Other Specific"
    race_bi_multi_spec        = "Race: Biracial/Multi-racial"
    employed_now              = "Employment Now"
    employed_past_year        = "Employed Past Year"
    hear_harm_friend          = "How did you hear about this Harm Reduction program? (Friend)"
    hear_harm_family          = "How did you hear about this Harm Reduction program? (Family member)"
    hear_harm_internet        = "How did you hear about this Harm Reduction program? (Internet)"
    hear_harm_csb             = "How did you hear about this Harm Reduction program? (CSB)"
    hear_harm_faith_org       = "How did you hear about this Harm Reduction program? (Faith-based org)"
    hear_harm_van             = "How did you hear about this Harm Reduction program? (Saw mobile van)"
    hear_harm_other           = "How did you hear about this Harm Reduction program? (Other)"
    hear_health_other         = "How did you hear about this health department/community org?"
    q1_helpful                = "Q1. How helpful has the program been in improving your life?"
    q2_helpful_food           = "Q2. How helpful has the program been in referring you to obtain food?"
    q3_helpful_housing        = "Q3. How helpful has the program been in referring you to obtain housing?"
    q4_helpful_mh             = "Q4. How helpful has the program been in referring you to obtain mental health services?"
    q5_satisfaction_needle    = "Q5. How satisfied are you with the needle (syringe) exchange process?"
    q6_prep_pep               = "Q6. How many times have you been offered info about PrEP/PEP?"
    q7_syphilis_info          = "Q7. How would you rate the info shared about syphilis testing?"
    q8_hep_c_info             = "Q8. How would you rate the info shared about Hepatitis C testing?"
    q9_suicide_info           = "Q9. How would you rate the info shared about suicide prevention?"
    q10_hiv_info              = "Q10. How would you rate the info shared about HIV testing?"
    q11_hiv_tests_taken       = "Q11. How many HIV tests have you taken?"
    q12_narcan_use            = "Q12. How many times have you (or someone) used NARCAN?"
    q13_fentanyl_concern      = "Q13. How concerned are you about taking fentanyl unknowingly?"
    q14_fentanyl_satisfaction = "Q14. How satisfied are you with the fentanyl test strips?"
    q15_xylazine_concern      = "Q15. How concerned are you about taking xylazine unknowingly?"
    q16_xylazine_satisfaction = "Q16. How satisfied are you with the xylazine test strips?"
    q17_harm_satisfaction     = "Q17. How satisfied are you with the harm reduction supplies?"
    q18_van_satisfaction      = "Q18. How satisfied are you with the services provided by the mobile van?"
    q19_treatment_consideration = "Q19. How much have you considered inpatient/outpatient drug treatment?"
    q20_overall_satisfaction  = "Q20. Overall, how satisfied are you with services received?"
    q21_additional_info       = "Q21. Additional info you'd like to share about the program?"
    next_survey               = "Would you like to participate in our next survey?"
    staff_comments            = "Staff Comments"
    complete                  = "Survey complete?"
  ;

  /* Character copies for ALL Q* (safe arrays) */
  length
    q1_helpful_c q2_helpful_food_c q3_helpful_housing_c q4_helpful_mh_c
    q5_satisfaction_needle_c q6_prep_pep_c q7_syphilis_info_c q8_hep_c_info_c
    q9_suicide_info_c q10_hiv_info_c q11_hiv_tests_taken_c q12_narcan_use_c
    q13_fentanyl_concern_c q14_fentanyl_satisfaction_c q15_xylazine_concern_c
    q16_xylazine_satisfaction_c q17_harm_satisfaction_c q18_van_satisfaction_c
    q19_treatment_consideration_c q20_overall_satisfaction_c $12;

  q1_helpful_c                  = strip(vvalue(q1_helpful));
  q2_helpful_food_c             = strip(vvalue(q2_helpful_food));
  q3_helpful_housing_c          = strip(vvalue(q3_helpful_housing));
  q4_helpful_mh_c               = strip(vvalue(q4_helpful_mh));
  q5_satisfaction_needle_c      = strip(vvalue(q5_satisfaction_needle));
  q6_prep_pep_c                 = strip(vvalue(q6_prep_pep));
  q7_syphilis_info_c            = strip(vvalue(q7_syphilis_info));
  q8_hep_c_info_c               = strip(vvalue(q8_hep_c_info));
  q9_suicide_info_c             = strip(vvalue(q9_suicide_info));
  q10_hiv_info_c                = strip(vvalue(q10_hiv_info));
  q11_hiv_tests_taken_c         = strip(vvalue(q11_hiv_tests_taken));
  q12_narcan_use_c              = strip(vvalue(q12_narcan_use));
  q13_fentanyl_concern_c        = strip(vvalue(q13_fentanyl_concern));
  q14_fentanyl_satisfaction_c   = strip(vvalue(q14_fentanyl_satisfaction));
  q15_xylazine_concern_c        = strip(vvalue(q15_xylazine_concern));
  q16_xylazine_satisfaction_c   = strip(vvalue(q16_xylazine_satisfaction));
  q17_harm_satisfaction_c       = strip(vvalue(q17_harm_satisfaction));
  q18_van_satisfaction_c        = strip(vvalue(q18_van_satisfaction));
  q19_treatment_consideration_c = strip(vvalue(q19_treatment_consideration));
  q20_overall_satisfaction_c    = strip(vvalue(q20_overall_satisfaction));

  drop q1_helpful--q20_overall_satisfaction;

  rename
    q1_helpful_c                  = q1_helpful
    q2_helpful_food_c             = q2_helpful_food
    q3_helpful_housing_c          = q3_helpful_housing
    q4_helpful_mh_c               = q4_helpful_mh
    q5_satisfaction_needle_c      = q5_satisfaction_needle
    q6_prep_pep_c                 = q6_prep_pep
    q7_syphilis_info_c            = q7_syphilis_info
    q8_hep_c_info_c               = q8_hep_c_info
    q9_suicide_info_c             = q9_suicide_info
    q10_hiv_info_c                = q10_hiv_info
    q11_hiv_tests_taken_c         = q11_hiv_tests_taken
    q12_narcan_use_c              = q12_narcan_use
    q13_fentanyl_concern_c        = q13_fentanyl_concern
    q14_fentanyl_satisfaction_c   = q14_fentanyl_satisfaction
    q15_xylazine_concern_c        = q15_xylazine_concern
    q16_xylazine_satisfaction_c   = q16_xylazine_satisfaction
    q17_harm_satisfaction_c       = q17_harm_satisfaction
    q18_van_satisfaction_c        = q18_van_satisfaction
    q19_treatment_consideration_c = q19_treatment_consideration
    q20_overall_satisfaction_c    = q20_overall_satisfaction
  ;
run;

/* ===============================================================================
   COVER PAGE (executive-friendly) - airy title/subtitle, fits on one page
   =============================================================================== */
%let today_word = %sysfunc(date(), worddate.);
%let created_on = 01 Dec 2024;  /* display form for cover; keep in sync with header */
%let revised_on = 08 Nov 2025;  /* display form for cover; keep in sync with header */

data title_page;
  length A $360;
  A=" "; output;  /* top padding */
  A=" "; output;

  A="Virginia Department of Health"; output;
  A="Comprehensive Harm Reduction (CHR) Program"; output;

  A=" "; output;  /* space before subtitle */

  A="Survey Analysis - Updated Program for Public Release"; output;

  A=" "; output;  /* generous spacing */
  A="&today_word"; output;

  A=" "; output;

  A="Summary:"; output;
  A="This example mirrors the CHR program's report structure, variable harmonization, and analysis logic for totals and subgroup charts. All results are generated from a fully SYNTHETIC dataset that imitates realistic distributions - no real responses."; output;

  A=" "; output;

  A="Timeframe Covered by the Synthetic Example:"; output;
  A="January 1, 2018 - May 31, 2024 (illustrative)"; output;

  A=" "; output;

  A="How this PDF is organized:"; output;
  A="1) Participant demographics"; output;
  A="2) Program reach (how respondents heard about CHR)"; output;
  A="3) Satisfaction, helpfulness, and concern measures by demographic"; output;

  A=" "; output;

  A="Licensing:"; output;
  A="- Code: MIT License (c) 2025 Isaac B. Michael"; output;
  A="- Reports and Documentation: Creative Commons Attribution 4.0 (CC BY 4.0)"; output;

  A=" "; output;

  A="Attribution and Contact:"; output;
  A="Please credit Isaac B. Michael when reusing and include links to both licenses."; output;

  A=" "; output;

  if not missing(symget('REPO_URL')) then do;
    A="Source and instructions: see GitHub repository (REPO_URL in program header)."; output;
  end;

  A=" "; output;  /* trailing spacer to avoid page break jitter */
run;

options orientation=landscape
        papersize=letter
        leftmargin=0.75in rightmargin=0.75in
        topmargin=0.75in  bottommargin=0.75in;

title; footnote;
ods pdf startpage=no;
proc report data=title_page nowd noheader
  style(report)=[frame=void rules=none cellpadding=6 cellspacing=0 outputwidth=9in];
  columns A;
  define A / display flow
             style(column)=[cellwidth=9in just=l];
  compute A;
    if A="Virginia Department of Health" then
      call define(_col_,"style","style={font_size=20pt font_weight=bold just=center}");
    else if A="Comprehensive Harm Reduction (CHR) Program" then
      call define(_col_,"style","style={font_size=18pt font_weight=bold just=center}");
    else if A="Survey Analysis - Updated Program for Public Release" then
      call define(_col_,"style","style={font_size=15pt just=center}");
    else if A="&today_word" then
      call define(_col_,"style","style={font_size=12pt just=center}");
    else if A in ("Summary:","How this PDF is organized:","Licensing:",
                  "Attribution and Contact:","Timeframe Covered by the Synthetic Example:") then
      call define(_col_,"style","style={font_size=12pt font_weight=bold just=left}");
    else call define(_col_,"style","style={font_size=11pt just=left}");
  endcomp;
run;
ods pdf startpage=yes;

/* ===============================================================================
   DEMOGRAPHICS & BASIC FEATURES
   =============================================================================== */
data work.vdh_chr_data1;
  set work.vdh_chr_data1;
  if age = . then age_group = "Unknown";
  else if 18 <= age <= 34 then age_group = "18-34";
  else if 35 <= age <= 44 then age_group = "35-44";
  else if age >= 45 then age_group = "45+";
run;

proc means data=work.vdh_chr_data1 noprint;
  var age;
  output out=avg_age mean=avg_age;
run;
data _null_;
  set avg_age;
  call symputx('avg_age', round(avg_age,1));
run;

/* ---------- Age pie ---------- */
proc gchart data=work.vdh_chr_data1;
  %bigtitle(Age Distribution (Avg: &avg_age))
  pie3d age_group /
    percent=outside value=inside noheading slice=outside
    radius=25 angle=60 explode=all plabel=none legend=legend1
    ctext=BLACK;
  legend1 label=none
          value=(font=swiss height=&LEGEND_H)
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

/* ---------- Gender pie ---------- */
proc gchart data=work.vdh_chr_data1;
  %bigtitle(Gender Distribution)
  pie3d gender /
    percent=outside value=inside noheading slice=outside
    radius=25 angle=60 explode=all
    ctext=BLACK;
run; quit;

/* Race/Ethnicity short labels */
data work.vdh_chr_data1;
  length race_ethnicity $18;
  set work.vdh_chr_data1;
  if ethn_hisp = 'Yes' then race_ethnicity = "Hispanic";
  else if race_white = 'Yes' then race_ethnicity = "NH-White";
  else if race_black = 'Yes' then race_ethnicity = "NH-Black";
  else if race_bi_multi='Yes' then race_ethnicity = "NH-Bi/Multi-racial";
  else race_ethnicity = "Other/Unknown";
run;

/* ---------- Race/Ethnicity pie ---------- */
proc gchart data=work.vdh_chr_data1;
  %bigtitle(Race/Ethnicity Distribution)
  pie3d race_ethnicity /
    percent=outside slice=outside value=inside descending noheading
    ctext=BLACK other=1 radius=25 angle=60 explode=all legend=legend1;
  legend1 label=none value=(font=swiss height=&LEGEND_H)
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

/* ---------- Employment pies ---------- */
proc gchart data=work.vdh_chr_data1;
  %bigtitle(Employment Status Now)
  pie3d employed_now /
    percent=outside value=inside noheading slice=outside
    radius=25 angle=60 explode=all legend=legend1 name="Now" ctext=BLACK;
  legend1 label=none value=(font=swiss height=&LEGEND_H)
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

proc gchart data=work.vdh_chr_data1;
  %bigtitle(Employment Status in the Past Year)
  pie3d employed_past_year /
    percent=outside value=inside noheading slice=outside
    radius=25 angle=60 explode=all legend=legend1 name="PastYear" ctext=BLACK;
  legend1 label=none value=(font=swiss height=&LEGEND_H)
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

/* Site abbreviations + full labels (legend spells out the expansions) */
data work.vdh_chr_data1;
  length site_location2 $12 site_location_full $100;
  set work.vdh_chr_data1;

  if site_location="(MASS) Minority AIDS Support Services - Newport News, Norfolk, Virginia Beach" then do;
    site_location2="MASS";       site_location_full="(MASS) Newport News, Norfolk, Virginia Beach";
  end;
  else if site_location="Chris Atwood Foundation - Fairfax Co. Prince William Co." then do;
    site_location2="CAF";        site_location_full="(CAF) Fairfax (NoVA)";
  end;
  else if site_location="Council of Community Services - Roanoke" then do;
    site_location2="CCS";        site_location_full="(CCS) Roanoke";
  end;
  else if site_location="Health Brigade - Richmond" then do;
    site_location2="HB";         site_location_full="(HB) Richmond";
  end;
  else if site_location="Lenowisco Health District / Wise Co." then do;
    site_location2="Lenowisco HD"; site_location_full="(Lenowisco HD) Lenowisco/Wise Co.";
  end;
  else if site_location="Mt. Rogers Health District/ Smyth Co." then do;
    site_location2="Mt Rogers HD"; site_location_full="(Mt. Rogers HD) Mt. Rogers/Smyth Co.";
  end;
  else if site_location="Strength In Peers - Harrisonburg, Rockingham Co., Page Co., Shenandoah Co." then do;
    site_location2="SIP";        site_location_full="(SIP) Harrisonburg, Rockingham, Page, Shenandoah Co.";
  end;
  else if site_location="Virginia Harm Reduction Coalition/Roanoke" then do;
    site_location2="VHRC";       site_location_full="(VHRC) Roanoke";
  end;
  else do; site_location2="Unknown"; site_location_full="Unknown"; end;
run;

/* ---------- Site pie ---------- */
proc gchart data=work.vdh_chr_data1;
  %bigtitle(Site Location Distribution)
  pie3d site_location2 /
    percent=outside slice=outside value=inside noheading
    plabel=(height=1.2) radius=23 angle=45 explode=all legend=legend1 ctext=BLACK;
  legend1 label=none
          value=(font=swiss
                 "CAF: Chris Atwood Foundation - Fairfax (NoVA)"
                 "CCS: Council of Community Services - Roanoke"
                 "HB: Health Brigade - Richmond"
                 "Lenowisco HD: Lenowisco Health District - Lenowisco/Wise Co."
                 "MASS: Minority AIDS Support Services - Newport News, Norfolk, Virginia Beach"
                 "Mt. Rogers HD: Mt. Rogers Health District - Mt. Rogers/Smyth Co."
                 "SIP: Strength In Peers - Harrisonburg, Rockingham, Page, Shenandoah Co."
                 "VHRC: Virginia Harm Reduction Coalition - Roanoke")
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

/* Regions */
data work.vdh_chr_data1;
  set work.vdh_chr_data1;
  length regions $15;
  if site_location2 in ("VHRC","CCS","Mt Rogers HD","Lenowisco HD") then regions="Southwest VA";
  else if site_location2 = "HB" then regions="Central VA";
  else if site_location2 = "MASS" then regions="Hampton Rds";
  else if site_location2 in ("SIP","CAF") then regions="NoVA/NW";
  else regions="Unknown";
run;

proc gchart data=work.vdh_chr_data1;
  %bigtitle(Region Distribution)
  pie3d regions /
    percent=outside slice=outside value=inside explode=all
    radius=23 angle=45 noheading legend=legend1 ctext=BLACK;
  legend1 label=none value=(font=swiss height=&LEGEND_H)
          position=&LEG_PIE_POS offset=(&LEG_PIE_OFF_X,&LEG_PIE_OFF_Y) across=1;
run; quit;

/* ===============================================================================
   "How respondents heard about CHR" - overall + by demographic
   =============================================================================== */
data hear_harm_long;
  set work.vdh_chr_data1;
  length method $50 count 8;
  if hear_harm_friend   = 'Yes' then do; method='Friend';          count=1; output; end;
  if hear_harm_family   = 'Yes' then do; method='Family Member';   count=1; output; end;
  if hear_harm_internet = 'Yes' then do; method='Internet';        count=1; output; end;
  if hear_harm_csb      = 'Yes' then do; method='CSB';             count=1; output; end;
  if hear_harm_faith_org= 'Yes' then do; method='Faith-based Org'; count=1; output; end;
  if hear_harm_van      = 'Yes' then do; method='Mobile Van';      count=1; output; end;
  if hear_harm_other    = 'Yes' then do; method='Other';           count=1; output; end;
run;

/* helper: include INSIDE=FREQ only when toggled */
%macro _inside_freq; %if &SHOW_INSIDE_LABELS %then inside=freq; %mend;

/* Small note box - lock font to SWISS so it never inherits bold */
%macro _note_box(dsname);
  data &dsname;
    length function $8 text $96 style $12; retain xsys ysys '3';
    style='SWISS';
    x=&NOTE_X1;  y=&NOTE_YTOP;  function='MOVE';  output;
    x=&NOTE_X2;                 function='DRAW'; size=0.1; color='BLACK'; output;
                 y=&NOTE_YBOT;  function='DRAW';                         output;
    x=&NOTE_X1;                 function='DRAW';                         output;
                 y=&NOTE_YTOP;  function='DRAW';                         output;

    x=&NOTE_TEXT_X; y=&NOTE_YTOP-2; function='LABEL'; text="NOTE: Respondents"; size=&ANNO_NOTE_H; color='BLACK'; output;
                    y=&NOTE_YTOP-5; function='LABEL'; text="could select one"; size=&ANNO_NOTE_H; color='BLACK'; output;
                    y=&NOTE_YTOP-8; function='LABEL'; text="or more choices."; size=&ANNO_NOTE_H; color='BLACK'; output;
  run;
%mend;

/* Common axes with explicit normal fonts */
axis1 label=(font=swiss height=&YLABEL_H "Percent")
      order=(0 to 100 by 10)
      value=(font=swiss height=&YTICK_H "0%" "10%" "20%" "30%" "40%" "50%" "60%" "70%" "80%" "90%" "100%");

%macro heard_chart_overall;
  %_note_box(anno_label)
  axis2 label=none value=(font=swiss angle=&XAXIS_ANGLE height=&XAXIS_H)
        offset=(&XAXIS_OFFSET,&XAXIS_OFFSET);

  proc gchart data=hear_harm_long;
    %bigtitle(How Respondents Heard About the CHR Program)
    vbar3d method /
      type=pct discrete
      outside=percent %_inside_freq
      width=6 space=3 coutline=black
      raxis=axis1 maxis=axis2
      annotate=anno_label
      ctext=BLACK;
  run; quit;
%mend;

%macro heard_chart(demographic, demo_label);
  %_note_box(anno_label)
  axis2 label=none value=(font=swiss angle=&XAXIS_ANGLE height=&XAXIS_H)
        offset=(&XAXIS_OFFSET,&XAXIS_OFFSET);

  proc gchart data=hear_harm_long;
    %bigtitle(How Respondents Heard About the CHR Program)
    vbar3d method /
      type=pct discrete
      outside=percent %_inside_freq
      width=6 space=3 coutline=black
      legend=legend1 subgroup=&demographic
      raxis=axis1 maxis=axis2
      annotate=anno_label
      ctext=BLACK;
    legend1 label=(font=swiss "&demo_label")
            value=(font=swiss height=1)
            position=&LEG_BAR_POS offset=(&LEG_BAR_OFF_X,&LEG_BAR_OFF_Y) across=1;
  run; quit;
%mend;

/* Render */
%heard_chart_overall;
%heard_chart(race_ethnicity, Race/Ethnicity);
%heard_chart(gender,          Gender);
%heard_chart(age_group,       Age);

/* ===============================================================================
   LABEL MAPPINGS FOR QUESTIONS (all Q* are character now - safe arrays)
   =============================================================================== */
data work.vdh_chr_data1;
  set work.vdh_chr_data1;

  array helpfulness{8}        $ q1_helpful q2_helpful_food q3_helpful_housing q4_helpful_mh
                                q7_syphilis_info q8_hep_c_info q9_suicide_info q10_hiv_info;
  array helpfulness_labels{8} $40 q1_label q2_label q3_label q4_label q7_label q8_label q9_label q10_label;

  do _i_=1 to 8;
    select (helpfulness{_i_});
      when ('1') helpfulness_labels{_i_} = "1. Not helpful";
      when ('2') helpfulness_labels{_i_} = "2. Slightly helpful";
      when ('3') helpfulness_labels{_i_} = "3. Helpful";
      when ('4') helpfulness_labels{_i_} = "4. Very helpful";
      when ('5') helpfulness_labels{_i_} = "5. Extremely helpful";
      otherwise  helpfulness_labels{_i_} = "NA/Skip";
    end;
  end;

  array satisfaction{6}        $ q5_satisfaction_needle q14_fentanyl_satisfaction q16_xylazine_satisfaction
                                 q17_harm_satisfaction q18_van_satisfaction q20_overall_satisfaction;
  array satisfaction_labels{6} $40 q5_label q14_label q16_label q17_label q18_label q20_label;

  do _i_=1 to 6;
    select (satisfaction{_i_});
      when ('1') satisfaction_labels{_i_} = "1. Very dissatisfied";
      when ('2') satisfaction_labels{_i_} = "2. Slightly dissatisfied";
      when ('3') satisfaction_labels{_i_} = "3. Satisfied";
      when ('4') satisfaction_labels{_i_} = "4. Very satisfied";
      when ('5') satisfaction_labels{_i_} = "5. Extremely satisfied";
      otherwise  satisfaction_labels{_i_} = "NA/Skip";
    end;
  end;

  array concerned{2}        $ q13_fentanyl_concern q15_xylazine_concern;
  array concerned_labels{2} $40 q13_label q15_label;

  do _i_=1 to 2;
    select (concerned{_i_});
      when ('1') concerned_labels{_i_} = "1. Not at all concerned";
      when ('2') concerned_labels{_i_} = "2. Slightly concerned";
      when ('3') concerned_labels{_i_} = "3. Concerned";
      when ('4') concerned_labels{_i_} = "4. Very concerned";
      when ('5') concerned_labels{_i_} = "5. Extremely concerned";
      otherwise  concerned_labels{_i_} = "NA/Skip";
    end;
  end;

  length q19_label $20 q6_label q11_label q12_label $10;
  select (q19_treatment_consideration);
    when ('1') q19_label = "1. Not at all";
    when ('2') q19_label = "2. Slightly";
    when ('3') q19_label = "3. Moderately";
    when ('4') q19_label = "4. Quite a bit";
    when ('5') q19_label = "5. To a great extent";
    otherwise   q19_label = "NA/Skip";
  end;

  select (q6_prep_pep);
    when ('0','1','2','3','4','4+','5','5+') q6_label  = q6_prep_pep;
    otherwise                                 q6_label  = "NA/Skip";
  end;
  select (q11_hiv_tests_taken);
    when ('0','1','2','3','4','4+','5','5+') q11_label = q11_hiv_tests_taken;
    otherwise                                 q11_label = "NA/Skip";
  end;
  select (q12_narcan_use);
    when ('0','1','2','3','4','4+','5','5+') q12_label = q12_narcan_use;
    otherwise                                 q12_label = "NA/Skip";
  end;
run;

/* ===============================================================================
   PERCENT-HIGH CALCULATIONS
   =============================================================================== */
%macro percent_high_one(code_var, id, rule);
  %local _tot _hi;

  proc freq data=work.vdh_chr_data1 noprint;
    tables &code_var / out=freq_&id;
  run;

  data _null_;
    set freq_&id end=last;
    retain total_count 0 high_count 0;
    total_count + count;

    %if %upcase(&rule) = COUNT %then %do;
      if &code_var in ('1','2','3','4','4+','5','5+') then high_count + count;
    %end;
    %else %if %upcase(&rule) = LIKERT4 %then %do;
      if &code_var in ('4','5') then high_count + count;
    %end;
    %else %do; /* LIKERT (default = 3 or higher) */
      if &code_var in ('3','4','5') then high_count + count;
    %end;

    if last then do;
      call symputx("total_count_&id", total_count, 'g');
      call symputx("high_count_&id",  high_count,  'g');
    end;
  run;

  %let _tot = &&total_count_&id;
  %let _hi  = &&high_count_&id;

  %global percent_high&id;  /* ensure visibility to callers */

  %if &_tot > 0 %then
    %let percent_high&id = %sysfunc(round(%sysevalf((&_hi / &_tot) * 100), 0.1));
  %else
    %let percent_high&id = 0;
%mend;

/* ===============================================================================
   BAR CHARTS FOR ALL 20 QUESTIONS - OVERALL + BY DEMOGRAPHIC
   =============================================================================== */
axis1 label=(font=swiss height=&YLABEL_H "Percent")
      order=(0 to 100 by 10)
      value=(font=swiss height=&YTICK_H "0%" "10%" "20%" "30%" "40%" "50%" "60%" "70%" "80%" "90%" "100%");

%macro one_question(code_var, label_var, longlabel, rule, id);

  %percent_high_one(&code_var, &id, &rule)

  /* x-axis labels (keep angle; lock font) */
  axis2 label=none value=(font=swiss angle=&XAXIS_ANGLE height=&XAXIS_H)
        offset=(&XAXIS_OFFSET,&XAXIS_OFFSET);

  /* Percent-high annotation (lock font via STYLE var) */
  data anno_label;
    length function $8 text $64 style $12; retain xsys ysys '3';
    style='SWISS';
    x=&ANNO_BAR_X1;  y=&ANNO_BAR_YTOP;  function='MOVE';  output;
    x=&ANNO_BAR_X2;                     function='DRAW'; size=0.1; color='BLACK'; output;
                       y=&ANNO_BAR_YBOT; function='DRAW';                         output;
    x=&ANNO_BAR_X1;                     function='DRAW';                         output;
                       y=&ANNO_BAR_YTOP; function='DRAW';                         output;

    x=&ANNO_BAR_TEXT_X; y=&ANNO_BAR_YTOP-2; function='LABEL';
    %if %upcase(&rule) = COUNT   %then %do; text="Selected 1 or Higher:"; %end;
    %else %if %upcase(&rule)=LIKERT4 %then %do; text="Selected 4 or Higher:"; %end;
    %else                                %do; text="Selected 3 or Higher:"; %end;
    size=&ANNO_NOTE_H; color='BLACK'; output;

    y=&ANNO_BAR_LINE2_Y; function='LABEL'; text="&&percent_high&id.%"; size=&ANNO_BIG_H; color='BLACK'; output;
  run;

  /* ---------- (1) OVERALL ---------- */
  proc gchart data=work.vdh_chr_data1;
    %bigtitle(&longlabel)
    vbar3d &label_var /
      type=pct discrete width=6 space=3
      raxis=axis1 maxis=axis2
      outside=percent %_inside_freq
      coutline=black
      ctext=BLACK
      annotate=anno_label;
  run; quit;

  /* ---------- (2) By-demographic ---------- */
  %macro bydemo(demo, demo_label);
    legend1 label=(font=swiss "&demo_label")
            value=(font=swiss height=1)
            position=&LEG_BAR_POS offset=(&LEG_BAR_OFF_X,&LEG_BAR_OFF_Y) across=1;
    proc gchart data=work.vdh_chr_data1;
      %bigtitle(&longlabel)
      vbar3d &label_var /
        type=pct discrete width=6 space=3
        raxis=axis1 maxis=axis2
        outside=percent %_inside_freq
        coutline=black
        ctext=BLACK
        legend=legend1
        subgroup=&demo
        annotate=anno_label;
    run; quit;
  %mend bydemo;

  %bydemo(race_ethnicity, Race/Ethnicity);
  %bydemo(gender,          Gender);
  %bydemo(age_group,       Age);

%mend;

/* ---- 20 calls (IDs 1..20) ---- */
%one_question(q1_helpful,                 q1_label,  How helpful has the program been in improving your life?,                                   LIKERT,  1);
%one_question(q2_helpful_food,            q2_label,  How helpful has the program been in referring you to obtain food?,                         LIKERT,  2);
%one_question(q3_helpful_housing,         q3_label,  How helpful has the program been in referring you to obtain housing?,                      LIKERT,  3);
%one_question(q4_helpful_mh,              q4_label,  How helpful has the program been in referring you to obtain mental health services?,       LIKERT,  4);
%one_question(q5_satisfaction_needle,     q5_label,  How satisfied are you with the needle (syringe) exchange process?,                         LIKERT,  5);
%one_question(q6_prep_pep,                q6_label,  How many times have you been offered info about PrEP/PEP?,                                 COUNT,   6);
%one_question(q7_syphilis_info,           q7_label,  How would you rate the info shared about syphilis testing?,                                LIKERT,  7);
%one_question(q8_hep_c_info,              q8_label,  How would you rate the info shared about Hepatitis C testing?,                             LIKERT,  8);
%one_question(q9_suicide_info,            q9_label,  How would you rate the info shared about suicide prevention?,                              LIKERT,  9);
%one_question(q10_hiv_info,               q10_label, How would you rate the info shared about HIV testing?,                                     LIKERT, 10);
%one_question(q11_hiv_tests_taken,        q11_label, How many HIV tests have you taken?,                                                        COUNT,  11);
%one_question(q12_narcan_use,             q12_label, How many times have you (or someone) used NARCAN?,                                         COUNT,  12);
%one_question(q13_fentanyl_concern,       q13_label, How concerned are you about taking fentanyl unknowingly?,                                  LIKERT, 13);
%one_question(q14_fentanyl_satisfaction,  q14_label, How satisfied are you with the fentanyl test strips?,                                      LIKERT, 14);
%one_question(q15_xylazine_concern,       q15_label, How concerned are you about taking xylazine unknowingly?,                                  LIKERT, 15);
%one_question(q16_xylazine_satisfaction,  q16_label, How satisfied are you with the xylazine test strips?,                                      LIKERT, 16);
%one_question(q17_harm_satisfaction,      q17_label, How satisfied are you with the harm reduction supplies?,                                   LIKERT, 17);
%one_question(q18_van_satisfaction,       q18_label, How satisfied are you with the services provided by the mobile van?,                       LIKERT, 18);
%one_question(q19_treatment_consideration, q19_label, How much have you considered inpatient/outpatient drug treatment?,                         LIKERT, 19);
%one_question(q20_overall_satisfaction,   q20_label, %str(Overall, how satisfied are you with services received?),                               LIKERT, 20);

/* ===============================================================================
   CLOSE OUT
   =============================================================================== */
ods pdf close;

data _null_;
  dur = datetime() - &TIMER_START;
  put 30*'-' / ' Total DURATION:' dur time13.2 / 30*'-';
run;

/* END OF SAS PROGRAM */
