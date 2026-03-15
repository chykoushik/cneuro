# CNeuro

EEG analysis of readiness potential (RP) and contingent negative variation (CNV)
recorded during a naturalistic driving simulation.

## Equipment
EEG recorded using the **Unicorn Hybrid Black** wireless headset (8 channels: Fz, C3, Cz, C4, Pz, PO7, Oz, PO8) at 250 Hz.

## Recordings

| Case | Purpose | Duration |
|---|---|---|
| Case 1 | RP analysis – cued and spontaneous braking events | 8.08 min |
| Case 2 | Artifact demonstration – deliberate motion/facial noise | 11.15 min |
| Case 3 | Both RP and CNV – instruction-cued and free braking | 8.38 min |

Events were marked manually in mm:ss format.

## Signal Processing

**Preprocessing**
- 50 Hz notch filter (IIR, Q = 30)
- Bandpass filter (Butterworth 4th order, 0.1–10 Hz)

**Epoching**
- RP window: −2.0 s to +3.0 s around motor onset (1251 samples)
- CNV window: −3.0 s to +2.0 s around action onset (1251 samples)

**Baseline Correction**
- RP: −0.5 to 0.0 s
- CNV: −2.5 to −2.0 s

**Artifact Rejection**
- EEG peak-to-peak amplitude > 120 µV
- Motion RMS robust Z-score > 4.5

## Results

| Case | Duration (min) | RP events | RP clean | CNV pairs | CNV clean |
|---|---|---|---|---|---|
| Case 1 | 8.08 | 3 | 2 | 0 | 0 |
| Case 2 | 11.15 | 0 | 0 | 0 | 0 |
| Case 3 | 8.38 | 7 | 3 | 2 | 1 |

- Case 1 yielded 2 clean RP epochs from 3 events
- Case 3 yielded 3 clean RP epochs from 7 events (57% rejection) and 1 clean CNV epoch
- Case 2 demonstrated motion and muscle artifacts from head movements and facial expressions

## Files

| File | Description |
|---|---|
| `config.jl` | All settings, paths, and events |
| `functions.jl` | Filters, epoching, baseline, plotting |
| `main.jl` | Main analysis script |
| `outputs_julia/` | All output figures and CSV files |
| `cneuro.pdf` | Full report with figures |

## Requirements

- Julia 1.12 or higher
- VS Code with Julia extension

## Installation

**Step 1 - Download Julia**
- Go to https://julialang.org/downloads
- Download and install the latest stable release for your OS

**Step 2 - Download VS Code**
- Go to https://code.visualstudio.com
- Download and install

**Step 3 - Install Julia extension in VS Code**
- Open VS Code
- Go to Extensions (Ctrl + Shift + X)
- Search "Julia"
- Install the one by julialang

**Step 4 - Clone this repository**
```
git clone https://github.com/chykoushik/cneuro.git
cd cneuro
```

**Step 5 - Install required Julia packages**

Open Julia terminal and run:
```julia
] add CSV DataFrames DSP FFTW Plots Statistics DelimitedFiles
```

## Usage

**Step 1 - Update the path in config.jl**

Open `config.jl` and change this line to your local path:
```julia
const BASE_PATH = "C:\\Users\\YourName\\Desktop\\cneuro"
```

**Step 2 - Run the analysis**
```
julia main.jl
```

**Step 3 - View outputs**

All figures and CSV files are saved to `outputs_julia/` folder.

## Language
Julia 1.12.5
```

---

Copy this into `README.md` then run:
```
git add README.md
git commit -m "update readme with installation guide"
git push
