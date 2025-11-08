/* SPDX-License-Identifier: MIT
--------------------------------------------------------------------------------
VDH CHR — Program Totals (01_totals.sas)

Author: Isaac B. Michael
Created: 2024-10-20  (cleaned for public release)
Description:
  Generates the “Program Totals” PDF and a few derived summary CSVs for the
  Virginia CHR client survey.

How this module is called:
  - Assumes run_all.sas defined the following macro vars:
      &ROOT        -> repository root (path prefix for all outputs)
      &DATA_SOURCE -> SYNTHETIC | REAL
      &INFILE      -> input file (CSV for synthetic, XLSX for real)
      &OUT_TOT     -> PDF path for Totals report (under reports/)
      &OUT_DER     -> folder for derived CSVs (under data/derived/)
--------------------------------------------------------------------------------*/

/* ---------- Session options (portable) ---------- */
options
  mprint nomlogic nosymbolgen /* quiet by default; flip on if debugging   */
  validvarname=v7             /* V7-style names after IMPORT              */
  nodate nonumber             /* cleaner PDF pages                        */
  orientation=landscape;

ods noproctitle;
ods graphics on;

/* ---------- Import data ---------- */
/* Keep this self-contained so the file can be run standalone if needed. */
%macro _import_chr_data;
  %if %upcase(&DATA_SOURCE)=SYNTHETIC %then %do;
    proc import datafile="&INFILE"
      out=work.vdh_chr_data dbms=csv replace;
      guessingrows=max;
    run;
  %end;
  %else %do;
    proc import datafile="&INFILE"
      out=work.vdh_chr_data dbms=xlsx replace;
      getnames=yes;
    run;
  %end;
%mend _import_chr_data;

%_import_chr_data;

/* ---------- Variable labels (safe, no PHI/PII) ---------- */
data work.vdh_chr_data;
  set work.vdh_chr_data;
  label
    record_id                 = "Record ID"
    residence                 = "What city or county do you live in?"
    age                       = "Age"
    dob_y                     = "What year were you born?"
    program_length            = "How long in program?"
    site_location             = "Sub-grantee Site location/Local Org."
    gender                    = "Gender"
    gen_id                    = "Gender: self-identify"
    race_white                = "White, non-Hispanic"
    race_black                = "Black/African American, non-Hispanic"
    ethn_hisp                 = "Hispanic/Latino (all races)"
    race_bi_multi             = "Biracial/Multi-racial"
    race_other                = "Other"
    race_other_spec           = "Other Specific"
    race_bi_multi_spec        = "Race: Biracial/Multi-racial"
    employed_now              = "Employment Now"
    employed_past_year        = "Employed Past Year"
    hear_harm_friend          = "Heard about program: Friend"
    hear_harm_family          = "Heard about program: Family"
    hear_harm_internet        = "Heard about program: Internet"
    hear_harm_csb             = "Heard about program: CSB"
    hear_harm_faith_org       = "Heard about program: Faith-based org"
    hear_harm_van             = "Heard about program: Saw mobile van"
    hear_harm_other           = "Heard about program: Other"
    hear_health_other         = "Heard about Health Dept/Community org"
    q1_helpful                = "Q1. Program helpfulness (overall life)"
    q2_helpful_food           = "Q2. Referral helpfulness: Food"
    q3_helpful_housing        = "Q3. Referral helpfulness: Housing"
    q4_helpful_mh             = "Q4. Referral helpfulness: Mental Health"
    q5_satisfaction_needle    = "Q5. Needle/syringe exchange satisfaction"
    q6_prep_pep               = "Q6. Offered info about PrEP/PEP (count)"
    q7_syphilis_info          = "Q7. Info quality: Syphilis testing"
    q8_hep_c_info             = "Q8. Info quality: Hepatitis C testing"
    q9_suicide_info           = "Q9. Info quality: Suicide prevention"
    q10_hiv_info              = "Q10. Info quality: HIV testing"
    q11_hiv_tests_taken       = "Q11. HIV tests taken (count)"
    q12_narcan_use            = "Q12. NARCAN use (count)"
    q13_fentanyl_concern      = "Q13. Concern: Fentanyl unknowingly"
    q14_fentanyl_satisfaction = "Q14. Satisfaction: Fentanyl test strips"
    q15_xylazine_concern      = "Q15. Concern: Xylazine unknowingly"
    q16_xylazine_satisfaction = "Q16. Satisfaction: Xylazine test strips"
    q17_harm_satisfaction     = "Q17. Satisfaction: Harm reduction supplies"
    q18_van_satisfaction      = "Q18. Satisfaction: Mobile van services"
    q19_treatment_consideration = "Q19. Consider inpatient/outpatient treatment"
    q20_overall_satisfaction  = "Q20. Overall satisfaction"
    next_survey               = "Willing to participate in next survey?"
    staff_comments            = "Staff Comments"
    complete                  = "Survey complete?"
  ;
