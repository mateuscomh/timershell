# Timer Script

## Overview

This script is a terminal-based timer utility written in Bash. It allows users to set a countdown timer in seconds, minutes, or hours, with progress notifications displayed via `dunstify`. At the end of the timer, a notification is shown, and a sound is played to alert the user.

## Features

- **Customizable Timer**: Input the desired timer duration in seconds (`s`), minutes (`m`), or hours (`h`).
- **Progress Notifications**: Displays real-time progress updates using `dunstify` with a percentage-based progress bar.
- **Final Notification**: Notifies the user when the timer ends, showing a custom message.
- **Audio Alert**: Plays an alarm sound when the timer finishes.

## Prerequisites

To use this script, ensure the following dependencies are installed on your system:

- **Bash**: Required to execute the script.
- **Dunst**: For displaying notifications.
- **Paplay**: Part of the PulseAudio package, used for playing the alert sound.
- **Dunstify**: A notification utility compatible with `dunst`.

Install these dependencies using your package manager:

```bash
sudo apt install dunst pulseaudio-utils
```
## Usage
Running the Script
Save the script as timer.sh and make it executable:

```bash
chmod +x timer.sh
./timer.sh
```
## Steps
Input Timer Duration: Enter the timer duration using the format 10s (10 seconds), 5m (5 minutes), or 1h (1 hour). If no input is provided, the default is 10s.
Set a Custom Message: Enter the message to be displayed when the timer ends.
Monitor Progress: The script provides progress updates through dunstify notifications.
Final Alert: A notification and an alarm sound will indicate the timer's completion.

## License
This script is released under the MIT License. Feel free to use, modify, and distribute it as needed.
