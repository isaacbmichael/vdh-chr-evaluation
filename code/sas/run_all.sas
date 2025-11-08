/* SPDX-License-Identifier: MIT */
/* -----------------------------------------------------------------------------
   VDH CHR — Run-All Orchestrator (run_all.sas)

   What this does:
     - Chooses the input (synthetic CSV by default; toggle to REAL for XLSX).
     - Ensures output folders exist.
     - Defines standard OUT_* macro vars used by the report modules.
     - Runs 01_totals.sas and 02_subgroups.sas.

   Usage:
     %include "code/sas/run_all.sas";
----------------------------------------------------------------------------- */

/* ---------- Session options (quiet by default) ---------- */
/* Uncomment the next line if you want verbose macro logging for debugging.    */
/* options mprint mlogic symbolgen;                                            */

options
  validvarname=v7           /* v7-style names after IMPORT                  */
  nodate nonumber           /* cleaner PDF pages                            */
;

/* ---------- Paths & data source toggle ---------- */
%let ROOT = .;                      /* repository root (relative)              */
%let DATA_SOURCE = synthetic;       /* synthetic | real                        */

/* ---------- Input selection ---------- */
%macro set_input;
  %if &DATA_SOURCE = synthetic %then
    %let INFILE = &ROOT./data/synthetic/chr_survey.csv;
  %else
    %let INFILE = C:\secure\VDH_CHR_ClientSurvey_2023.xlsx;  /* local, not committed */
%mend;
%set_input;

/* ---------- Ensure output directories exist (portable) ---------- */
%macro ensure_dir(dir);
  %local _exists;
  %let _exists = %sysfunc(fileexist(&dir));
  %if &_exists = 0 %then %do;
    options dlcreatedir;
    libname _mk "&dir";
    libname _mk clear;
  %end;
%mend;

/* Output roots */
%let OUT_DIR_REP = &ROOT./reports;
%let OUT_DIR_DER = &ROOT./data/derived;

/* Create them if missing */
%ensure_dir(&OUT_DIR_REP);
%ensure_dir(&OUT_DIR_DER);

/* ---------- Output files used by modules ---------- */
%let OUT_TOT = &OUT_DIR_REP./vdh_chr_survey_totals.pdf;
%let OUT_SUB = &OUT_DIR_REP./vdh_chr_survey_subgroups.pdf;
%let OUT_DER = &OUT_DIR_DER;

/* ---------- Optional: echo config to SASLOG ---------- */
%put NOTE- DATA_SOURCE=&DATA_SOURCE;
%put NOTE- INFILE=&INFILE;
%put NOTE- OUT_TOT=&OUT_TOT;
%put NOTE- OUT_SUB=&OUT_SUB;
%put NOTE- OUT_DER=&OUT_DER;

/* ---------- Run modules ---------- */
%include "&ROOT./code/sas/01_totals.sas";
%include "&ROOT./code/sas/02_subgroups.sas";