run;

/* ---------- Light grooming / canonical categories ---------- */
data work.vdh_chr_data;
  set work.vdh_chr_data;

  /* Age groups */
  length age_group $8;
  if missing(age) then age_group="Unknown";
  else if 18 <= age <= 34 then age_group="18-34";
  else if 35 <= age <= 44 then age_group="35-44";
  else if age >= 45 then age_group="45+";
  else age_group="Unknown";

  /* Race/ethnicity (short labels) */
  length race_ethnicity $18;
  if upcase(coalescec(ethn_hisp,''))='YES' then race_ethnicity="Hispanic";
  else if upcase(coalescec(race_white,''))='YES' then race_ethnicity="NH-White";
  else if upcase(coalescec(race_black,''))='YES' then race_ethnicity="NH-Black";
  else if upcase(coalescec(race_bi_multi,''))='YES' then race_ethnicity="NH-Bi/Multi";
  else race_ethnicity="Other/Unknown";

  /* Site abbreviations (kept compact for legend) */
  length site_location2 $12 site_location_full $100;
  select (strip(site_location));
    when("(MASS) Minority AIDS Support Services - Newport News, Norfolk, Virginia Beach")
      do; site_location2="MASS"; site_location_full="(MASS) Newport News / Norfolk / VA Beach"; end;
    when("Chris Atwood Foundation - Fairfax Co. Prince William Co.")
      do; site_location2="CAF";  site_location_full="(CAF) Fairfax (NoVA)"; end;
    when("Council of Community Services - Roanoke")
      do; site_location2="CCS";  site_location_full="(CCS) Roanoke"; end;
    when("Health Brigade - Richmond")
      do; site_location2="HB";   site_location_full="(HB) Richmond"; end;
    when("Lenowisco Health District / Wise Co.")
      do; site_location2="Lenowisco"; site_location_full="(Lenowisco HD) Wise Co."; end;
    when("Mt. Rogers Health District/ Smyth Co.")
      do; site_location2="MtRogers";  site_location_full="(Mt. Rogers HD) Smyth Co."; end;
    when("Strength In Peers - Harrisonburg, Rockingham Co., Page Co., Shenandoah Co.")
      do; site_location2="SIP";  site_location_full="(SIP) Harrisonburg / Rockingham / Page / Shenandoah"; end;
    when("Virginia Harm Reduction Coalition/Roanoke")
      do; site_location2="VHRC"; site_location_full="(VHRC) Roanoke"; end;
    otherwise do; site_location2="Unknown"; site_location_full="Unknown"; end;
  end;

  /* Regions derived from sites */
  length region $12;
  if site_location2 in ("VHRC","CCS","MtRogers","Lenowisco") then region="Southwest";
  else if site_location2="HB" then region="Central";
  else if site_location2="MASS" then region="HamptonRds";
  else if site_location2 in ("SIP","CAF") then region="NoVA/NW";
  else region="Unknown";
run;

/* ---------- Open PDF ---------- */
ods pdf file="&OUT_TOT" dpi=300 notoc;

/* Cover page (brief) */
title1 height=18pt "Virginia Department of Health";
title2 height=16pt "Comprehensive Harm Reduction (CHR)";
title3 height=14pt "Client Survey — Program Totals";
title4 height=12pt "Automated report (public demo)";
proc odstext;
  p "This document summarizes high-level totals from the CHR client survey. It is generated from a synthetic dataset when running this repository publicly.";
  p "No PHI/PII is included. All counts/percentages may be illustrative when using synthetic data.";
run;
title;

