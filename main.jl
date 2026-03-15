# main.jl
include("config.jl")
include("functions.jl")

mkpath(OUT_DIR)

results = Dict()

# Load
for case_name in ["case1", "case2", "case3"]
    filename = CASE_FILES[case_name]
    println("="^70)
    println("Loading $case_name: $filename")
    case   = load_case(case_name, filename)
    ev_sec = events_to_seconds(case_name)
    println("  Duration : $(round(case["duration_s"] / 60, digits=2)) min")
    println("  Motion   : $(case["motion"] !== nothing ? "yes" : "no")")
    println("  Events:")
    for (label, sec) in ev_sec
        status = 0 <= sec <= case["duration_s"] ? "OK" : "OUTSIDE"
        println("    $(rpad(label, 32)) $(round(sec, digits=1))s  [$status]")
    end
    results[case_name] = Dict("data" => case, "events_sec" => ev_sec)
end

# RawEEG
for case_name in ["case1", "case2", "case3"]
    case = results[case_name]["data"]
    plot_raw_with_events(
        case["time_s"],
        case["eeg"],
        results[case_name]["events_sec"],
        "$(uppercase(case_name)) - Filtered EEG with Event Markers (Fz)",
        ch=1,
        case_name=case_name,
    )
end

# RP
for case_name in ["case1", "case2", "case3"]
    println("="^70)
    println("RP analysis: $case_name")
    wanted = RP_EVENT_NAMES[case_name]
    if isempty(wanted)
        println("  No RP events defined - skipping.")
        results[case_name]["rp_epochs"] = Array{Float64}(undef, 0, 0, 0)
        continue
    end
    case                  = results[case_name]["data"]
    ev_samples, ev_labels = labels_to_samples(
        results[case_name]["events_sec"], wanted, FS
    )
    println("  Events: $ev_labels")
    eeg_epochs, valid_idx = make_epochs(
        case["eeg"], ev_samples, FS, RP_TMIN, RP_TMAX
    )
    if case["motion"] !== nothing
        valid_samples    = [ev_samples[i] for i in valid_idx]
        motion_epochs, _ = make_epochs(
            case["motion"], valid_samples, FS, RP_TMIN, RP_TMAX
        )
    else
        motion_epochs = nothing
    end
    eeg_epochs         = baseline_correct(eeg_epochs, FS, RP_TMIN, RP_BASELINE)
    clean_epochs, keep = reject_bad_epochs(
        eeg_epochs,
        motion_epochs=motion_epochs,
        p2p_thresh=120.0,
        motion_z_thresh=4.5
    )
    println("  Total epochs : $(size(eeg_epochs, 1))")
    println("  Clean epochs : $(size(clean_epochs, 1))")
    results[case_name]["rp_epochs"] = clean_epochs
    plot_overlay(
        clean_epochs, FS, RP_TMIN,
        ch=1,
        title_str="$(uppercase(case_name)) - RP overlay (Fz)",
        fname="$(case_name)_rp_overlay.png",
    )
    plot_average_all_channels(
        clean_epochs, FS, RP_TMIN,
        title_str="$(uppercase(case_name)) - RP grand average (all channels)",
        fname="$(case_name)_rp_avg_all.png",
    )
end

# CNV
for case_name in ["case1", "case2", "case3"]
    println("="^70)
    println("CNV analysis: $case_name")
    pairs = CNV_PAIRS[case_name]
    if isempty(pairs)
        println("  No CNV pairs defined - skipping.")
        results[case_name]["cnv_epochs"] = Array{Float64}(undef, 0, 0, 0)
        continue
    end
    case       = results[case_name]["data"]
    event_dict = Dict(results[case_name]["events_sec"])
    action_samples = Int[]
    pair_labels    = String[]
    for (warn, act) in pairs
        if haskey(event_dict, warn) && haskey(event_dict, act)
            push!(action_samples, round(Int, event_dict[act] * FS))
            push!(pair_labels,    "$warn to $act")
        else
            missing_keys = [x for x in (warn, act) if !haskey(event_dict, x)]
            println("  [WARN] Skipping pair ($warn to $act): $missing_keys not found")
        end
    end
    println("  Pairs used: $pair_labels")
    eeg_epochs, valid_idx = make_epochs(
        case["eeg"], action_samples, FS, CNV_TMIN, CNV_TMAX
    )
    if case["motion"] !== nothing
        valid_samples    = [action_samples[i] for i in valid_idx]
        motion_epochs, _ = make_epochs(
            case["motion"], valid_samples, FS, CNV_TMIN, CNV_TMAX
        )
    else
        motion_epochs = nothing
    end
    eeg_epochs         = baseline_correct(eeg_epochs, FS, CNV_TMIN, CNV_BASELINE)
    clean_epochs, keep = reject_bad_epochs(
        eeg_epochs,
        motion_epochs=motion_epochs,
        p2p_thresh=120.0,
        motion_z_thresh=4.5
    )
    println("  Total epochs : $(size(eeg_epochs, 1))")
    println("  Clean epochs : $(size(clean_epochs, 1))")
    results[case_name]["cnv_epochs"] = clean_epochs
    plot_overlay(
        clean_epochs, FS, CNV_TMIN,
        ch=1,
        title_str="$(uppercase(case_name)) - CNV overlay (Fz)",
        fname="$(case_name)_cnv_overlay.png",
    )
    plot_average_all_channels(
        clean_epochs, FS, CNV_TMIN,
        title_str="$(uppercase(case_name)) - CNV grand average (all channels)",
        fname="$(case_name)_cnv_avg_all.png",
    )
