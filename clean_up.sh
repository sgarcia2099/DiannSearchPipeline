#For resetting nextflow directory during debugging

if [ -d ".nextflo*" ]; then rm -r .nextflo*; fi
if [ -d "logs" ];      then rm -r logs; fi

cd /lustre/or-scratch/cades-bsd/$USER

if [ -d "results" ]; then rm -r results; fi

if [ -d "work" ];    then rm -r work; fi

if [ -d "stash" ];   then rm -r stash; fi

echo "\n Reset! \n"
