import sys
import gzip
import matplotlib.pyplot as plt

vcf_file = sys.argv[1]

vafs = []  # initialize

open_func = gzip.open if vcf_file.endswith(".gz") else open

with open_func(vcf_file, "rt") as f:
    for line in f:
        if line.startswith("#"):
            continue

        fields = line.strip().split("\t")

        # FORMAT and sample columns
        format_keys = fields[8].split(":")
        sample_values = fields[9].split(":")

        format_dict = dict(zip(format_keys, sample_values))

        # Extract AF (allele fraction)
        if "AF" in format_dict:
            try:
                af_values = format_dict["AF"].split(",")  # handle multiallelic
                for af in af_values:
                    vafs.append(float(af))
            except:
                continue

# Plot
plt.figure(figsize=(10, 6))
plt.hist(vafs, bins=30, edgecolor='black')
plt.xlabel("Variant Allele Frequency (VAF)")
plt.ylabel("Count")
plt.title("VAF Distribution")
plt.savefig("vaf_plot.png")
plt.show()
