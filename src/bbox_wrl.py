import numpy as np
import re
import sys

if len(sys.argv) != 2:
    print("Usage: python bbox_wrl.py yourfile.wrl")
    sys.exit(1)

file_path = sys.argv[1]

with open(file_path, 'r') as f:
    content = f.read()

# Normalize whitespace and remove commas/newlines for easier regex
normalized = re.sub(r'[\n\r,]', ' ', content)
normalized = re.sub(r'\s+', ' ', normalized)

# Find all floating-point numbers in 'point [' ... ']'
match = re.search(r'point\s*\[\s*(.*?)\s*\]', normalized, re.DOTALL)
if not match:
    print("No point field found (not a simple mesh?)")
    sys.exit(1)

numbers = re.findall(r'[-+]?\d*\.\d+(?:[eE][-+]?\d+)?|[-+]?\d+', match.group(1))
if len(numbers) % 3 != 0:
    print("Invalid number of coordinates")
    sys.exit(1)

vertices = np.array(numbers, dtype=float).reshape(-1, 3)

# Compute axis-aligned bounding box
min_coords = vertices.min(axis=0)
max_coords = vertices.max(axis=0)

print("Bounding Box:")
print(f"Min: {min_coords}")
print(f"Max: {max_coords}")
print(f"Size: {max_coords - min_coords}")
print(f"Center: {(min_coords + max_coords) / 2}")