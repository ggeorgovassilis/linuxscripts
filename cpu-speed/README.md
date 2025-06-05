#CPU speed

I'm using this script with my Linux Ryzen laptop to limit CPU frequency. It 

Usage:

```sh
cpu-speed.sh min|normal|high|max
cpu-speed.sh up|down
```

Frequency values are hard-coded, you probably should edit the script to match frequencies for your computer. I tried this only with the AMD pstate governor.

Tip: the script displays an overlay with the new frequency. I assigned the CRTL SHIFT + to `cpu-speed.sh` up and the CRTL SHIFT - hotkey to `cpu-speed.sh` down

