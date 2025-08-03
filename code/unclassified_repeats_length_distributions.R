library(styler)
library(tidyverse)

gff3_file <- "../repetitive_elements/Arctic_Surf_Clam_Cleaned.out.gff3"
fa_file   <- "../repetitive_elements/arcticsurfclam_unclassified_seqs.fa"

#Obtain TE family names in FASTA headers of the unclassified TE sequences
unclassified <- read_lines(fa_file) %>%
  keep(~ str_starts(.x, ">")) %>%
  str_remove("^>") %>%
  str_extract("^[^# ]+")

#Import GFF3 file
gff <- read_tsv(gff3_file,
  comment     = "#",
  col_names   = c("seqid","source","type","start","end","score","strand","phase","attributes"),
  col_types   = cols(
    seqid      = col_character(),
    source     = col_character(),
    type       = col_character(),
    start      = col_integer(),
    end        = col_integer(),
    score      = col_character(),
    strand     = col_character(),
    phase      = col_character(),
    attributes = col_character()
  )
)

#Extract TE name from "Target" part of attributes column, and make it lowercase to match the names in FASTA headers
gff <- gff %>%
  mutate(repeat_family = str_extract(attributes, "(?<=Target=)[^ ]+") %>%
           str_to_lower())

#Keep hits that match in the unclassified list
gff2 <- gff %>%
  filter(!is.na(repeat_family) & repeat_family %in% unclassified) %>%
  mutate(length = end - start + 1)

#Summarize per TE family
te_summary <- gff2 %>%
  group_by(repeat_family) %>%
  summarise(
    count       = n(),
    total_bases = sum(length),
    median_size = median(length),
    mean_size   = mean(length),
    .groups     = "drop"
  ) %>%
  arrange(desc(total_bases))

write_csv(te_summary,"arcticsurfclam_unclassified_stats.csv")


