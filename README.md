# SP404 MK2 WAV File Converter

This script helps convert WAV audio files to be compatible with the Roland SP404 MK2 sampler. It creates a complete collection of SP404 MK2-compatible files in a single location while preserving your original files and folder structure.

> 📝 **For a detailed writeup about why I created this tool and how it works, check out my [blog post on the SP404 MK2 WAV Converter](https://sebpatron.com/sp404mk2-wav-converter/).**

## What This Script Does

- Presents a folder selection dialog to choose your samples directory
- Scans for WAV files in the selected folder and all subfolders
- Checks each file for compatibility with the SP404 MK2
- Places ALL files in a "converted" subdirectory:
  - Compatible files are simply copied as-is
  - Incompatible files are converted to a compatible format
- Preserves your original folder structure in the "converted" directory
- Preserves your original files completely untouched
- Intelligently skips files that have already been processed in previous runs

## SP404 MK2 Compatibility Requirements

The Roland SP404 MK2 has specific requirements for WAV files:

- **Bit Depth**: Must be 16-bit or 24-bit
- **Sample Rates**: Must be one of the following:
  - 16 kHz
  - 22.05 kHz
  - 32 kHz
  - 44.1 kHz (recommended)
  - 48 kHz
  - 88.2 kHz
  - 96 kHz
  - 176.4 kHz
  - 192 kHz

Files that don't meet these requirements will not play correctly on the SP404 MK2 or may not be recognized at all.

## Safe for Your Original Files

**This script never modifies your original files.** Instead, it creates a "converted" subdirectory that contains a complete mirror of your sample library with all files guaranteed to be compatible with the SP404 MK2. This makes it easy to copy your entire library to your sampler while ensuring your original samples remain untouched.

## Prerequisites

Before using this script, you need to install:

1. **Homebrew** - The package manager for macOS
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **FFmpeg** - The audio/video conversion tool
   ```
   brew install ffmpeg
   ```

## How to Use

1. Download the `convert-wavs.sh` script
2. Make it executable:
   ```
   chmod +x convert-wavs.sh
   ```
3. Run the script:
   ```
   ./convert-wavs.sh
   ```
4. When prompted, select the folder containing your WAV samples
5. The script will process all WAV files
6. Find your complete set of SP404 MK2-compatible files in the "converted" subdirectory

## How It Works

1. **Folder Selection**: Uses AppleScript to show a native macOS folder selection dialog
2. **Smart Processing**: For each WAV file, the script:
   - Checks if the file has already been processed in a previous run (and skips if it has)
   - Uses `ffprobe` to analyze the audio format
   - Determines if the file is already compatible with the SP404 MK2
3. **File Handling**:
   - Compatible files are copied directly to the "converted" directory with no changes
   - Incompatible files are converted to 16-bit, 44.1kHz PCM WAV format
   - All files maintain their original paths and filenames within the converted directory
4. **Detailed Reporting**: After processing, the script provides:
   - Count of incompatible files converted in the current run
   - Count of compatible files copied in the current run
   - Count of files that were already processed in previous runs
   - Location of all processed files

## Troubleshooting

- **Permission Denied**: Make sure the script is executable (`chmod +x convert-wavs.sh`)
- **Command Not Found**: Ensure FFmpeg is installed (`brew install ffmpeg`)
- **No Files Processed**: Check that your directory contains WAV files

## License

This script is provided as-is under the MIT License. Feel free to modify and distribute as needed. 