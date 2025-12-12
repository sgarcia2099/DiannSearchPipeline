#For resetting nextflow directory during debugging

rm -f .nextflow*
rm -f logs

cd /lustre/or-scratch/cades-bsd/$USER

if [ -d "results" ]; then rm -r results; fi

if [ -d "work" ];    then rm -r work; fi

if [ -d "stash" ];   then rm -r stash; fi

rm -f .nextflow*

echo "\n Reset! \n"