end

# ArtifactDemo
println("="^70)
println("CASE2 artifact demonstration")
case2           = results["case2"]["data"]
art_samples, art_labels = labels_to_samples(
    results["case2"]["events_sec"], ARTIFACT_LABELS_CASE2, FS
)
art_epochs, _   = make_epochs(case2["eeg"], art_samples, FS, -1.0, 2.0)
println("  Labels : $art_labels")
println("  Epochs : $(size(art_epochs, 1))")
plot_overlay(
    art_epochs, FS, -1.0,
    ch=1,
    title_str="CASE2 - Artifact overlay (Fz)",
    fname="case2_artifact_overlay.png",
)
plot_average_all_channels(
    art_epochs, FS, -1.0,
    title_str="CASE2 - Artifact average (all channels)",
    fname="case2_artifact_avg_all.png",
)

# PSD
p1 = plot_psd_single(results["case1"]["data"]["eeg"][:, 1], FS,
                     title_str="CASE1 - Welch PSD (Fz)")
p2 = plot_psd_single(results["case2"]["data"]["eeg"][:, 1], FS,
                     title_str="CASE2 - Welch PSD (Fz)")
p3 = plot_psd_single(results["case3"]["data"]["eeg"][:, 1], FS,
                     title_str="CASE3 - Welch PSD (Fz)")
psd_fig = plot(p1, p2, p3, layout=(1,3), size=(1400,400))
display(psd_fig)
savefig(psd_fig, joinpath(OUT_DIR, "all_cases_psd.png"))
println("  Saved: all_cases_psd.png")

# Summary
rows = []
for case_name in ["case1", "case2", "case3"]
    rp_ep  = get(results[case_name], "rp_epochs",  nothing)
    cnv_ep = get(results[case_name], "cnv_epochs", nothing)
    push!(rows, (
        case              = case_name,
        duration_min      = round(results[case_name]["data"]["duration_s"] / 60, digits=2),
        rp_events_defined = length(RP_EVENT_NAMES[case_name]),
        rp_clean_epochs   = rp_ep  !== nothing ? size(rp_ep,  1) : 0,
        cnv_pairs_defined = length(CNV_PAIRS[case_name]),
        cnv_clean_epochs  = cnv_ep !== nothing ? size(cnv_ep, 1) : 0,
    ))
end
summary_df = DataFrame(rows)
println("\nSUMMARY")
println(summary_df)
CSV.write(joinpath(OUT_DIR, "summary.csv"), summary_df)

# CSV
for case_name in ["case1", "case2", "case3"]
    rp_ep = get(results[case_name], "rp_epochs", nothing)
    if rp_ep !== nothing && size(rp_ep, 1) > 0
        rp_avg = dropdims(mean(rp_ep, dims=1), dims=1)
        rp_df  = DataFrame(rp_avg, UNICORN_CH_NAMES)
        rp_df[!, "time_sec"] = collect(0:size(rp_avg,1)-1) ./ FS .+ RP_TMIN
        CSV.write(joinpath(OUT_DIR, "$(case_name)_rp_average.csv"), rp_df)
    end
    cnv_ep = get(results[case_name], "cnv_epochs", nothing)
    if cnv_ep !== nothing && size(cnv_ep, 1) > 0
        cnv_avg = dropdims(mean(cnv_ep, dims=1), dims=1)
        cnv_df  = DataFrame(cnv_avg, UNICORN_CH_NAMES)
        cnv_df[!, "time_sec"] = collect(0:size(cnv_avg,1)-1) ./ FS .+ CNV_TMIN
        CSV.write(joinpath(OUT_DIR, "$(case_name)_cnv_average.csv"), cnv_df)
    end
end

println("\nAll outputs saved to: $OUT_DIR")
println("\nPress Enter to close...")
readline()