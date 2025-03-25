# SP404 MK2 WAV File Converter

This script helps convert WAV audio files to be compatible with the Roland SP404 MK2 sampler. It automatically detects incompatible files and converts only those that need conversion, preserving your folder structure.

## What This Script Does

- Presents a folder selection dialog to choose your samples directory
- Scans for WAV files in the selected folder and all subfolders
- Checks each file for compatibility with the SP404 MK2
- Converts only incompatible files to the correct format (16-bit, 44.1kHz)
- Preserves your original folder structure
- Replaces incompatible files with compatible versions

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

## ⚠️ IMPORTANT: Backup Your Files First ⚠️

**This script will replace your original incompatible WAV files with converted versions.**

It is strongly recommended to create a backup of your sample library before running this script. While the script only modifies incompatible files, it's always better to be safe than sorry.

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
5. The script will process all WAV files and convert only those that are incompatible

## How It Works

1. **Folder Selection**: Uses AppleScript to show a native macOS folder selection dialog
2. **Compatibility Check**: For each WAV file, the script:
   - Uses `ffprobe` to analyze the audio format
   - Checks if the bit depth is compatible (16-bit or 24-bit)
   - Verifies the sample rate is one of the supported rates
   - Skips files that are already compatible
3. **Conversion**: For incompatible files, the script:
   - Creates a temporary directory structure matching your original folders
   - Converts the file to 16-bit, 44.1kHz PCM WAV format
   - Preserves the original file path
4. **Replacement**: After conversion, the script:
   - Copies the converted files back to their original locations
   - Cleans up the temporary conversion directory

## Troubleshooting

- **Permission Denied**: Make sure the script is executable (`chmod +x convert-wavs.sh`)
- **Command Not Found**: Ensure FFmpeg is installed (`brew install ffmpeg`)
- **No Files Converted**: Your files may already be compatible with the SP404 MK2

## License

This script is provided as-is under the MIT License. Feel free to modify and distribute as needed. 