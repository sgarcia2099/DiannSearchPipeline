#For resetting nextflow directory during debugging

if [ -d "results" ]; then rm -r results; fi

if [ -d "work" ];    then rm -r work; fi

rm .nextflow*

echo "\n Reset! \n"
