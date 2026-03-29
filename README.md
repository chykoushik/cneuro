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

## Events

**Case 1**

| Event | Time |
|---|---|
| brakes_at_signal_mild | 0:52 |
| accident | 1:15 |
| start_severe | 1:22 |
| out_of_control | 2:04 |
| bad_handling | 3:00 |
| false_braking | 3:30 |
| sudden_acceleration | 5:40 |

**Case 2**

| Event | Time |
|---|---|
| head_shake | 0:20 |
| facial_expression | 0:50 |
| head_right | 1:23 |
| head_down | 1:33 |
| head_left | 1:43 |
| fast | 1:50 |
| top_speed | 2:10 |
| sound | 2:20 |
| deep_breath | 2:31 |
| smile | 2:54 |
| speak | 3:11 |
| comment | 3:34 |
| shake_head | 3:56 |
| slight_head_tilt | 4:10 |
| weird_sound | 4:31 |
| fast_2 | 5:12 |
| faster | 5:20 |
| anger | 5:45 |
| right_turn | 6:01 |
| left_hand_up | 6:21 |
| look_down | 7:00 |
| head_turn_right | 7:20 |
| look_left_mirror | 7:57 |
| look_right_mirror | 8:10 |
| head_shake_2 | 9:00 |
| head_shake_3 | 9:14 |
| right_view_both_sides | 9:25 |
| facial_expression_2 | 9:40 |
| structures | 10:00 |
| structures_2 | 10:18 |

**Case 3**

| Event | Time |
|---|---|
| start | 0:00 |
| listening_to_instruction | 0:17 |
| braking | 0:57 |
| sudden_braking | 2:07 |
| listening_to_instruction_2 | 2:20 |
| braking_traffic | 4:04 |
| car_passing | 4:59 |
| brakes | 5:33 |
| overtake | 6:10 |
| animal_interruption | 6:28 |
| handled | 6:50 |
| left_turn | 7:05 |

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
| `cneuro.pdf` | Report with figures (without description) |

## Requirements
- Julia 1.12 or higher

## Installation
**Step 1 - Download Julia**
- Go to https://julialang.org/downloads
- Download and install the latest stable release for your OS

**Step 2 - Clone this repository**
```
git clone https://github.com/chykoushik/cneuro.git
cd cneuro
```

**Step 3 - Install required Julia packages**

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
