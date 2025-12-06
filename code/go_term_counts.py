#!/usr/bin/env python3
#--------------------------------------------------------------
## GO Term Trinity Gene Counts
## Purpose: This script reads multiple Trinotate annotation reports and counts the number of unique Trinity gene IDs associated with each GO term defined in a separate immune-system- and longevity-associated GO term table.
## Usage: python3 go_term_counts.py <Trinotate1.tsv> <Trinotate2.tsv> <Trinotate3.tsv> <go_terms.tsv>
## Author: Rebecca Choi
## Date Created: November 2025
#--------------------------------------------------------------
import sys
import csv
from pathlib import Path

## Load GO Terms
def load_go_terms(go_file):
    go_rows = []
    with open(go_file) as f:
        reader = csv.reader(f, delimiter="\t")
        next(reader)  # skip header
        for row in reader:
            if len(row) < 4:
                continue
            pathway = row[0].strip()
            subcat = row[1].strip()
            go_id = row[2].strip()
            go_name = row[3].strip()
            if go_id.startswith("GO:"):
                go_rows.append((pathway, subcat, go_id, go_name))
    return go_rows

## Parse GO Annotation Fields
# Extract GO IDs from Trinotate GO annotation fields
def parse_go_field(field):
    if not field or field == ".":
        return set()
    ids = set()
    for chunk in field.split("`"):
        parts = chunk.split("^")
        if parts and parts[0].startswith("GO:"):
            ids.add(parts[0])
    return ids

## Count Unique Trinity Gene IDs per GO Term
def count_genes(trino_path, go_ids):
    result = {go: set() for go in go_ids}
    with open(trino_path, newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            gene = row.get("#gene_id", "").strip()
            if not gene:
                continue
            fields = [
                row.get("gene_ontology_BLASTX", ""),
                row.get("gene_ontology_BLASTP", ""),
                row.get("gene_ontology_Pfam", "")
            ]
            found = set()
            for ffield in fields:
                found |= parse_go_field(ffield)
            for go in found:
                if go in result:
                    result[go].add(gene)
    return result

## Main 
def main():
    if len(sys.argv) < 5:
        print("Usage: python3 go_term_counts.py <Trinotate1.tsv> <Trinotate2.tsv> <Trinotate3.tsv> <go_terms.tsv>")
        sys.exit(1)
    *trinotate_files, go_file = sys.argv[1:]
    trinotate_paths = [Path(p) for p in trinotate_files]
    species_labels = [p.stem for p in trinotate_paths]
    go_rows = load_go_terms(go_file)
    go_ids = {row[2] for row in go_rows}
    all_counts = [
        count_genes(path, go_ids) for path in trinotate_paths
    ]
    output = Path("go_term_counts.tsv")
    with open(output, "w") as out:
        header = ["Pathway", "Subcategory", "GO_ID", "GO_Name"] + species_labels
        out.write("\t".join(header) + "\n")
        for pathway, subcat, go_id, go_name in go_rows:
            row = [pathway, subcat, go_id, go_name]
            for species_dict in all_counts:
                row.append(str(len(species_dict.get(go_id, set()))))
            out.write("\t".join(row) + "\n")
    print(f"Done. Wrote: {output}")

if __name__ == "__main__":
    main()
