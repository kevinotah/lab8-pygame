# Runnable Assembly Version (Linux/WSL)

This folder contains a runnable x86_64 assembly simulation derived from the behavior in [main.py](../main.py):

- same square population profile: 5 large, 10 medium, 30 small
- flee/chase behavior based on nearby square size
- wrapping at screen bounds
- collision-based consumption and growth
- aging/lifespan-based respawn

It is implemented as a terminal simulation (no pygame window), so it is fully runnable with a standard C toolchain.

## Files

- [main_runnable_linux.S](main_runnable_linux.S): x86_64 GNU assembly source (Intel syntax)
- [build_linux.sh](build_linux.sh): Linux/WSL build script
- [run_linux.sh](run_linux.sh): Linux/WSL run script
- [do_everything_windows.ps1](do_everything_windows.ps1): Windows one-command orchestrator (uses WSL)

## Build and Run

On Linux/WSL:

```bash
sudo apt update
sudo apt install -y build-essential
bash assembly/build_linux.sh
bash assembly/run_linux.sh
```

On Windows (PowerShell, via WSL):

```powershell
powershell -ExecutionPolicy Bypass -File assembly/do_everything_windows.ps1
```

You should see periodic frame logs such as:

```text
frame=0 alive=45 s0=(123.45, 67.89) size=25
...
done: frames=600 alive=0
```

## Notes

- This is a runnable assembly simulation, not a direct pygame UI clone.
- The main logic was prioritized over text rendering/windowing to keep the executable assembly target practical.
