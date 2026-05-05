#!/usr/bin/env python3
"""
Map Panaroo gene clusters to Bakta annotations and identify core virulence factors
"""

import pandas as pd
import glob
from Bio import SeqIO
import os
import argparse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Map Panaroo pangenome clusters to Bakta annotations'
    )
    parser.add_argument('--panaroo_dir', required=True,
                        help='Directory containing Panaroo output files')
    parser.add_argument('--bakta_dir', required=True,
                        help='Directory containing Bakta TSV annotation files')
    parser.add_argument('--output_dir', required=True,
                        help='Output directory for results')
    parser.add_argument('--core_threshold', type=float, default=0.95,
                        help='Core gene threshold (default: 0.95)')
    
    args = parser.parse_args()
    
    # Virulence keywords
    VIRULENCE_KEYWORDS = [
        'toxin', 'adhesin', 'invasion', 'hemolysin', 'protease',
        'secretion system', 'type ii', 'type iii', 'type iv', 'type vi',
        'pilus', 'fimbria', 'fimbrial', 'capsule', 'polysaccharide',
        'lipopolysaccharide', 'LPS', 'siderophore', 'immune',
        'resistance', 'biofilm', 'quorum', 'gingipain', 'leukotoxin',
        'virulence', 'pathogen', 'RTX', 'outer membrane protein',
        'heme', 'iron acquisition', 'transferase', 'efflux'
    ]
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # ========================================================================
    # STEP 1: Load Panaroo Results
    # ========================================================================
    
    print("=" * 80)
    print("STEP 1: Loading Panaroo results")
    print("=" * 80)
    
    panaroo_file = os.path.join(args.panaroo_dir, "gene_presence_absence.csv")
    print(f"Loading: {panaroo_file}")
    
    if not os.path.exists(panaroo_file):
        print(f"ERROR: File not found: {panaroo_file}")
        sys.exit(1)
    
    panaroo = pd.read_csv(panaroo_file, low_memory=False)
    
# Count genome columns (exclude metadata columns)
    metadata_cols = ['Gene', 'Non-unique Gene name', 'Annotation', 'No. isolates', 
                     'No. sequences', 'Avg sequences per isolate', 'Genome Fragment',
                     'Order within Fragment', 'Accessory Fragment', 
                     'Accessory Order with Fragment', 'QC', 'Min group size nuc',
                     'Max group size nuc', 'Avg group size nuc']
    genome_cols = [col for col in panaroo.columns if col not in metadata_cols]
    n_genomes = len(genome_cols)
    
    print(f"Number of genomes: {n_genomes}")
    print(f"Number of gene clusters: {len(panaroo)}")
    
    pangenome_fasta = os.path.join(args.panaroo_dir, "pan_genome_reference.fa")
    if os.path.exists(pangenome_fasta):
        print(f"Loading: {pangenome_fasta}")
        pangenome_seqs = {record.id: str(record.seq) 
                          for record in SeqIO.parse(pangenome_fasta, "fasta")}
        print(f"Loaded {len(pangenome_seqs)} sequences")
    else:
        print("Warning: pan_genome_reference.fa not found")
        pangenome_seqs = {}    
# ========================================================================
    # STEP 2: Load ALL Bakta Annotations
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("STEP 2: Loading Bakta annotations")
    print("=" * 80)
    
    print(f"Searching for TSV files in: {args.bakta_dir}")
    
    # Search for TSV files, but EXCLUDE inference and hypotheticals files
    pattern = os.path.join(args.bakta_dir, "*", "*.tsv")
    all_tsv_files = glob.glob(pattern)
    
    # Filter out inference and hypotheticals files - keep only main annotation files
    bakta_files = [
        f for f in all_tsv_files 
        if not f.endswith('.inference.tsv') 
        and not f.endswith('.hypotheticals.tsv')
    ]
    
    print(f"Found {len(bakta_files)} main Bakta annotation files (excluded {len(all_tsv_files) - len(bakta_files)} inference/hypotheticals files)")
    
    if len(bakta_files) > 0:
        print("\nExample file paths:")
        for f in bakta_files[:3]:
            print(f"  {f}")
    
    if len(bakta_files) == 0:
        print(f"ERROR: No Bakta main annotation files found!")
        print(f"Searched with pattern: {pattern}")
        sys.exit(1)
    
