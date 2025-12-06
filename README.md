## Comparative Genomics, Transcriptomics, and Evolutionary Analysis of Three Marine Bivalves

### Project Partners
* University of Guelph
* Fisheries and Oceans Canada Bedford Institute of Oceanography

### Project Description
This repository contains analyses supporting a comparative genomics, transcriptomics, and evolutionary study of three species of marine bivalves:

- **Greenland cockle (*Serripes groenlandicus*)**  
- **Arctic surfclam (*Mactromeris polynyma*)**  
- **Northern propeller clam (*Cyrtodaria siliqua*)**  

Tissue samples were provided by the Department of Fisheries and Oceans Maritimes Region and industry partners, which were then sequenced by the [Canadian Biogenomes Project](https://earthbiogenome.ca/).  

### Project Objectives  
1)	Assess genome assembly quality and completeness among the three bivalve species using BUSCO and BlobToolKit snail plots
2)	Assemble and annotate draft transcriptomes for each species using Trinity and Trinotate from RNA-seq data 
3)	Examine transposable element content and diversity among genome assemblies using a modified Earl Grey pipeline and RepeatMasker Kimura-2-Parameter (K2P) divergence analyses to estimate relative transposable element ages
4)	Assess gene representation across immunity- and longevity-associated GO terms using Trinotate transcriptome annotations and custom Python scripts
5)	Infer phylogenomic relationships using OrthoFinder, including DIAMOND all-versus-all searches, MAFFT alignment, FastTree2 gene trees, and STAG/STRIDE species tree reconstruction
6)	Construct synteny plots with R package syntenyPlotteR for identifying conserved genomic regions among species 
7)	Incorporate Hi-C data to improve genome scaffolding and investigate chromosomal structure using tools such as Juicebox

### Analytical Tools and Versions
For reproducibility, major tools include:

- **BUSCO** v5.8.2  
- **BlobToolKit** v4.4.6  
- **Earl Grey** (modified pipeline)  
- **RepeatMasker**  
- **Trinity** 
- **TransDecoder**  
- **DIAMOND** v2.1.10  
- **HMMER** 
- **SignalP** v6.0  
- **TMHMM** v2.0c  
- **Trinotate** 
- **OrthoFinder** v2.5.5  
- **MAFFT** v7.526  
- **FastTree2**  
