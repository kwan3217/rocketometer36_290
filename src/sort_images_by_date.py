import fnmatch
import os
import sys
import time
from collections.abc import Iterable


def find_images(
    root: str,
    patterns: list[str],
    ignore_dirs: set[str] = None,
    case_sensitive: bool = False
) -> Iterable[str]:
    """
    Recursively find files matching any of the given wildcard patterns under `root`.

    Yields full paths one at a time (memory efficient for huge collections).

    Parameters:
    - root: Starting directory (e.g., os.path.expanduser('~'))
    - patterns: List of glob patterns, e.g. ['*.jpg', '*.jpeg', '*.png', '*.webp']
    - ignore_dirs: Set of directory names or full paths to completely skip.
                  Can mix names (e.g. '__pycache__') and full paths (e.g. '/home/user/.cache')
    - case_sensitive: If False (default), matching is case-insensitive

    Example:
        for path in find_images('~', ['*.jpg', '*.jpeg', '*.png'], ignore_dirs={'.git', '__pycache__', '/home/user/.thumbnails'}):
            print(path)
    """
    if ignore_dirs is None:
        ignore_dirs = set()

    # Normalize patterns for case-insensitive matching if needed
    if not case_sensitive:
        patterns = [p.lower() for p in patterns]

    # Expand and normalize root
    root = os.path.abspath(os.path.expanduser(root))

    # Convert ignore_dirs: keep full paths as-is, extract basenames for name-based ignores
    ignore_names = {os.path.basename(p.rstrip(os.sep)) for p in ignore_dirs if not p.startswith('/')}
    ignore_full_paths = {os.path.abspath(os.path.expanduser(p)) for p in ignore_dirs if p.startswith('/')}

    with os.scandir(root) as it:
        for entry in it:
            try:
                full_path = entry.path

                # Skip ignored full paths
                if full_path in ignore_full_paths:
                    continue

                if entry.is_dir(follow_symlinks=False):
                    # Skip ignored directory names
                    if entry.name in ignore_names:
                        continue

                    # Recurse
                    yield from find_images(full_path, patterns, ignore_dirs, case_sensitive)

                elif entry.is_file(follow_symlinks=False):
                    name = entry.name if case_sensitive else entry.name.lower()
                    if any(fnmatch.fnmatch(name, pat) for pat in patterns):
                        yield full_path

            except PermissionError:
                # Silently skip directories/files we can't access
                continue
            except OSError:
                # Handle broken symlinks, etc.
                continue

data = []
for i_path,path in enumerate(find_images(root="/home/chrisj",
                       patterns=["*.jpg","*.jpe","*.jpeg"],
                       ignore_dirs={"/home/chrisj/docker_compose","Cardserver","DigiQuillMain",".thumbnails"},
                       case_sensitive=False)):
    try:
        st = os.stat(path)
        data.append((st.st_mtime, st.st_size, path))
    except FileNotFoundError:
        pass  # Skip if file doesn't exist anymore
    except Exception as e:
        print(f"Error stat'ing {path}: {e}", file=sys.stderr)  # Optional: log other errors
    if i_path%100==0:
        print(".",end='')
        if i_path%10000==0 and i_path>0:
            print(f"{i_path:6d}")

n_paths=len(data)
print(f"Total of {n_paths} files")

print("sorting")
# Sort by mtime (ascending)
data.sort(key=lambda x: x[0])
print("Done sorting")

# Output: ISO-like date, size in bytes, path

with open("sorted_jpg_list.csv","wt") as ouf:
    for mtime, size, path in data:
        # Use ISO 8601 format for consistency: YYYY-MM-DDTHH:MM:SS
        dt = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(mtime))
        line=f'{dt}, {size:9d}, "{path}"'
        print(line,file=ouf)

print(f"Done!")
