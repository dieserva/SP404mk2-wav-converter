#!/bin/bash

# Use AppleScript to show a folder selection dialog
FOLDER=$(osascript -e 'tell application "Finder"
    set folderPath to POSIX path of (choose folder with prompt "Select folder containing WAV files:")
    return folderPath
end tell')

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

# Function to check if a WAV file is compatible with SP404 MK2
is_compatible() {
    local file="$1"
    
    # Get audio file information using ffprobe
    local info=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_fmt,sample_rate -of csv=p=0 "$file" 2>/dev/null)
    
    # Extract bit depth and sample rate
    local sample_fmt=$(echo "$info" | head -1)
    local sample_rate=$(echo "$info" | tail -1)
    
    # Check if sample format is compatible (16-bit or 24-bit)
    # s16 = 16-bit, s32 = 32-bit, etc.
    if [[ "$sample_fmt" != *"s16"* && "$sample_fmt" != *"s24"* ]]; then
        return 1  # Not compatible
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

# Counters for tracking what's happening
converted_count=0
copied_count=0
already_processed_count=0

# Find all WAV files in the source directory and process them
# Exclude files starting with ._ (macOS resource fork files)
# Exclude files in the converted directory
find "$SOURCE_DIR" -name "*.wav" -not -path "$CONVERTED_DIR/*" -not -name "._*" -exec sh -c '
  for file; do
    # Get the relative path from SOURCE_DIR
    rel_path="${file#'"$SOURCE_DIR"'/}"
    
    # Check if the file has already been processed in a previous run
    converted_file="'"$CONVERTED_DIR"'/$rel_path"
    if [ -f "$converted_file" ]; then
      echo "Already processed in previous run: $file"
      already_processed_count=$((already_processed_count + 1))
      continue
    fi
    
    # Create the directory structure in the converted directory
    target_dir="'"$CONVERTED_DIR"'/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    
    # Check if the file is already compatible
    if is_compatible "$file"; then
      echo "Copying compatible file: $file"
      # Just copy the file without conversion
      cp "$file" "'"$CONVERTED_DIR"'/$rel_path"
      copied_count=$((copied_count + 1))
    else
      # Convert the file, preserving its path and original filename
      echo "Converting incompatible file: $file"
      if ffmpeg -i "$file" -acodec pcm_s16le -ar 44100 "'"$CONVERTED_DIR"'/$rel_path" 2>/dev/null; then
        # Update converted count
        converted_count=$((converted_count + 1))
      else
        echo "Failed to convert: $file"
      fi
    fi
  done
' sh {} +

# Report results
total_processed=$((converted_count + copied_count))
if [ "$total_processed" -eq 0 ] && [ "$already_processed_count" -eq 0 ]; then
    echo "No WAV files were found to process."
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
