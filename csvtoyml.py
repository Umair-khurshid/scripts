#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import csv
import os
import sys
from pathlib import Path
import yaml


def main():
    # Validate arguments
    if len(sys.argv) != 3:
        print("Usage: {} input.csv output.yml".format(sys.argv[0]))
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Validate input file exists
    if not os.path.isfile(input_file):
        print("Error: File '{}' does not exist!".format(input_file))
        sys.exit(1)

    # Validate output file doesn't exist
    if os.path.exists(output_file):
        print("Error: File '{}' already exists!".format(output_file))
        sys.exit(1)

    # Read and process CSV file
    try:
        with open(input_file, 'r', encoding='utf-8') as file:
            # Use DictReader to automatically handle headers
            reader = csv.DictReader(file)
            content = list(reader)
            
    except Exception as e:
        print("Error reading CSV file: {}".format(e))
        sys.exit(1)

    # Check if we have data
    if not content:
        print("No data found in file {}".format(input_file))
        sys.exit(1)

    # Write YAML file
    try:
        with open(output_file, 'w', encoding='utf-8') as yfile:
            yaml.dump(content, yfile, default_flow_style=False, allow_unicode=True)
            
    except Exception as e:
        print("Error writing YAML file: {}".format(e))
        # Clean up partial output file
        if os.path.exists(output_file):
            os.remove(output_file)
        sys.exit(1)

    print("Conversion successful: {} -> {}".format(input_file, output_file))
    print("{} rows converted".format(len(content)))


if __name__ == "__main__":
    main()