#!/bin/python3

import os
import xml.etree.ElementTree as ET
import shutil
import time
import argparse

# Instantiate the parser
parser = argparse.ArgumentParser()
parser.add_argument('--no_files', action='store_true')
parser.add_argument('--branch')
args = parser.parse_args()

start = time.time()
rootdir = "vrp/"
outdir = "vrp_build/"
branch = args.branch
includeFiles = not args.no_files
externalFiles = False

# Build vrp_build structure
print("Creating build structure...")

def rm_r(path):
    if os.path.isdir(path):
        shutil.rmtree(path)
    elif os.path.exists(path):
        os.remove(path)

rm_r(outdir)
os.mkdir(outdir)
os.mkdir(outdir + "server")
os.mkdir(outdir + "server/http")
shutil.copyfile(rootdir + "server/http/api.lua", outdir + "server/http/api.lua")
shutil.copytree(rootdir + "server/config", outdir + "server/config")

# Get files
print("Copying required files...")

files = []

tree = ET.parse(rootdir + "meta.xml")
root = tree.getroot()

for child in root.findall("script"):
    files.append(rootdir + child.attrib["src"])
    if child.attrib["type"] in ["client", "shared"]:
        child.set("cache", "false")

if externalFiles:
    # Copy maps
    shutil.copytree(rootdir + "files/maps", outdir + "files/maps")

    # Copy only files with <file> tag
    for child in root.findall("file"):
        filename = child.attrib["src"]
        if not os.path.exists(outdir + os.path.dirname(filename)):
            os.makedirs(outdir + os.path.dirname(filename))

        shutil.copyfile(rootdir + filename, outdir + filename)

    # Ignore <vrpfile> tags
    for child in root.findall("vrpfile"):
        root.remove(child)
else:
    if includeFiles:
        # Copy all files
        shutil.copytree(rootdir + "files", outdir + "files")
    else:
        print("Ignoring files.")

# Copy script files
for script in files:
    dest_path = os.path.join(outdir, script[len(rootdir):])
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    shutil.copyfile(script, dest_path)

# Save modified meta.xml
tree.write(outdir + "meta.xml")

print("Done. (took %.2f seconds)" % (time.time() - start))