# Load all Bakta files (skip first 5 comment lines)
    all_bakta = []
    for i, file in enumerate(bakta_files, 1):
        if i % 10 == 0 or i == len(bakta_files):
            print(f"  Loading files: {i}/{len(bakta_files)}")
        try:
            # Bakta format: 5 comment lines, then header line (with #), then data
            df = pd.read_csv(file, sep='\t', skiprows=5)  # Changed from 6 to 5
            
            # Clean column names (remove # and whitespace)
            df.columns = df.columns.str.replace('#', '').str.strip()
            
            # Debug: print columns from first file
            if i == 1:
                print(f"  First file columns: {df.columns.tolist()}")
            
            # Use the subdirectory name as genome identifier
            df['source_genome'] = os.path.basename(os.path.dirname(file))
            all_bakta.append(df)
        except Exception as e:
            print(f"    WARNING: Could not load {file}: {e}")
    
    if len(all_bakta) == 0:
        print("ERROR: No Bakta files could be loaded!")
        sys.exit(1)
    
    # Concatenate all dataframes
    bakta_all = pd.concat(all_bakta, ignore_index=True)
    
    print(f"\nTotal Bakta annotations loaded: {len(bakta_all)}")
    print(f"Columns: {bakta_all.columns.tolist()}")
    
    # Check if we have the expected columns
    if 'Locus Tag' not in bakta_all.columns:
        print("\nERROR: 'Locus Tag' column not found!")
        print("This might mean skiprows is incorrect.")
        print(f"Available columns: {bakta_all.columns.tolist()}")
        sys.exit(1)
    
    print(f"Unique locus tags: {bakta_all['Locus Tag'].nunique()}")
    print(f"Unique source genomes: {bakta_all['source_genome'].nunique()}")
    
    # ========================================================================
    # STEP 3: Map Panaroo Clusters to Bakta Annotations
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("STEP 3: Mapping Panaroo clusters to Bakta annotations")
    print("=" * 80)
    
    # CRITICAL: Verify bakta_all exists and has data
    print(f"\n*** VALIDATION: Checking Bakta data ***")
    print(f"  bakta_all shape: {bakta_all.shape}")
    print(f"  bakta_all rows: {len(bakta_all)}")
    print(f"  bakta_all columns: {list(bakta_all.columns)}")
    print(f"  Sample Bakta products: {bakta_all['Product'].dropna().head(5).tolist()}")
    
    def extract_locus_tags(row):
        """Extract all locus tags from a Panaroo row"""
        locus_tags = []
        for col in panaroo.columns[14:]:
            if pd.notna(row[col]) and row[col] != '':
                tags = str(row[col]).split('\t')
                locus_tags.extend(tags)
        return locus_tags
    
    def get_consensus_annotation(bakta_subset):
        """Get consensus annotation from multiple instances"""
        if bakta_subset.empty:
            return {
                'Product': None,
                'Gene': None,
                'DbXrefs': None,
                'n_annotated': 0,
                'product_variants': 0,
                'source': 'missing'  # Track if annotation is missing
            }
        
        product_counts = bakta_subset['Product'].value_counts()
        most_common_product = product_counts.index[0] if len(product_counts) > 0 else None
        
        gene_name = None
        if 'Gene' in bakta_subset.columns:
            genes = bakta_subset['Gene'].dropna()
            if len(genes) > 0:
                gene_name = genes.mode()[0] if len(genes) > 0 else genes.iloc[0]
        
        dbxrefs = None
        if 'DbXrefs' in bakta_subset.columns:
            dbxrefs_series = bakta_subset['DbXrefs'].dropna()
            if len(dbxrefs_series) > 0:
                dbxrefs = dbxrefs_series.iloc[0]
        
        return {
            'Product': most_common_product,
            'Gene': gene_name,
            'DbXrefs': dbxrefs,
            'n_annotated': len(bakta_subset),
            'product_variants': len(bakta_subset['Product'].unique()),
            'source': 'bakta'  # Mark as coming from Bakta
        }
    
    # Process all clusters
    cluster_annotations = []
    
    # Tracking statistics
    bakta_matched = 0
    bakta_missing = 0
    locus_tags_not_found = []
    
    print(f"Processing {len(panaroo)} gene clusters...")
    for idx, row in panaroo.iterrows():
        if idx % 500 == 0:
            print(f"  Processed {idx}/{len(panaroo)} clusters...")
        
        cluster = row['Gene']
        panaroo_annotation = row.get('Annotation', '')
        
        # Extract locus tags
        locus_tags = extract_locus_tags(row)
        
        # CRITICAL: Query bakta_all for these locus tags
        bakta_subset = bakta_all[bakta_all['Locus Tag'].isin(locus_tags)]
        
        # Get Bakta annotations
        consensus = get_consensus_annotation(bakta_subset)
        
        # Track success/failure
        if consensus['source'] == 'bakta':
            bakta_matched += 1
        else:
            bakta_missing += 1
            if idx < 10:  # Save first 10 examples for debugging
                locus_tags_not_found.extend(locus_tags[:2])
        
        n_instances = len(locus_tags)
        prevalence = n_instances / n_genomes
        
        # Store both Panaroo and Bakta annotations for comparison
        cluster_annotations.append({
            'Panaroo_Cluster': cluster,
            'Panaroo_Annotation': panaroo_annotation,  # Keep for reference
            'Bakta_Product': consensus['Product'],      # PRIMARY - from Bakta
            'Product': consensus['Product'],             # PRIMARY - from Bakta (main column)
            'Gene': consensus['Gene'],
            'DbXrefs': consensus['DbXrefs'],
            'n_instances': n_instances,
            'prevalence': prevalence,
            'n_annotated': consensus['n_annotated'],
            'product_variants': consensus['product_variants'],
            'annotation_source': consensus['source'],
            'has_sequence': cluster in pangenome_seqs
        })
    
    pangenome_annotated = pd.DataFrame(cluster_annotations)
    print(f"Successfully processed {len(pangenome_annotated)} clusters")
    
    # ========================================================================
    # VALIDATION: Check annotation sources
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("*** ANNOTATION SOURCE VALIDATION ***")
    print("=" * 80)
    
    print(f"\nTotal gene clusters: {len(pangenome_annotated)}")
    print(f"  ✓ Matched to Bakta: {bakta_matched} ({100*bakta_matched/len(pangenome_annotated):.1f}%)")
    print(f"  ✗ Missing Bakta: {bakta_missing} ({100*bakta_missing/len(pangenome_annotated):.1f}%)")
    
    # Show examples of Bakta-annotated genes
    bakta_annotated = pangenome_annotated[pangenome_annotated['annotation_source'] == 'bakta']
    if len(bakta_annotated) > 0:
        print(f"\n✓ Example Bakta annotations (first 5):")
        for idx, row in bakta_annotated.head(5).iterrows():
            print(f"  {row['Panaroo_Cluster']}: {row['Bakta_Product']}")
    
    # Show genes missing Bakta annotations
    missing_bakta = pangenome_annotated[pangenome_annotated['annotation_source'] == 'missing']
    if len(missing_bakta) > 0:
        print(f"\n✗ WARNING: {len(missing_bakta)} genes missing Bakta annotations")
        print(f"  First 5 examples:")
        for idx, row in missing_bakta.head(5).iterrows():
            print(f"  {row['Panaroo_Cluster']}: Panaroo says '{row['Panaroo_Annotation']}'")
        
        # Check if locus tags exist in Bakta
        if locus_tags_not_found:
            print(f"\n  Sample locus tags not found in Bakta:")
            for tag in locus_tags_not_found[:5]:
                print(f"    {tag}")
            
            # See if these locus tags exist at all
            sample_tag = locus_tags_not_found[0]
            exists = sample_tag in bakta_all['Locus Tag'].values
            print(f"\n  Does '{sample_tag}' exist in bakta_all? {exists}")
    
    # Compare Panaroo vs Bakta annotations
    print(f"\n*** ANNOTATION COMPARISON ***")
    both_present = pangenome_annotated[
        pangenome_annotated['Panaroo_Annotation'].notna() & 
        pangenome_annotated['Bakta_Product'].notna()
    ]
    
    if len(both_present) > 0:
        # Check if they're different
        different = both_present[
            both_present['Panaroo_Annotation'] != both_present['Bakta_Product']
        ]
        print(f"  Genes with both annotations: {len(both_present)}")
        print(f"  Panaroo ≠ Bakta: {len(different)} ({100*len(different)/len(both_present):.1f}%)")
        
        if len(different) > 0:
            print(f"\n  Examples where Panaroo ≠ Bakta (first 3):")
            for idx, row in different.head(3).iterrows():
                print(f"    {row['Panaroo_Cluster']}:")
                print(f"      Panaroo: {row['Panaroo_Annotation']}")
                print(f"      Bakta:   {row['Bakta_Product']} ← USING THIS")
    
    print("\n" + "=" * 80)
    print("✓ Validation complete - using Bakta annotations as primary source")
    print("=" * 80)

    # ========================================================================
    # STEP 4: Classify Genes
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("STEP 4: Classifying genes")
    print("=" * 80)
    
    pangenome_annotated['classification'] = pd.cut(
        pangenome_annotated['prevalence'],
        bins=[0, 0.15, args.core_threshold, 1.0],
        labels=['Cloud', 'Shell', 'Core'],
        include_lowest=True
    )
    
    print(f"\nGene classification:")
    print(pangenome_annotated['classification'].value_counts())
    print(f"\nCore gene threshold: {args.core_threshold} ({int(args.core_threshold * n_genomes)}/{n_genomes} genomes)")
    
    output_file = os.path.join(args.output_dir, "pangenome_annotated.csv")
    pangenome_annotated.to_csv(output_file, index=False)
    print(f"\nSaved: {output_file}")
    
    # ========================================================================
    # STEP 5: Extract Core Genes
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("STEP 5: Extracting core genes")
    print("=" * 80)
    
    core_genes = pangenome_annotated[pangenome_annotated['classification'] == 'Core'].copy()
    print(f"Core genes: {len(core_genes)}")
    
    output_file = os.path.join(args.output_dir, "core_genes.csv")
    core_genes.to_csv(output_file, index=False)
    print(f"Saved: {output_file}")
    
    # ========================================================================
    # STEP 6: Identify Virulence Factors
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("STEP 6: Identifying virulence factors")
    print("=" * 80)
    
    virulence_pattern = '|'.join(VIRULENCE_KEYWORDS)
    
    all_virulence = pangenome_annotated[
        pangenome_annotated['Product'].str.contains(
            virulence_pattern, 
            case=False, 
            na=False
        )
    ].copy()
    
    print(f"Total virulence-related genes: {len(all_virulence)}")
    
    core_virulence = core_genes[
        core_genes['Product'].str.contains(
            virulence_pattern, 
            case=False, 
            na=False
        )
    ].copy()
    
    print(f"Core virulence factors: {len(core_virulence)}")
    
    def categorize_virulence(product):
        """Categorize virulence mechanism"""
        if pd.isna(product):
            return 'Unknown'
        
        product_lower = str(product).lower()
        
        if any(term in product_lower for term in ['toxin', 'hemolysin', 'cytolysin', 'rtx']):
            return 'Toxin/Cytotoxin'
        elif any(term in product_lower for term in ['adhesin', 'pilus', 'fimbria', 'adherence']):
            return 'Adhesion/Colonization'
        elif any(term in product_lower for term in ['secretion', 'type ii', 'type iii', 'type iv', 'type vi']):
            return 'Secretion System'
        elif any(term in product_lower for term in ['protease', 'peptidase', 'gingipain']):
            return 'Protease/Degradation'
        elif any(term in product_lower for term in ['capsule', 'polysaccharide', 'exopolysaccharide', 'lps']):
            return 'Capsule/Surface'
        elif any(term in product_lower for term in ['siderophore', 'iron', 'heme']):
            return 'Iron Acquisition'
        elif any(term in product_lower for term in ['resistance', 'efflux', 'antibiotic']):
            return 'Antimicrobial Resistance'
        elif any(term in product_lower for term in ['biofilm', 'quorum']):
            return 'Biofilm/Quorum Sensing'
        else:
            return 'Other'
    
    core_virulence['Mechanism'] = core_virulence['Product'].apply(categorize_virulence)
    all_virulence['Mechanism'] = all_virulence['Product'].apply(categorize_virulence)
    
    print(f"\nCore virulence factors by mechanism:")
    print(core_virulence['Mechanism'].value_counts())
    
    output_file = os.path.join(args.output_dir, "all_virulence_factors.csv")
    all_virulence.to_csv(output_file, index=False)
    print(f"\nSaved all virulence factors: {output_file}")
    
    output_file = os.path.join(args.output_dir, "core_virulence_factors.csv")
    core_virulence.to_csv(output_file, index=False)
    print(f"Saved core virulence factors: {output_file}")
    
    # ========================================================================
    # STEP 7: Summary Report
    # ========================================================================
    
    print("\n" + "=" * 80)
    print("SUMMARY REPORT")
    print("=" * 80)
    
    print(f"\nGenomes analyzed: {n_genomes}")
    print(f"Total gene clusters: {len(pangenome_annotated)}")
    print(f"  - Core genes (≥{int(args.core_threshold*100)}%): {len(core_genes)}")
    print(f"  - Shell genes: {len(pangenome_annotated[pangenome_annotated['classification'] == 'Shell'])}")
    print(f"  - Cloud genes: {len(pangenome_annotated[pangenome_annotated['classification'] == 'Cloud'])}")
    
    print(f"\nVirulence factors:")
    print(f"  - Total: {len(all_virulence)}")
    print(f"  - Core: {len(core_virulence)}")
    print(f"  - Accessory: {len(all_virulence) - len(core_virulence)}")
    
    if len(core_virulence) > 0:
        print(f"\nTop 10 core virulence factors:")
        top_virulence = core_virulence.nsmallest(10, 'prevalence', keep='all')[
            ['Panaroo_Cluster', 'Gene', 'Product', 'Mechanism', 'prevalence']
        ]
        print(top_virulence.to_string(index=False))
    
    print(f"\nAll results saved to: {args.output_dir}/")
    print("\n" + "=" * 80)
    print("Analysis complete!")
    print("=" * 80)

if __name__ == "__main__":
    main()
