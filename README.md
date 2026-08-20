# CAP–HRV: an automated EEG–ECG framework for CAP–HRV analysis

Open-source MATLAB pipeline for integrated analysis of the cyclic alternating
pattern (CAP) of NREM sleep EEG and heart-rate variability (HRV) from overnight
polysomnography. Companion code for the *Frontiers in Physiology* (Technology
and Code) manuscript.

**HRV is computed by calling the PhysioZoo mhrv toolbox directly** — the pipeline
does not reimplement or fork any HRV routine.

## What this repository contains

| File | Purpose |
|------|---------|
| `Shaween_HRV_Features_w_CAP.m` | Main driver: preprocessing, CAP A1 detection, CAP–ECG synchronization, HRV feature assembly |
| `ShaweenHRV_mhrv.m` | HRV feature extraction over CAP epochs, calling mhrv (`hrv_time`, `hrv_freq`, `hrv_nonlinear`) directly |
| `pan_tompkin.m` | Pan–Tompkins R-peak detection |
| `validate_CAP_A1.m` | Benchmarks CAP A1 detection against the PhysioNet CAP Sleep Database (Se/Sp/F1/κ) |
| `worked_example.m` | End-to-end demonstration on the bundled demo dataset |
| `demo_CAP_ECG_A1.csv` | Bundled demo dataset: 5 CAP A1-event ECG epochs (5 min @ 200 Hz). **Fully synthetic** — provided only to exercise the pipeline; not physiological data |

## Dependencies

- **MATLAB** R2023b or later, with the **Signal Processing Toolbox** and the
  **Statistics and Machine Learning Toolbox** (`kurtosis`, `skewness`).
- **PhysioZoo / mhrv toolbox — required.** All HRV features (time, frequency,
  nonlinear) are produced by mhrv, called directly. Install from
  https://physiozoo.com (https://github.com/physiozoo/mhrv), add it to the path,
  and cite PhysioZoo (Behar et al., 2018).

## Quick start

```matlab
addpath(genpath('mhrv'));     % PhysioZoo mhrv toolbox on the path (required)
addpath(pwd);                 % this repository
worked_example;               % runs on bundled demo_CAP_ECG_A1.csv -> demo_output.csv
```

## Reproducing the manuscript analyses

- **HRV feature extraction:** `ShaweenHRV_mhrv('ECG_Epochs.mat')` — computes the
  full HRV set for each CAP epoch by calling mhrv directly.
- **CAP A1 detection validation:** download the PhysioNet CAP Sleep Database
  (capslpdb), then `validate_CAP_A1('capslpdb', {'n1','n2','sdb1'}, 'cap_a1_validation.csv')`.

## Note on the previous version

Earlier commits included edited copies of mhrv routines (`hrv_*_edit.m`) and
standalone reimplementations (`poincare.m`, `freqband_power.m`, `dfa_edit.m`,
`mse_edit.m`) plus parameter-default files. These have been **removed**: they
were unnecessary and could diverge numerically from mhrv (particularly for the
nonlinear features). The pipeline now calls mhrv directly, so the reported HRV
values are exactly those of the mhrv toolbox.

## Data

Patient recordings are not redistributed (IRB #0019, ACPN, Abu Dhabi). Control
recordings are the publicly available CAP Sleep Database (Terzano et al., 2001;
PhysioNet, Goldberger et al., 2000). The bundled `demo_CAP_ECG_A1.csv` is
fully synthetic.

## License

CC-BY 4.0. Please cite the manuscript and PhysioZoo.

## Citation

> Shukir S, Moussa M, AlZaabi Y, Khandoker A, Struzik ZR. An Automated EEG–ECG
> Framework for CAP–HRV Analysis: Enabling Brain–Heart Coupling Studies in
> Sleep Disorders. *Frontiers in Physiology* (under review).
