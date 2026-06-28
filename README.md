# CAP–HRV: an automated EEG–ECG framework for CAP–HRV analysis

Open-source MATLAB pipeline for integrated analysis of the cyclic alternating
pattern (CAP) of NREM sleep EEG and heart-rate variability (HRV) from
overnight polysomnography. Companion code for the *Frontiers in Physiology*
(Technology and Code) manuscript.

## What this repository contains

| File | Purpose |
|------|---------|
| `ShaweenHRV.m` | HRV feature extraction over CAP A-phase ECG epochs |
| `Shaween_HRV_Features_w_CAP.m` | Main driver: preprocessing, CAP A1 detection, CAP–ECG synchronization, HRV feature assembly |
| `pan_tompkin.m` | Pan–Tompkins R-peak detection |
| `hrv_time_edit.m` | Time-domain HRV (AVNN, SDNN, RMSSD, pNN, SEM) |
| `hrv_freq_edit.m` | Frequency-domain HRV (Lomb–Scargle: VLF/LF/HF, LF/HF, total power) |
| `hrv_nonlinear_edit.m` | Nonlinear HRV (Poincaré SD1/SD2, DFA α1/α2, sample entropy) |
| `hrv_fragmentation_edit.m` | Fragmentation indices (PIP, IALS, PSS, PAS) |
| `validate_CAP_A1.m` | Benchmarks CAP A1 detection against the PhysioNet CAP Sleep Database (sensitivity, specificity, F1, Cohen's κ) |
| `compare_mhrv_parity.m` | Reproducibility check: runs the ported HRV routines and the PhysioZoo mhrv library on identical R-R inputs and reports per-metric agreement |
| `run_A1_HRV_controls.m` | Per-subject A1-event HRV over the capslpdb control cohort |
| `worked_example.m` | End-to-end demonstration on the bundled demo dataset |
| `demo_CAP_ECG_A1.csv` | Bundled demo dataset: 5 CAP A1-event ECG epochs (5 min @ 200 Hz). **Fully synthetic** — provided only to exercise the pipeline; not physiological data |

## Dependencies

- **MATLAB** R2023b or later (Signal Processing Toolbox; Statistics Toolbox for `kurtosis`/`skewness`).
- **PhysioZoo / mhrv toolbox** — required by `hrv_freq_edit.m` and `hrv_nonlinear_edit.m`
  (provides `poincare`, `dfa_edit`, `mse_edit`, and the `Frequency_defaults` /
  `Nonlinear_defaults` parameter files). Install from https://physiozoo.com
  (https://github.com/physiozoo/mhrv) and add it to the MATLAB path. These files
  are **not** redistributed here; please cite PhysioZoo (Behar et al., 2018).

## Quick start

```matlab
addpath(genpath('mhrv'));          % PhysioZoo mhrv toolbox on the path (optional)
addpath(pwd);                      % this repository
worked_example;                    % runs on bundled demo_CAP_ECG_A1.csv -> demo_output.csv
```
The worked example runs even without mhrv (it then reports the time-domain and
fragmentation features; frequency/nonlinear columns are filled once mhrv is installed).

## Reproducing the manuscript analyses

- **HRV port-consistency (Table 3 / Section 3.3):**
  `compare_mhrv_parity.m` — runs the ported routines and mhrv on identical R-R
  arrays and writes `mhrv_parity.csv` with per-metric agreement.
- **CAP A1 detection validation (Section 2.4):**
  download the PhysioNet CAP Sleep Database (capslpdb), then
  `validate_CAP_A1('capslpdb', {'n1','n2','sdb1'}, 'cap_a1_validation.csv')`.
- **Control A1-event HRV (Table 5):**
  `run_A1_HRV_controls('CAP_ECG_Epochs.mat', 'A1_HRV_per_control_subject.xlsx')`.

## Data

The patient recordings are not redistributed (IRB #0019, ACPN, Abu Dhabi). The
control recordings are the publicly available CAP Sleep Database
(Terzano et al., 2001; PhysioNet, Goldberger et al., 2000).

## License

CC-BY 4.0. If you use this code, please cite the manuscript and PhysioZoo.

## Citation

> Shukir S, Moussa M, AlZaabi Y, Khandoker A, Struzik ZR. An Automated EEG–ECG
> Framework for CAP–HRV Analysis: Enabling Brain–Heart Coupling Studies in
> Sleep Disorders. *Frontiers in Physiology* (under review).
