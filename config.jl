# config.jl
using CSV, DataFrames, DSP, Plots, Statistics, FFTW

# Channels
const UNICORN_CH_NAMES = ["Fz","C3","Cz","C4","Pz","PO7","Oz","PO8"]

# Paths
const BASE_PATH = "C:\\Users\\Koush\\Desktop\\cneuro"
const OUT_DIR   = joinpath(BASE_PATH, "outputs_julia")

# Files
const CASE_FILES = Dict(
    "case1" => "UnicornRawDataRecorder_19_11_2025_10_51_060.csv",
    "case2" => "UnicornRawDataRecorder_19_11_2025_11_04_170.csv",
    "case3" => "UnicornRawDataRecorder_19_11_2025_11_17_440.csv",
)

# SamplingRate
const FS = 250

# Offsets
const TIME_OFFSETS_SEC = Dict(
    "case1" => 0.0,
    "case2" => 0.0,
    "case3" => 0.0,
)

# Events
const EVENTS = Dict(
    "case1" => [
        ("brakes_at_signal_mild",  "0:52"),
        ("accident",               "1:15"),
        ("start_severe",           "1:22"),
        ("out_of_control",         "2:04"),
        ("bad_handling",           "3:00"),
        ("false_braking",          "3:30"),
        ("sudden_acceleration",    "5:40"),
    ],
    "case2" => [
        ("head_shake",             "0:20"),
        ("facial_expression",      "0:50"),
        ("head_right",             "1:23"),
        ("head_down",              "1:33"),
        ("head_left",              "1:43"),
        ("fast",                   "1:50"),
        ("top_speed",              "2:10"),
        ("sound",                  "2:20"),
        ("deep_breath",            "2:31"),
        ("smile",                  "2:54"),
        ("speak",                  "3:11"),
        ("comment",                "3:34"),
        ("shake_head",             "3:56"),
        ("slight_head_tilt",       "4:10"),
        ("weird_sound",            "4:31"),
        ("fast_2",                 "5:12"),
        ("faster",                 "5:20"),
        ("anger",                  "5:45"),
        ("right_turn",             "6:01"),
        ("left_hand_up",           "6:21"),
        ("look_down",              "7:00"),
        ("head_turn_right",        "7:20"),
        ("look_left_mirror",       "7:57"),
        ("look_right_mirror",      "8:10"),
        ("head_shake_2",           "9:00"),
        ("head_shake_3",           "9:14"),
        ("right_view_both_sides",  "9:25"),
        ("facial_expression_2",    "9:40"),
        ("structures",            "10:00"),
        ("structures_2",          "10:18"),
    ],
    "case3" => [
        ("start",                      "0:00"),
        ("listening_to_instruction",   "0:17"),
        ("braking",                    "0:57"),
        ("sudden_braking",             "2:07"),
        ("listening_to_instruction_2", "2:20"),
        ("braking_traffic",            "4:04"),
        ("car_passing",                "4:59"),
        ("brakes",                     "5:33"),
        ("overtake",                   "6:10"),
        ("animal_interruption",        "6:28"),
        ("handled",                    "6:50"),
        ("left_turn",                  "7:05"),
    ],
)

# RP
const RP_TMIN     = -2.0
const RP_TMAX     =  3.0
const RP_BASELINE = (-0.5, 0.0)
const RP_EVENT_NAMES = Dict(
    "case1" => ["brakes_at_signal_mild","false_braking","sudden_acceleration"],
    "case2" => String[],
    "case3" => ["braking","sudden_braking","braking_traffic",
                "brakes","overtake","animal_interruption","left_turn"],
)

# CNV
const CNV_TMIN     = -3.0
const CNV_TMAX     =  2.0
const CNV_BASELINE = (-2.5, -2.0)
const CNV_PAIRS = Dict(
    "case1" => Tuple{String,String}[],
    "case2" => Tuple{String,String}[],
    "case3" => [
        ("listening_to_instruction",   "braking"),
        ("listening_to_instruction_2", "braking_traffic"),
    ],
)

# Artifacts
const ARTIFACT_LABELS_CASE2 = [
    "head_shake","head_right","head_down","head_left",
    "deep_breath","smile","speak","comment",
    "shake_head","slight_head_tilt","left_hand_up",
]

println("config.jl loaded")