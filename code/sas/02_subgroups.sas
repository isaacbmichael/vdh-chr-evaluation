/* SPDX-License-Identifier: MIT
--------------------------------------------------------------------------------
VDH CHR — Subgroups Summary (02_subgroups.sas)

Author: Isaac B. Michael
Created: 2024-10-20  (cleaned for public release)
Description:
  Produces a compact “Subgroups” PDF and a long-form CSV of percent-positive
  summaries by subgroup for the Virginia CHR client survey.

How this module is called (from run_all.sas):
  - Expects the following macro vars to be defined:
      &ROOT        -> repository root (path prefix for all outputs)
      &DATA_SOURCE -> SYNTHETIC | REAL
      &INFILE      -> input file (CSV for synthetic, XLSX for real)
      &OUT_SUB     -> PDF path for Subgroups report (under reports/)
      &OUT_DER     -> folder for derived CSVs (under data/derived/)
--------------------------------------------------------------------------------*/

/* --------- Session options (portable) --------- */
options
  mprint nomlogic nosymbolgen   /* quiet by default; flip on if debugging  */
  validvarname=v7               /* v7-style names after IMPORT             */
  nodate nonumber               /* cleaner PDF pages                       */
  orientation=landscape;        /* wide pages for tables                   */

ods noproctitle;
ods graphics on;

/* --------- Import (standalone-safe) --------- */
/* If an upstream step already built WORK.chr_raw, we reuse it.             */
%macro import_chr_data;
  %if %sysfunc(exist(work.chr_raw)) = 0 %then %do;
    %put NOTE: [02_subgroups] Importing input from &INFILE (source=&DATA_SOURCE).;

    %if %upcase(&DATA_SOURCE) = SYNTHETIC %then %do;
      proc import datafile="&INFILE"
        out=work.chr_raw dbms=csv replace;
        guessingrows=max;
        getnames=yes;
      run;
    %end;
    %else %do;
      proc import datafile="&INFILE"
        out=work.chr_raw dbms=xlsx replace;
        sheet="Sheet1";
        getnames=yes;
      run;
    %end;
  %end;
%mend;
%import_chr_data

