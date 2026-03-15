# functions.jl

# mmss_to_sec
function mmss_to_sec(s::String)
    parts = split(strip(s), ":")
    return parse(Int, parts[1]) * 60 + parse(Int, parts[2])
end

# events_to_seconds
function events_to_seconds(case_name::String)
    offset = TIME_OFFSETS_SEC[case_name]
    return [(label, mmss_to_sec(t) + offset) for (label, t) in EVENTS[case_name]]
end

# labels_to_samples
function labels_to_samples(events_sec, wanted_labels, fs)
    samples = Int[]
    labels  = String[]
    for (label, sec) in events_sec
        if label in wanted_labels
            push!(samples, round(Int, sec * fs))
            push!(labels,  label)
        end
    end
    return samples, labels
end

# notch_filter
function notch_filter(data::Matrix{Float64}; fs=250, freq=50.0, q=30.0)
    w0     = freq / (fs / 2)
    bw     = w0 / q
    design = iirnotch(w0, bw)
    result = similar(data)
    for ch in 1:size(data, 2)
        result[:, ch] = filt(design, data[:, ch])
    end
    return result
end

# bandpass_filter
function bandpass_filter(data::Matrix{Float64}; fs=250, low=0.1, high=10.0, order=4)
    nyq    = fs / 2
    rtype  = Bandpass(low/nyq, high/nyq)
    design = digitalfilter(rtype, Butterworth(order))
    result = similar(data)
    for ch in 1:size(data, 2)
        result[:, ch] = filtfilt(design, data[:, ch])
    end
    return result
end

# make_epochs
function make_epochs(data::Matrix{Float64}, event_samples::Vector{Int},
                     fs::Int, tmin::Float64, tmax::Float64)
    pre     = round(Int, abs(tmin) * fs)
    post    = round(Int, tmax * fs)
    n_times = pre + post + 1
    n_ch    = size(data, 2)
    epochs    = Array{Float64}(undef, 0, n_times, n_ch)
    valid_idx = Int[]
    for (i, s) in enumerate(event_samples)
        start = s - pre
        stop  = s + post
        if start >= 1 && stop <= size(data, 1)
            ep = data[start:stop, :]
            if size(ep, 1) == n_times
                epochs = cat(epochs, reshape(ep, 1, n_times, n_ch), dims=1)
                push!(valid_idx, i)
            end
        end
    end
    return epochs, valid_idx
end

# baseline_correct
function baseline_correct(epochs::Array{Float64,3}, fs::Int,
                           tmin::Float64, baseline::Tuple{Float64,Float64})
    if size(epochs, 1) == 0
        return epochs
    end
    b0   = max(1, round(Int, (baseline[1] - tmin) * fs) + 1)
    b1   = min(size(epochs, 2), round(Int, (baseline[2] - tmin) * fs) + 1)
    base = mean(epochs[:, b0:b1, :], dims=2)
    return epochs .- base
end

# robust_z
function robust_z(x::Vector{Float64})
    med = median(x)
    mad = median(abs.(x .- med)) + 1e-12
    return 0.6745 .* (x .- med) ./ mad
end

# reject_bad_epochs
function reject_bad_epochs(eeg_epochs::Array{Float64,3};
                           motion_epochs=nothing,
                           p2p_thresh=120.0,
                           motion_z_thresh=4.5)
    if size(eeg_epochs, 1) == 0
        return eeg_epochs, Bool[]
    end
    p2p     = maximum(eeg_epochs, dims=2) .- minimum(eeg_epochs, dims=2)
    eeg_bad = vec(any(p2p .> p2p_thresh, dims=3))
    if motion_epochs !== nothing && size(motion_epochs, 1) == size(eeg_epochs, 1)
        motion_rms = [sqrt(mean(motion_epochs[i,:,:].^2))
                      for i in 1:size(motion_epochs, 1)]
        motion_bad = abs.(robust_z(motion_rms)) .> motion_z_thresh
    else
        motion_bad = falses(size(eeg_epochs, 1))
    end
    keep = .!(eeg_bad .| motion_bad)
    return eeg_epochs[keep, :, :], keep
end

# load_unicorn_csv
function load_unicorn_csv(path::String)
    df = CSV.read(path, DataFrame)
    rename!(df, [string(n) => strip(string(n)) for n in names(df)])
    if occursin(r"^unnamed"i, string(names(df)[1]))
        select!(df, Not(1))
    end
    return df
end

