# CAP–HRV: an automated EEG–ECG framework for CAP–HRV analysis

Open-source MATLAB pipeline for integrated analysis of the cyclic alternating
pattern (CAP) of NREM sleep EEG and heart-rate variability (HRV) from
overnight polysomnography. Companion code for the *Frontiers in Physiology*
(Technology and Code) manuscript.

## What this repository contains

| File | Purpose |
|------|---------|
| `Shaween_HRV_Features_w_CAP.m` | Main driver: preprocessing, CAP A1 detection, CAP–ECG synchronization, HRV feature assembly |
| `ShaweenHRV.m` | HRV feature extraction over CAP A-phase ECG epochs |
| `pan_tompkin.m` | Pan–Tompkins R-peak detection |
| `hrv_time_edit.m` | Time-domain HRV (AVNN, SDNN, RMSSD, pNN, SEM) |
| `hrv_freq_edit.m` | Frequency-domain HRV (Lomb–Scargle: VLF/LF/HF, LF/HF, total power, β) |
| `hrv_nonlinear_edit.m` | Nonlinear HRV (Poincaré SD1/SD2, DFA α1/α2, sample entropy) |
| `hrv_fragmentation_edit.m` | Fragmentation indices (PIP, IALS, PSS, PAS) |
| `poincare.m`, `freqband_power.m` | Poincaré SD1/SD2 and spectral band-power helpers (standalone, standard definitions) |
| `dfa_edit.m`, `mse_edit.m` | DFA and multiscale sample-entropy helpers (standalone, standard definitions) |
| `make_defaults.m` | Creates/regenerates `Frequency_defaults.mat` and `Nonlinear_defaults.mat` |
| `Frequency_defaults.mat`, `Nonlinear_defaults.mat` | Parameter defaults loaded by `hrv_freq_edit.m` / `hrv_nonlinear_edit.m` (produced by `make_defaults`) |
| `validate_CAP_A1.m` | Benchmarks CAP A1 detection against the PhysioNet CAP Sleep Database (sensitivity, specificity, F1, Cohen's κ) |
| `compare_mhrv_parity.m` | Reproducibility check: runs the pipeline routines and the PhysioZoo mhrv library on identical R-R inputs and reports per-metric agreement |
| `run_A1_HRV_controls.m` | Per-subject A1-event HRV over the capslpdb control cohort |
| `worked_example.m` | End-to-end demonstration on the bundled demo dataset |
| `demo_CAP_ECG_A1.csv` | Bundled demo dataset: 5 CAP A1-event ECG epochs (5 min @ 200 Hz). **Fully synthetic** — provided only to exercise the pipeline; not physiological data |

## Dependencies

**MATLAB** R2023b or later, with the **Signal Processing Toolbox** (`plomb`,
`pyulear`, `pwelch`, `periodogram`, `findpeaks`), the **Image Processing
Toolbox** (`padarray`, used for spectral-peak handling in `hrv_freq_edit.m`),
and the **Statistics and Machine Learning Toolbox** (`kurtosis`, `skewness`).

**Self-contained — no external HRV toolbox required.** The Poincaré, band-power,
DFA, and multiscale-entropy helpers (`poincare.m`, `freqband_power.m`,
`dfa_edit.m`, `mse_edit.m`) are bundled here as standalone, standard-definition
implementations, and the parameter files (`Frequency_defaults.mat`,
`Nonlinear_defaults.mat`) are produced by `make_defaults`. The pipeline
therefore runs without installing the PhysioZoo mhrv toolbox.

> These helpers reproduce the conventional HRV definitions (Poincaré SD1/SD2;
> DFA α1 over 4–16 and α2 over 16–64 beats; sample entropy m=2, r=0.2·SD;
> trapezoidal band power over the standard VLF/LF/HF bands). They let the code
> run and give conventional results; for bit-exact reproduction of the original
> published values, use the original mhrv-derived routines/parameters if
> available.

**PhysioZoo / mhrv toolbox** is needed **only** for `compare_mhrv_parity.m`,
which compares the pipeline against mhrv. Install from https://physiozoo.com
(https://github.com/physiozoo/mhrv) and cite PhysioZoo (Behar et al., 2018).

## Quick start

```matlab
addpath(pwd);        % this repository
make_defaults;       % one-time: writes Frequency_defaults.mat / Nonlinear_defaults.mat
worked_example;      % runs on bundled demo_CAP_ECG_A1.csv -> demo_output.csv
```

## Reproducing the manuscript analyses

- **CAP A1 detection validation (Section 2.4):** download the PhysioNet CAP
  Sleep Database (capslpdb), then
  `validate_CAP_A1('capslpdb', {'n1','n2','sdb1'}, 'cap_a1_validation.csv')`.
- **Control A1-event HRV (Table 5):**
  `run_A1_HRV_controls('CAP_ECG_Epochs.mat', 'A1_HRV_per_control_subject.xlsx')`.
- **HRV port-consistency (Table 3 / Section 3.3):** install mhrv, then
  `compare_mhrv_parity` — writes `mhrv_parity.csv` with per-metric agreement.

## Data

The patient recordings are not redistributed (IRB #0019, ACPN, Abu Dhabi). The
control recordings are the publicly available CAP Sleep Database
(Terzano et al., 2001; PhysioNet, Goldberger et al., 2000). The bundled
`demo_CAP_ECG_A1.csv` is fully synthetic.

## License

CC-BY 4.0. If you use this code, please cite the manuscript (and PhysioZoo if you
run `compare_mhrv_parity.m`).

## Citation

> Shukir S, Moussa M, AlZaabi Y, Khandoker A, Struzik ZR. An Automated EEG–ECG
> Framework for CAP–HRV Analysis: Enabling Brain–Heart Coupling Studies in
> Sleep Disorders. *Frontiers in Physiology* (under review).
