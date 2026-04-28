#!/usr/bin/env python3
import sys
import matplotlib.pyplot as plt

vcf_file = sys.argv[1]
vafs = []

with open(vcf_file, 'r') as f:
    for line in f:
        if line.startswith('#'):
            continue
        # Mutect2 usually puts AF in the sample format field
        # We will parse the AF values specifically
        parts = line.split('\t')
        info = parts[7]
        if 'AF=' in info:
            # Extract AF value
            try:
                af = float(info.split('AF=')[1].split(';')[0].split(',')[0])
                vafs.append(af)
            except:
                continue

plt.figure(figsize=(10, 6))
plt.hist(vafs, bins=30, color='skyblue', edgecolor='black')
plt.title('Somatic Variant Allele Frequency (VAF) Distribution')
plt.xlabel('Allele Frequency')
plt.ylabel('Count')
plt.grid(axis='y', alpha=0.75)
plt.savefig('vaf_distribution.png')
