#!/usr/bin/env bash

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2 | head -n 1
}
getactivemonitor() {
    if command -v niri >/dev/null 2>&1 && niri msg focused-output >/dev/null 2>&1; then
        niri msg focused-output | head -n 1 | sed -n 's/.*(\(.*\))/\1/p'
    elif command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
    fi
}

# Try to get save path from config, fallback to XDG Videos
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
SAVE_PATH=""
VIDEO_CODEC="libx264"
AUDIO_CODEC="aac"
FPS="60"
VIDEO_BITRATE_KBPS="12000"
AUDIO_BITRATE_KBPS="192"
PIXEL_FORMAT="yuv420p"
VIDEO_PRESET="veryfast"
VIDEO_CRF="21"
if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
    SAVE_PATH=$(jq -r '.screenRecord.savePath // empty' "$CONFIG_FILE" 2>/dev/null)
    VIDEO_CODEC=$(jq -r '.screenRecord.videoCodec // "libx264"' "$CONFIG_FILE" 2>/dev/null)
    AUDIO_CODEC=$(jq -r '.screenRecord.audioCodec // "aac"' "$CONFIG_FILE" 2>/dev/null)
    FPS=$(jq -r '.screenRecord.fps // 60' "$CONFIG_FILE" 2>/dev/null)
    VIDEO_BITRATE_KBPS=$(jq -r '.screenRecord.videoBitrateKbps // 12000' "$CONFIG_FILE" 2>/dev/null)
    AUDIO_BITRATE_KBPS=$(jq -r '.screenRecord.audioBitrateKbps // 192' "$CONFIG_FILE" 2>/dev/null)
    PIXEL_FORMAT=$(jq -r '.screenRecord.pixelFormat // "yuv420p"' "$CONFIG_FILE" 2>/dev/null)
    VIDEO_PRESET=$(jq -r '.screenRecord.preset // "veryfast"' "$CONFIG_FILE" 2>/dev/null)
    VIDEO_CRF=$(jq -r '.screenRecord.crf // 21' "$CONFIG_FILE" 2>/dev/null)
fi

# Fallback to XDG Videos if config path is empty
if [[ -z "$SAVE_PATH" ]]; then
    xdgvideo="$(xdg-user-dir VIDEOS)"
    if [[ $xdgvideo = "$HOME" ]]; then
        SAVE_PATH="$HOME/Videos"
    else
        SAVE_PATH="$xdgvideo"
    fi
fi

mkdir -p "$SAVE_PATH"
cd "$SAVE_PATH" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill wf-recorder &
else
    timestamp="$(getdate)"
    output_file="./recording_${timestamp}.mp4"
    common_args=(
        -f "$output_file"
        -t
        --pixel-format "$PIXEL_FORMAT"
        --codec "$VIDEO_CODEC"
        --framerate "$FPS"
        --codec-param "b=${VIDEO_BITRATE_KBPS}k"
    )

    case "$VIDEO_CODEC" in
        libx264|libx265)
            common_args+=(
                --codec-param "preset=$VIDEO_PRESET"
                --codec-param "crf=$VIDEO_CRF"
            )
            ;;
    esac

    audio_args=()
    if [[ $SOUND_FLAG -eq 1 ]]; then
        audio_device="$(getaudiooutput)"
        if [[ -n "$audio_device" ]]; then
            audio_args=(
                --audio="$audio_device"
                --audio-codec "$AUDIO_CODEC"
                --audio-codec-param "b=${AUDIO_BITRATE_KBPS}k"
                --sample-rate 48000
            )
        else
            audio_args=(
                --audio
                --audio-codec "$AUDIO_CODEC"
                --audio-codec-param "b=${AUDIO_BITRATE_KBPS}k"
                --sample-rate 48000
            )
        fi
    fi

    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "recording_${timestamp}.mp4" -a 'Recorder' & disown
        wf-recorder -o "$(getactivemonitor)" "${common_args[@]}" "${audio_args[@]}"
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi

        notify-send "Starting recording" "recording_${timestamp}.mp4" -a 'Recorder' & disown
        wf-recorder --geometry "$region" "${common_args[@]}" "${audio_args[@]}"
    fi
fi
