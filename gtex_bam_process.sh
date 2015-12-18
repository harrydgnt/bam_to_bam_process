if [ $# -lt 5 ] 
then 
echo "GTEx data Decryption Data - Written by Harry Yang - harry2416@gmail.com"
echo "[1] dir with .bam files" 
echo "[2] sample files for bam files"
echo "[3] decryption depository - provided as you set up the decryption key"
echo "	e.g. /u/home/h/harryyan/project-eeskin/decryption_test/"
echo " FOR YOUR PURPOSES, Serghei, just type any directory - it will not be used."
echo "[4] the dump directory where decrypted bam files would be stored." 
echo "	the dump dir will be created and scripts will be written in this folder!" 
echo "[5] gene list - i.e. /u/home/h/harryyan/project-eeskin/gtex/gtex_bam_gene_coodrinate_list.txt"
echo "	This includes jimmy, TCR, BCR, Immune genes."

exit 1
fi 

pwd 
decdir=$3
dumpdir=$4
mkdir $dumpdir
cd $dumpdir 
pwd 

while read line 
do 
#echo $line 
item=$(echo $line | awk -F '.ncbi_enc' '{print $1}')
itemname=$(echo $item | awk -F '.' '{print $1}') 
ext_item_name=$(echo $item | awk -F '.bam' '{print $1}')
echo $item 

###each sample would have dedicated folder

mkdir $ext_item_name
cd $ext_item_name

#### commented out because we use already decrypted bams 
# ###decrypt .ncbi_enc file to bam
# echo "mv ${1}/${line} ${decdir}" >> run_${itemname}.sh
# echo "cd ${decdir}" >> run_${itemname}.sh
# echo "${decdir}/vdb-decrypt -f ${decdir}/${line}" >> run_${itemname}.sh 
# echo "mv ${decdir}/$item ${dumpdir}/$ext_item_name" >> run_${itemname}.sh 

### extract unmapped fastq
echo "samtools view -b -f 4 ${dumpdir}/${ext_item_name}/${item} > ${dumpdir}/${ext_item_name}/${ext_item_name}.unmapped.bam" >> run_${itemname}.sh
echo "samtools index ${dumpdir}/${ext_item_name}/${ext_item_name}.unmapped.bam">>run_${itemname}.sh
#echo "bamtools convert -in ${dumpdir}/${ext_item_name}/${ext_item_name}.unmapped.bam -format fastq > ${dumpdir}/${ext_item_name}/${ext_item_name}.fastq">>run_${itemname}.sh
#echo "gzip ${dumpdir}/${ext_item_name}/${ext_item_name}.fastq">>run_${itemname}.sh

### bam index

echo "samtools index ${dumpdir}/${ext_item_name}/${item}">>run_${itemname}.sh

###HTSeq -default gtf is set

gtf=/u/home/s/serghei/project/Homo_sapiens/Ensembl/GRCh37/Annotation/Genes/genes.gtf 

echo "#!/bin/bash">>run_${itemname}.sh
echo ". /u/local/Modules/default/init/modules.sh" >>run_${itemname}.sh
echo "module load samtools" >>run_${itemname}.sh
echo "module load bamtools" >>run_${itemname}.sh
echo "samtools sort -n ${dumpdir}/${ext_item_name}/$item ${dumpdir}/${ext_item_name}/${item}_sort_byname">>run_${itemname}.sh
echo "module load python/2.7.3">>run_${itemname}.sh
echo "python /u/home/h/harryyan/project-eeskin/utilities/HTSeq-0.6.1/scripts/htseq-count --format=bam --mode=intersection-strict --stranded=no ${dumpdir}/${ext_item_name}/${item}_sort_byname.bam $gtf >${item}.counts" >>run_${itemname}.sh
echo "rm -rf ${dumpdir}/${ext_item_name}/${item}_sort_byname.bam">>run_${itemname}.sh

###bam file extractor for each gene
while read gene
do
###becho $gene
chr=$(echo $gene | awk -F ',' '{print $1}')
name=$(echo $gene | awk -F ',' '{print $4}')
pos_one=$(echo $gene | awk -F ',' '{print $5}')
pos_two=$(echo $gene | awk -F ',' '{print $6}')

echo "samtools view -bh ${dumpdir}/${ext_item_name}/${item} $chr:$pos_one-$pos_two > ${dumpdir}/${ext_item_name}/${ext_item_name}_$name.bam">>run_$itemname.sh
echo "samtools view -c ${dumpdir}/${ext_item_name}/${ext_item_name}_$name.bam | echo "${name} \$1">>${dumpdir}/${ext_item_name}/${ext_item_name}.gene_count">>run_$itemname.sh
done<$5




### repeat profile
echo "mkdir ${dumpdir}/${ext_item_name}/repeat_profile">>run_${itemname}.sh
echo "python /u/home/h/harryyan/project-eeskin/repeat/rprofile/rprofile.py ${dumpdir}/${ext_item_name}/${item} ${dumpdir}/${ext_item_name}/repeat_profile/${ext_item_name}_repeat.">>run_${itemname}.sh

###gene profile 
echo "mkdir ${dumpdir}/${ext_item_name}/genomic_profile">>run_${itemname}.sh
echo "python /u/home/h/harryyan/project-eeskin/repeat/gprofile/gprofilePE.py --readPerCategory ${dumpdir}/${ext_item_name}/${item} ${dumpdir}/${ext_item_name}/genomic_profile/${ext_item_name}_genome h">>run_${itemname}.sh




### unmapped read

echo "num_unmapped=\$(samtools view -c -fox4 ${dumpdir}/${ext_item_name}/${item})">>run_${itemname}.sh
echo "num_total=\$(samtools view -c ${dumpdir}/${ext_item_name}/${item})">>run_${itemname}.sh
echo "echo "\${num_unmapped}	\${num_total}">>${dumpdir}/unmapped_ratio.txt">>run_${itemname}.sh
#







echo "rm ${dumpdir}/${ext_item_name}/${ext_item_name}.unmapped.bam">>run_${itemname}.sh
echo "rm ${dumpdir}/${ext_item_name}/${ext_item_name}.unmapped.bam.bai">>run_${itemname}.sh
echo "rm ${dumpdir}/${ext_item_name}/$item">>run_${itemname}.sh


cd ..
done <$2 	
