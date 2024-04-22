#!/bin/bash
set -u

# goal: sam to bam, bam preprocess, leave out hamr command

if [ "$#" -lt 5 ]; then
echo "Missing arguments!"
echo "USAGE: fastq2hamr.sh <input bam file> <reference genome.fa> <filter.pl> <out directory> <sequence dictionary.dict>"
exit 1
fi

bam_in=$1
gno=$2
sort=$3
out=$4
dict=$5

bam_basename=$(basename "$bam_in")
bam_stem="${bam_basename%.*}"

#sorts the accepted hits
echo "[$bam_stem] sorting..."
samtools sort \
    -n $bam_in \
    -o $out/sorted.bam
echo "[$bam_stem] finished sorting"
echo ""

wait

#filter the accepted hits by uniqueness
echo "[$bam_stem] filter unique..."
samtools view \
    -h $out/sorted.bam \
    | perl $sort 1 \
    | samtools view -bS - \
    | samtools sort \
    -o $out/unique.bam
echo "[$bam_stem] finished filtering"
echo ""

wait

#adds read groups using picard, note the RG arguments are disregarded here
echo "[$bam_stem] adding/replacing read groups..."
gatk AddOrReplaceReadGroups \
    I=$out/unique.bam \
    O=$out/unique_RG.bam \
    RGID=1 \
    RGLB=xxx \
    RGPL=illumina_100se \
    RGPU=HWI-ST1395:97:d29b4acxx:8 \
    RGSM=sample
echo "[$bam_stem] finished adding/replacing read groups"
echo ""

wait

#reorder the reads using picard
echo "[$bam_stem] reordering..."
gatk --java-options "-Xmx2g -Djava.io.tmpdir=$out/tmp" ReorderSam \
    I=$out/unique_RG.bam \
    O=$out/unique_RG_ordered.bam \
    R=$gno \
    CREATE_INDEX=TRUE \
    SEQUENCE_DICTIONARY=$dict \
    TMP_DIR=$out/tmp
echo "[$bam_stem] finished reordering"
echo ""

wait

#splitting and cigarring the reads, using genome analysis tool kit
#note can alter arguments to allow cigar reads 
echo "[$bam_stem] getting split and cigar reads..."
gatk --java-options "-Xmx2g -Djava.io.tmpdir=$out/tmp" SplitNCigarReads \
    -R $gno \
    -I $out/unique_RG_ordered.bam \
    -O $out/unique_RG_ordered_splitN.bam \
    # -U ALLOW_N_CIGAR_READS
echo "[$bam_stem] finished splitting N cigarring"
echo ""

wait

#final resorting using picard
echo "[$bam_stem] resorting..."
gatk --java-options "-Xmx2g -Djava.io.tmpdir=$out/tmp" SortSam \
    I=$out/unique_RG_ordered_splitN.bam \
    O=$out/unique_RG_ordered_splitN.resort.bam \
    SORT_ORDER=coordinate
echo "[$bam_stem] finished resorting"
echo ""

wait