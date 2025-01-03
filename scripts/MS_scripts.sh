#!/bin/bash
#Flye
~/miniconda3/bin/flye --genome-size 2.6g --pacbio-raw MS_1kb.fastq --threads 96 --asm-coverage 50 -o MS

# Pilon
/opt/software/anaconda2/bin/bwa index MS_flye.fa
/opt/software/anaconda2/bin/bwa mem -t 48 MS_flye.fa ../MS_R1.fq.gz ../MS_R1.fq.gz | samtools view -@ 48 -bS -F 12 | samtools sort -@ 48 > bwa.sort.bam
samtools index bwa.sort.bam
pilon --genome MS_flye.fa --frags bwa.sort.bam --output MS_flye.pilon --changes --threads 48

# RagTag
ragtag.py scaffold /home/wuzhongzi2019/00.DRCv20/00.sus/sus11.fa MS_flye_pilon.fa -o MS_ragtag -r -t 72 -u -w

# TGScloser
conda activate TGS_gapcloser
/home/wuzhongzi2019/miniconda3/envs/TGS_gapcloser/bin/tgsgapcloser \
    --scaff /home/wuzhongzi2019/11.MSdhp/13.TGScloser/MS_ragtag.fa  \
    --reads  /home/wuzhongzi2019/11.MSdhp/13.TGScloser/ms30kb.fa \
    --output tgs_ms30ok \
    --ne \
    --tgstype pb \
    --thread 96 \
    >pipe.log 2>pipe.err
    
    
### Repeat
BuildDatabase -name mypiglib -engine ncbi MSjxau.fa
RepeatModeler -threads 72 -database mypiglib -engine ncbi
RepeatMasker -lib MyRepeatOk.lib -pa 72 -a -s -engine ncbi MSjxau.fa
/home/duhuipeng/ChenJQ/soft/repeatmakser/RepeatMasker/util/calcDivergenceFromAlign.pl -s MSjxau.divsum MSjxau.fa.align
/home/duhuipeng/ChenJQ/soft/repeatmakser/RepeatMasker/util/createRepeatLandscape.pl -div MSjxau.divsum -t "MSjxau" -g 2447343390 > MS.html

### liftoff
/home/goldenpigs217/miniconda3/bin/liftoff -g sus.gff3 -copies -polish -exclude_partial -m /home/goldenpigs217/miniconda3/bin/minimap2 -p 64 -dir ./MSsus -o ms.gff3 ./MSjxau.fa ./sus.fa


###SD
/home/wuzhongzi/00.bin/sedef/sedef.sh -o sedef_mm -j 24 msjxau.fa

###BUSCO
singularity exec -B /work/wuzhongzi/11.MSdhp/21.busco:/work/wuzhongzi/11.MSdhp/21.busco /work/wuzhongzi/11.MSdhp/21.busco/017.busco.sif busco --in MSjxau.fa -o MSjxau_mam -c 32 -l /work/wuzhongzi/11.MSdhp/21.busco/mammalia_odb10/ -m geno --offline
