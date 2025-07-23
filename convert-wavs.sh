#!/bin/bash

# Use Zenity to show a folder selection dialog
FOLDER=$(zenity --file-selection --directory --title="Select a Folder")

# Check if user canceled the dialog
if [ -z "$FOLDER" ]; then
    echo "No folder selected. Exiting."
    exit 1
fi

# Use the selected folder as the source directory
SOURCE_DIR="$FOLDER"
echo "Selected folder: $SOURCE_DIR"

# Create a converted directory inside the source directory
CONVERTED_DIR="$SOURCE_DIR/converted"
mkdir -p "$CONVERTED_DIR"

# Function to check if an audio file is compatible with SP404 MK2
is_compatible() {
    local file="$1"
    
    # Get audio file information using ffprobe
    local info=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_fmt,sample_rate -of csv=p=0 "$file" 2>/dev/null)
    
    # Check if ffprobe returned valid output
    if [ -z "$info" ]; then
        echo "Error: Could not retrieve audio info for $file"
        return 1
    fi
    
    # Extract bit depth and sample rate
    local sample_fmt=$(echo "$info" | head -1)
    local sample_rate=$(echo "$info" | tail -1)
    
    # For WAV files, check if sample format is compatible (16-bit or 24-bit)
    # For other formats, assume they need conversion to WAV
    if [[ "$file" == *.wav ]]; then
        if [[ "$sample_fmt" != *"s16"* && "$sample_fmt" != *"s24"* ]]; then
            return 1  # Not compatible
        fi
    else
        # Non-WAV files (e.g., MP3, FLAC, etc.) need conversion to WAV
        return 1
    fi
    
    # Check if sample rate is compatible
    # SP404 MK2 supports: 16, 22.05, 32, 44.1, 48, 88.2, 96, 176.4, or 192 kHz
    case "$sample_rate" in
        16000|22050|32000|44100|48000|88200|96000|176400|192000)
            return 0  # Compatible
            ;;
        *)
            return 1  # Not compatible
            ;;
    esac
}

# Export the is_compatible function to make it available to subshells
export -f is_compatible

# Initialize temporary file for counters
TEMP_COUNTS=$(mktemp)
echo "converted_count=0" > "$TEMP_COUNTS"
echo "copied_count=0" >> "$TEMP_COUNTS"
echo "already_processed_count=0" >> "$TEMP_COUNTS"

# Find all audio files in the source directory and process them
# Include common audio formats supported by ffmpeg
# Exclude files starting with ._ (macOS resource fork files)
# Exclude files in the converted directory
find "$SOURCE_DIR" -type f \( -name "*.wav" -o -name "*.mp3" -o -name "*.flac" -o -name "*.aiff" -o -name "*.ogg" -o -name "*.aac" -o -name "*.m4a" \) -not -path "$CONVERTED_DIR/*" -not -name "._*" -exec bash -c '
  for file; do
    # Get the relative path from SOURCE_DIR
    rel_path="${file#'"$SOURCE_DIR"'/}"
    
    # Replace the original extension with .wav for the output file
    output_file="'"$CONVERTED_DIR"'/${rel_path%.*}.wav"
    
    # Check if the file has already been processed in a previous run
    if [ -f "$output_file" ]; then
      echo "Already processed in previous run: $file"
      echo "already_processed_count=$(( $(grep already_processed_count "'"$TEMP_COUNTS"'" | cut -d= -f2) + 1 ))" > "'"$TEMP_COUNTS"'".tmp
      mv "'"$TEMP_COUNTS"'".tmp "'"$TEMP_COUNTS"'"
      continue
    fi
    
    # Create the directory structure in the converted directory
    target_dir="'"$CONVERTED_DIR"'/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    
    # Check if the file is already compatible
    if [[ "$file" == *.wav ]] && is_compatible "$file"; then
      echo "Copying compatible file: $file"
      # Just copy the file without conversion
      cp "$file" "$output_file"
      echo "copied_count=$(( $(grep copied_count "'"$TEMP_COUNTS"'" | cut -d= -f2) + 1 ))" > "'"$TEMP_COUNTS"'".tmp
      mv "'"$TEMP_COUNTS"'".tmp "'"$TEMP_COUNTS"'"
    else
      # Convert the file to WAV, preserving its path and setting compatible format
      echo "Converting incompatible file: $file"
      if ffmpeg -i "$file" -acodec pcm_s16le -ar 44100 "$output_file" 2>/dev/null; then
        # Update converted count
        echo "converted_count=$(( $(grep converted_count "'"$TEMP_COUNTS"'" | cut -d= -f2) + 1 ))" > "'"$TEMP_COUNTS"'".tmp
        mv "'"$TEMP_COUNTS"'".tmp "'"$TEMP_COUNTS"'"
      else
        echo "Failed to convert: $file"
      fi
    fi
  done
' bash {} +

# Read final counts from temp file
source "$TEMP_COUNTS"
rm "$TEMP_COUNTS"

# Report results
total_processed=$((converted_count + copied_count))
if [ "$total_processed" -eq 0 ] && [ "$already_processed_count" -eq 0 ]; then
    echo "No audio files were found to process."
    # Clean up the empty converted directory if it contains no files
    if [ -z "$(find "$CONVERTED_DIR" -type f -name "*.wav" 2>/dev/null)" ]; then
        rm -rf "$CONVERTED_DIR"
    fi
else
    echo "Processing complete!"
    [ "$converted_count" -gt 0 ] && echo "- $converted_count incompatible files were converted in this run"
    [ "$copied_count" -gt 0 ] && echo "- $copied_count already-compatible files were copied in this run"
    [ "$already_processed_count" -gt 0 ] && echo "- $already_processed_count files were already processed in previous runs"
    echo "All files are located in: $CONVERTED_DIR"
    echo "Original files remain untouched."
fi

echo "Your samples are now ready for the SP404 MK2. Enjoy!"