/* --------- Minimal value engineering for subgrouping --------- */
data work.chr;
  length
    age_group $6
    race_ethnicity $18
    site_location2 $12
    regions $15;

  set work.chr_raw;

  /* Age buckets (fallback when missing) */
  if missing(age) then age_group = "Unknown";
  else if 18 <= age <= 34 then age_group = "18-34";
  else if 35 <= age <= 44 then age_group = "35-44";
  else if age >= 45 then age_group = "45+";

  /* Race/Ethnicity (short labels) */
  if ethn_hisp = 'Yes' then race_ethnicity = "Hispanic";
  else if race_white = 'Yes' then race_ethnicity = "NH-White";
  else if race_black = 'Yes' then race_ethnicity = "NH-Black";
  else if race_bi_multi = 'Yes' then race_ethnicity = "NH-Bi/Multi-racial";
  else race_ethnicity = "Other/Unknown";

  /* Site abbreviations (condensed legend labels) */
  if site_location = "(MASS) Minority AIDS Support Services - Newport News, Norfolk, Virginia Beach" then do;
    site_location2 = "MASS";
  end;
  else if site_location = "Chris Atwood Foundation - Fairfax Co. Prince William Co." then do;
    site_location2 = "CAF";
  end;
  else if site_location = "Council of Community Services - Roanoke" then do;
    site_location2 = "CCS";
  end;
  else if site_location = "Health Brigade - Richmond" then do;
    site_location2 = "HB";
  end;
  else if site_location = "Lenowisco Health District / Wise Co." then do;
    site_location2 = "Lenowisco HD";
  end;
  else if site_location = "Mt. Rogers Health District/ Smyth Co." then do;
    site_location2 = "Mt Rogers HD";
  end;
  else if site_location = "Strength In Peers - Harrisonburg, Rockingham Co., Page Co., Shenandoah Co." then do;
    site_location2 = "SIP";
  end;
  else if site_location = "Virginia Harm Reduction Coalition/Roanoke" then do;
    site_location2 = "VHRC";
  end;
  else site_location2 = "Unknown";

  /* Regions (roll-up) */
  if site_location2 in ("VHRC","CCS","Mt Rogers HD","Lenowisco HD") then regions = "Southwest VA";
  else if site_location2 = "HB" then regions = "Central VA";
  else if site_location2 = "MASS" then regions = "Hampton Rds";
  else if site_location2 in ("SIP","CAF") then regions = "NoVA/NW";
  else regions = "Unknown";

  /* Canonical label variables used for displays (same as 01_totals.sas) */
  length
    q1_label-q5_label q7_label-q10_label
    q13_label q14_label q15_label q16_label
    q17_label q18_label q19_label q20_label $40
    q6_label q11_label q12_label $6;

  array helpful{*} $ q1_helpful q2_helpful_food q3_helpful_housing q4_helpful_mh
                       q7_syphilis_info q8_hep_c_info q9_suicide_info q10_hiv_info;
  array hlabel{*}   $ q1_label      q2_label         q3_label           q4_label
                       q7_label        q8_label        q9_label           q10_label;

  do _i = 1 to dim(helpful);
    select (helpful{_i});
      when ('1') hlabel{_i} = "1. Not helpful";
      when ('2') hlabel{_i} = "2. Slightly helpful";
      when ('3') hlabel{_i} = "3. Helpful";
      when ('4') hlabel{_i} = "4. Very helpful";
      when ('5') hlabel{_i} = "5. Extremely helpful";
      otherwise      hlabel{_i} = "NA/Skip";
    end;
  end;

  array satis{*} $ q5_satisfaction_needle q14_fentanyl_satisfaction q16_xylazine_satisfaction
                    q17_harm_satisfaction q18_van_satisfaction q20_overall_satisfaction;
  array slabel{*} $ q5_label              q14_label               q16_label
                    q17_label             q18_label               q20_label;

  do _i = 1 to dim(satis);
    select (satis{_i});
      when ('1') slabel{_i} = "1. Very dissatisfied";
      when ('2') slabel{_i} = "2. Slightly dissatisfied";
      when ('3') slabel{_i} = "3. Satisfied";
      when ('4') slabel{_i} = "4. Very satisfied";
      when ('5') slabel{_i} = "5. Extremely satisfied";
      otherwise    slabel{_i} = "NA/Skip";
    end;
  end;

  /* Concerned scale */
  length q13_label q15_label $40;
  select (q13_fentanyl_concern);
    when ('1') q13_label = "1. Not at all concerned";
    when ('2') q13_label = "2. Slightly concerned";
    when ('3') q13_label = "3. Concerned";
    when ('4') q13_label = "4. Very concerned";
    when ('5') q13_label = "5. Extremely concerned";
    otherwise    q13_label = "NA/Skip";
  end;
  select (q15_xylazine_concern);
    when ('1') q15_label = "1. Not at all concerned";
    when ('2') q15_label = "2. Slightly concerned";
    when ('3') q15_label = "3. Concerned";
    when ('4') q15_label = "4. Very concerned";
    when ('5') q15_label = "5. Extremely concerned";
    otherwise    q15_label = "NA/Skip";
  end;

  /* Treatment consideration (Q19) */
  length q19_label $24;
  select (q19_treatment_consideration);
    when ('1') q19_label = "1. Not at all";
    when ('2') q19_label = "2. Slightly";
    when ('3') q19_label = "3. Moderately";
    when ('4') q19_label = "4. Quite a bit";
    when ('5') q19_label = "5. Great extent";
    otherwise    q19_label = "NA/Skip";
  end;

  /* Simple count buckets (Q6, Q11, Q12) */
  if missing(q6_prep_pep) then q6_label = "NA/Skip"; else q6_label = strip(q6_prep_pep);
  if missing(q11_hiv_tests_taken) then q11_label = "NA/Skip"; else q11_label = strip(q11_hiv_tests_taken);
  if missing(q12_narcan_use) then q12_label = "NA/Skip"; else q12_label = strip(q12_narcan_use);
run;

/* --------- Percent-positive rules ---------
  - DEFAULT: values in {"3","4","5"} are “positive”
  - ANYPOS : values >=1 for count questions (Q6, Q11, Q12)
------------------------------------------------ */
%let questions =
  q1_helpful q2_helpful_food q3_helpful_housing q4_helpful_mh q5_satisfaction_needle
  q6_prep_pep q7_syphilis_info q8_hep_c_info q9_suicide_info q10_hiv_info
  q11_hiv_tests_taken q12_narcan_use q13_fentanyl_concern q14_fentanyl_satisfaction
  q15_xylazine_concern q16_xylazine_satisfaction q17_harm_satisfaction
  q18_van_satisfaction q19_treatment_consideration q20_overall_satisfaction;