/* ---------- Descriptive stats ---------- */
title "Respondent Counts by Key Dimensions";
proc freq data=work.vdh_chr_data nlevels;
  tables gender age_group race_ethnicity region site_location2 / missing;
run;
title;

title "Employment (Current / Past Year)";
proc freq data=work.vdh_chr_data;
  tables employed_now employed_past_year / missing;
run;
title;

title "How respondents heard about the program (multi-select)";
/* Expand the multi-select checkboxes into long form */
data work.hear_harm_long;
  set work.vdh_chr_data(keep=record_id hear_harm_:);
  length method $30;
  array src[7] $ hear_harm_friend hear_harm_family hear_harm_internet
                    hear_harm_csb hear_harm_faith_org hear_harm_van hear_harm_other;
  array lbl[7] $30 _temporary_ ('Friend','Family Member','Internet','CSB',
                                'Faith-based Org','Mobile Van','Other');
  do i=1 to dim(src);
    if upcase(coalescec(src[i],''))='YES' then do;
      method=lbl[i]; output;
    end;
  end;
  drop i;
run;

proc freq data=work.hear_harm_long order=freq;
  tables method / missing;
run;
title;

/* ---------- Satisfaction / helpfulness (collapsed) ---------- */
/* Build labeled copies with consistent buckets */
data work.ratings;
  set work.vdh_chr_data;
  array help_q[8]  $ q1_helpful q2_helpful_food q3_helpful_housing q4_helpful_mh
                        q7_syphilis_info q8_hep_c_info q9_suicide_info q10_hiv_info;
  array sat_q[6]   $ q5_satisfaction_needle q14_fentanyl_satisfaction q16_xylazine_satisfaction
                        q17_harm_satisfaction q18_van_satisfaction q20_overall_satisfaction;

  /* helper: convert to ordered categories 1–5 or 'NA/Skip' */
  length _resp $18;
  do _i=1 to dim(help_q);
    _resp = strip(help_q[_i]);
    select (_resp);
      when ('1') help_q[_i] = '1 Not helpful';
      when ('2') help_q[_i] = '2 Slightly helpful';
      when ('3') help_q[_i] = '3 Helpful';
      when ('4') help_q[_i] = '4 Very helpful';
      when ('5') help_q[_i] = '5 Extremely helpful';
      otherwise help_q[_i] = 'NA/Skip';
    end;
  end;

  do _i=1 to dim(sat_q);
    _resp = strip(sat_q[_i]);
    select (_resp);
      when ('1') sat_q[_i] = '1 Very dissatisfied';
      when ('2') sat_q[_i] = '2 Slightly dissatisfied';
      when ('3') sat_q[_i] = '3 Satisfied';
      when ('4') sat_q[_i] = '4 Very satisfied';
      when ('5') sat_q[_i] = '5 Extremely satisfied';
      otherwise sat_q[_i] = 'NA/Skip';
    end;
  end;
  drop _i _resp;
run;

title "Program helpfulness items (stacked percentages)";
proc freq data=work.ratings;
  tables
    q1_helpful q2_helpful_food q3_helpful_housing q4_helpful_mh /
    missing nocum;
run;

title "Satisfaction items (stacked percentages)";
proc freq data=work.ratings;
  tables
    q5_satisfaction_needle q14_fentanyl_satisfaction q16_xylazine_satisfaction
    q17_harm_satisfaction q18_van_satisfaction q20_overall_satisfaction /
    missing nocum;
run;
title;

/* ---------- Derived CSVs for reuse ---------- */
ods pdf text="^{style [font_weight=bold] Derived CSVs written to &OUT_DER}";

proc freq data=work.vdh_chr_data noprint;
  tables gender / out=work.gender_totals;
  tables age_group / out=work.age_totals;
  tables race_ethnicity / out=work.race_totals;
  tables region / out=work.region_totals;
run;

%macro _export(ds,name);
  proc export data=&ds
    outfile="&OUT_DER./&name..csv" dbms=csv replace; run;
%mend;

%_export(work.gender_totals,gender_totals);
%_export(work.age_totals,age_totals);
%_export(work.race_totals,race_totals);
%_export(work.region_totals,region_totals);

/* ---------- Close PDF ---------- */
ods pdf close;

/* ---------- End of file ---------- */
ods graphics off;
