# Latest Additions Script

given a input directory and output file, the script will create a list of most recently modified directories sorted from newest to oldest. it will also do the same for the immediate children directories. Output is formatted such that outputting as ```.txt``` or ```.md``` will just work.

## Example output

```bash
- Most Recently Modded Parent Dir
    - Most Recently Modded Child Dir
    - ...
    - Least Recently Modded Child Dir
- Least Recently Modded Parent Dir
    - Most Recently Modded Child Dir
    - ...
    - Least Recently Modded Child Dir
```

## Limiting Output

For larger lists of directories where not all dirs are needed in the output, the ```-t``` flag limits the output to the top N parent dirs.

For example, to output the 20 newest parent dirs and their children:

```bash
scan_dirs_by_date.sh -t 20 output.md
```
