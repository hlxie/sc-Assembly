##################################################################
# For sc-Assembly
# Scripts are provided for transparency
# Need be modified to fit other datasets
# Updated on Feb 14, 2022
# 
# Copyright (c) 2022, Haoling Xie, TangLab@PKU
# 
# Permission is hereby granted, free of charge, to 
# any person obtaining a copy of this software and 
# associated documentation files (the "Software"), 
# to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell copies 
# of the Software, and to permit persons to whom the Software 
# is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice 
# shall be included in all copies or substantial 
# portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH 
# THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###################################################################

#1. For the genomic assembly of single-cell HiFi data, we used Hiasm, Hicanu, Wtdbg2 to assembly with the following commands:
## Hiasm v0.16.0 was used
hifiasm \
-o asm_result \
-k 21 -t 20 \
*cell_reads.fastq.gz

## Hicanu v2.2 was used
canu \
-p asm -d asm_result \
genomeSize=3.1g \
maxMemory=900G \
maxThreads=16 \
useGrid=false \
-pacbio-hifi \
*cell_reads.fastq.gz

##We then used Purge_dups to identify primary contigs
minimap2 -I4G -xmap-pb asm.contigs.fasta ${cell}.fastq.gz | gzip -c - > ${cell}.paf.gz

pbcstat *.paf.gz

calcuts PB.stat > cutoffs 2>calcults.log

split_fa asm.contigs.fasta >asm.canu.contigs.sp.fasta

minimap2 -I4G -xasm5 -DP asm.canu.contigs.sp.fasta asm.canu.contigs.sp.fasta| gzip -c - > asm.canu.contigs.split.self.paf.gz

purge_dups  -2  -T cutoffs  -c PB.base.cov asm.canu.contigs.split.self.paf.gz > dups.bed 2> purge_dups.log

get_seqs -e dups.bed asm.contigs.fasta

## Wtdbg2 v2.5 was used
wtdbg2 \
-t 20 -k 0 \
-p 21 -AS 4 -s 0.5 \
-e 2 -K 0.05 \
-i *cell_reads.fastq.gz \
-fo asm_result

##we used wtpoa-cns to polish the initial assemblies of wtdbg2
wtpoa-cns -t 20 -i asm.ctg.lay.gz -fo asm.ctg.fa

minimap2 -t 16 -ax map-pb -r 2k asm.ctg.fa *cell_reads.fastq.gz |samtools sort -@ 16 > asm.ctg.bam

samtools view -F 0x900 asm.ctg.bam | wtpoa-cns  -t 16  -d asm.ctg.fa  -i  -  -fo asm.cns.fa


#2. For the genomic assembly of single-cell ONT data, we used Necat, Flye, Wtdbg2 to assembly with the following commands:
## Necat v0.0.1 was used

necat correct ecoli_config.txt
assemble ecoli_config.txt
bridge ecoli_config.txt

## Flye v2.9 was used
flye \
 --nano-raw *cell_reads.fastq.gz \
 --out-dir asm_flye \
 --genome-size 3.1g \
 --threads 20

## Wtdbg2 v2.5 was used
wtdbg2 \
-x ont -g3.1g -t20 --edge-min 2 --rescue-low-cov-edges \
-i *cell_reads.fastq.gz \
-fo asm_result

##we used wtpoa-cns to polish the initial assemblies of wtdbg2
wtpoa-cns -t 20 -i asm.ctg.lay.gz -fo asm.ctg.fa

minimap2 -t16  -ax map-pb -r2k asm.ctg.fa *cell_reads.fastq.gz | samtools sort -@ 16 > asm.ctg.bam

samtools view -F 0x900 asm.ctg.bam | wtpoa-cns -t 16 -d asm.ctg.fa  -i  - -fo asm.cns.fa