%let qlabels =
  Program Helpful|Food Referral Help|Housing Referral Help|Mental Health Help|Needle Exchange Satisfaction|
  PrEP/PEP Info Offered|Syphilis Information|Hepatitis C Information|Suicide Prevention Information|HIV Testing Information|
  HIV Tests Taken|NARCAN Use|Fentanyl Concern|Fentanyl Test Satisfaction|
  Xylazine Concern|Xylazine Test Satisfaction|Supplies Satisfaction|Van Services Satisfaction|Treatment Consideration|Overall Satisfaction;

%let rules =
  DEFAULT DEFAULT DEFAULT DEFAULT DEFAULT
  ANYPOS  DEFAULT DEFAULT DEFAULT DEFAULT
  ANYPOS  ANYPOS  DEFAULT DEFAULT
  DEFAULT DEFAULT DEFAULT DEFAULT DEFAULT DEFAULT;

%let subgroups = gender age_group race_ethnicity regions site_location2;

/* Utility macro: compute %positive within each subgroup level */
%macro percent_positive(ds=work.chr, out=work._sub_);
  %local nQ nS i j q var rule lbl sg;

  %let nQ = %sysfunc(countw(&questions));
  %let nS = %sysfunc(countw(&subgroups));

  /* Collector table */
  data &out; length question $40 subgroup $20 level $48; stop; run;

  %do i=1 %to &nQ;
    %let var = %scan(&questions,&i);
    %let rule = %scan(&rules,&i);
    %let q = %scan(&qlabels,&i,|);

    %do j=1 %to &nS;
      %let sg = %scan(&subgroups,&j);

      /* Frequency table for var by subgroup level */
      proc freq data=&ds noprint;
        tables &sg*&var / out=work._f;
      run;

      /* Summarize totals and “positive” per subgroup level */
      data work._pp;
        length question $40 subgroup $20 level $48;
        set work._f;
        by &sg;

        retain total high;
        if first.&sg then do; total=0; high=0; end;

        total + count;

        /* Apply rule */
        %if &rule = ANYPOS %then %do;
          /* Positive if NOT in ('0','NA/Skip','') */
          if upcase(strip(&var)) not in ('0','NA/SKIP','') then high + count;
        %end;
        %else %do; /* DEFAULT 3–5 */
          if &var in ('3','4','5') then high + count;
        %end;

        if last.&sg then do;
          question = "&q";
          subgroup = "&sg";
          level    = strip(vvalue(&sg));
          total_n  = total;
          high_n   = high;
          pct_high = ifn(total>0, round(100*high/total, 0.1), .);
          output;
        end;
        drop percent count;
      run;

      proc append base=&out data=work._pp force; run;
      proc datasets nolist; delete _f _pp; quit;

    %end; /* subgroup loop */
  %end; /* question loop */
%mend;
%percent_positive()

/* --------- Output: CSV summary --------- */
%let _csv = &OUT_DER./chr_subgroups_summary.csv;
proc sort data=work._sub_; by subgroup question level; run;
proc export data=work._sub_ outfile="&_csv" dbms=csv replace; run;

/* --------- Output: PDF (compact tables) --------- */
ods pdf file="&OUT_SUB" notoc;
title1 "Virginia CHR Client Survey — Subgroup Summaries";
title2 "Percent positive by subgroup (rules: default 3–5; Q6/Q11/Q12 = any value ≥1)";
footnote1 j=l "Source: VDH CHR client survey (public demo; synthetic option available)";
footnote2 j=l "Generated: %sysfunc(date(),worddate.)";

%macro report_by(group);
  proc report data=work._sub_ nowd;
    where upcase(subgroup) = "%upcase(&group)";
    columns question level pct_high total_n high_n;
    define question / group "Question" style(column)={width=36%};
    define level    / group "Subgroup: &group" style(column)={width=28%};
    define pct_high / analysis mean "Pct ≥ Rule" format=6.1;
    define total_n  / analysis sum  "N";
    define high_n   / analysis sum  "N ≥ Rule";
    compute after question; line ' '; endcomp;
  run;
%mend;

%report_by(gender)
%report_by(age_group)
%report_by(race_ethnicity)
%report_by(regions)
%report_by(site_location2)

ods pdf close;

/* --------- Done --------- */
ods graphics off;
%put NOTE: [02_subgroups] Wrote PDF to &OUT_SUB and CSV to &_csv.;
