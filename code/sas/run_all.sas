/* SPDX-License-Identifier: MIT */
options mprint mlogic symbolgen;

/* -------- repo-relative paths -------- */
%let ROOT=.;
%let DATA_SOURCE = synthetic;   /* synthetic | real */

/* Input selection */
%macro set_input;
  %if &DATA_SOURCE=synthetic %then %let INFILE=&ROOT./data/synthetic/chr_survey.csv;
  %else %let INFILE=C:\secure\VDH_CHR_ClientSurvey_2023.xlsx;  /* local, not committed */
%mend;
%set_input;

/* Outputs */
%let OUT_TOT=&ROOT./reports/VDH_CHR_Survey_Totals_Final.pdf;
%let OUT_SUB=&ROOT./reports/VDH_CHR_Survey_Subgroups_Final.pdf;
%let OUT_DER=&ROOT./data/derived;

/* Optional: confirm in SASLOG */
%put NOTE: DATA_SOURCE=&DATA_SOURCE INFILE=&INFILE;
%put NOTE: OUT_TOT=&OUT_TOT OUT_SUB=&OUT_SUB OUT_DER=&OUT_DER;

/* Run modules */
%include "&ROOT./code/sas/01_totals.sas";
%include "&ROOT./code/sas/02_subgroups.sas";