# load_case
function load_case(case_name::String, filename::String)
    path = joinpath(BASE_PATH, filename)
    println("  Reading: $path")
    df = load_unicorn_csv(path)
    eeg_cols = [n for n in names(df)
                if match(r"^EEG [1-8]$", string(n)) !== nothing]
    sort!(eeg_cols, by = c -> parse(Int, string(c)[end]))
    acc_cols = [n for n in names(df)
                if match(r"^ACC [XYZ]$", string(n)) !== nothing]
    gyr_cols = [n for n in names(df)
                if match(r"^GYR [XYZ]$", string(n)) !== nothing]
    if length(eeg_cols) != 8
        error("$case_name: expected 8 EEG columns, found $(length(eeg_cols))")
    end
    eeg = Matrix{Float64}(df[:, eeg_cols])
    eeg = notch_filter(eeg,    fs=FS, freq=50.0, q=30.0)
    eeg = bandpass_filter(eeg, fs=FS, low=0.1,   high=10.0, order=4)
    motion = nothing
    if length(acc_cols) == 3 && length(gyr_cols) == 3
        acc    = Matrix{Float64}(df[:, acc_cols])
        gyr    = Matrix{Float64}(df[:, gyr_cols])
        motion = hcat(acc, gyr)
    end
    time_s     = collect(0:1/FS:(size(eeg, 1)-1)/FS)
    duration_s = size(eeg, 1) / FS
    return Dict(
        "eeg"        => eeg,
        "motion"     => motion,
        "time_s"     => time_s,
        "duration_s" => duration_s,
    )
end

# save_fig
function save_fig(p, fname::String)
    path = joinpath(OUT_DIR, fname)
    savefig(p, path)
    println("  Saved: $path")
end

# plot_raw_with_events
function plot_raw_with_events(time_s, eeg, events_sec, title_str;
                               ch=1, case_name="")
    ch_name = UNICORN_CH_NAMES[ch]
    p = plot(time_s, eeg[:, ch],
             linewidth=0.7, label=false,
             title=title_str,
             xlabel="Time (s)",
             ylabel="$ch_name (uV)",
             size=(1200, 300))
    ymin   = minimum(eeg[:, ch])
    ymax   = maximum(eeg[:, ch])
    yrange = ymax - ymin > 0 ? ymax - ymin : 1.0
    txt_y  = ymax - 0.12 * yrange
    for (label, sec) in events_sec
        if 0 <= sec <= time_s[end]
            vline!(p, [sec], color=:red, linestyle=:dash, alpha=0.4, label=false)
            annotate!(p, sec + 0.05, txt_y,
                      text(label, :red, :left, 6, rotation=90))
        else
            println("  [WARN] '$label' at $(round(sec, digits=1))s outside recording")
        end
    end
    display(p)
    save_fig(p, "$(case_name)_raw_ch$(ch).png")
end

# plot_overlay
function plot_overlay(epochs::Array{Float64,3}, fs::Int, tmin::Float64;
                      ch=1, title_str="Epoch overlay", fname="overlay.png")
    if size(epochs, 1) == 0
        println("  No epochs for: $title_str")
        return
    end
    ch_name = UNICORN_CH_NAMES[ch]
    times   = collect(0:size(epochs, 2)-1) ./ fs .+ tmin
    p = plot(title=title_str,
             xlabel="Time (s)",
             ylabel="$ch_name (uV)",
             size=(800, 500))
    for i in 1:size(epochs, 1)
        plot!(p, times, epochs[i, :, ch],
              alpha=0.3, linewidth=0.8, label=false)
    end
    avg = vec(mean(epochs[:, :, ch], dims=1))
    plot!(p, times, avg, color=:black, linewidth=2.5, label="Average")
    vline!(p, [0.0], color=:red, linestyle=:dash, label=false)
    display(p)
    save_fig(p, fname)
end

# plot_average_all_channels
function plot_average_all_channels(epochs::Array{Float64,3}, fs::Int,
                                    tmin::Float64;
                                    title_str="Average", fname="avg_all.png")
    if size(epochs, 1) == 0
        println("  No epochs for: $title_str")
        return
    end
    erp   = dropdims(mean(epochs, dims=1), dims=1)
    times = collect(0:size(erp, 1)-1) ./ fs .+ tmin
    p = plot(title=title_str,
             xlabel="Time (s)",
             ylabel="Amplitude (uV)",
             size=(900, 500))
    for ch in 1:size(erp, 2)
        plot!(p, times, erp[:, ch], label=UNICORN_CH_NAMES[ch], linewidth=1.2)
    end
    vline!(p, [0.0], color=:black, linestyle=:dash, linewidth=1.2, label=false)
    display(p)
    save_fig(p, fname)
end

# plot_psd_single
function plot_psd_single(sig::Vector{Float64}, fs::Int; title_str="PSD")
    n    = length(sig)
    win  = min(1024, n)
    freq = rfftfreq(win, fs)
    pxx  = abs2.(rfft(sig[1:win])) ./ win
    return plot(freq, pxx,
                yscale=:log10,
                title=title_str,
                xlabel="Frequency (Hz)",
                ylabel="PSD (uV2/Hz)",
                linewidth=1.2,
                label=false)
end

println("functions.jl loaded")