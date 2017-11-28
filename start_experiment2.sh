# Usage: bash start_xyz.sh <node1> <node2> <decision_rule>
TEMPLATE='experiments/epuck_EC_locale_template.argos'
OUTFILE="experiments/epuck$1.argos"
#BASEDIR='/home/volker/Documents/bc_collective/controllers/epuck_environment_classification/'
BASEDIR='/home/vstrobel/Documents/argdavide/controllers/epuck_environment_classification/'
BLOCKCHAINPATH="/home/vstrobel/eth_data_para$1/data" # always without '/' at the end!!
MINERID=$(expr 120 + $1)
echo "MINERID is ${MINERID}"
NUMROBOTS=(20) 
REPETITIONS=50
DECISIONRULE=$3
#PERCENT_BLACKS=(34 36 38 40 42 44 46 48)
PERCENT_BLACKS=(34)
# the one I did all the tests with:
MININGDIFF=1000000 #was 1000000 before 
# never go with the difficulty below 131072! (see https://github.com/ethereum/go-ethereum/issues/3590)
USEMULTIPLENODES=true
USEBACKGROUNDGETHCALLS=true
MAPPINGPATH="/home/vstrobel/Documents/argdavide/experiments/config$1.txt"
CHANGEDIFFIULTY=""
NUMRUNS=1
THREADS=20
NOW=`date +"%d-%m-%Y"`
USEDNODES=($1 $2)
echo "USEDNODES is ${USEDNODES}"
BASEPORT=$((33000 + $1 * 200))
echo "BASEPORT is ${BASEPORT}"
DATADIR="data/experiment2_decision${DECISIONRULE}-node$1-byz-${NOW}/"
REGENERATEFILE="$(pwd)/regenerate${USEDNODES[0]}.sh"
# The miner node is the first of the used nodes
MINERNODE=${USEDNODES[0]}

USECLASSICALAPPROACH=false
# TODO:
NUMBYZANTINE=(0 1 2 3 4 5 6 7 8 9)
#NUMBYZANTINE=(0)
BYZANTINESWARMSTYLE=5
SUBSWARMCONSENSUS=true # Determines if all N robots have to agree or
		       # only the beneficial subswarm.



 # Rebuild geth with another value in checkDifficulty
 if [ $CHANGEDIFFIULTY ]; then
     ./create_geths.sh $MININGDIFF
 fi

 mkdir -p $DATADIR
 
 # Iterate over experimental settings and start experiments
 
 for i in `seq 1 $REPETITIONS`; do

     for y in "${NUMBYZANTINE[@]}"; do
 
	 for k in "${NUMROBOTS[@]}"; do

	 R0=$(expr $k / 2)
	 B0=$(expr $k / 2)

	 for p in "${PERCENT_BLACKS[@]}"; do

	PERCENT_BLACK=$p
	PERCENT_WHITE=$(expr 100 - $PERCENT_BLACK)
	
	if [ $USECLASSICALAPPROACH == "false" ]; then

	    echo "Blockchain version!"
	    
	    GENERATEDAG=`cat regeneratedag.txt`
	    if [ $GENERATEDAG ]; then
		#if [ "$i" -gt 0 ]; then
		rm ~/.ethash/*
		ssh vstrobel@c3-5 "geth makedag 0 ~/.ethash"
		echo "" > regeneratedag.txt
		#fi
	    fi
	    
	    # Create the mapping file
	    python experiments/create_node_mapping_call.py $MAPPINGPATH $NUMROBOTS ${USEDNODES[0]} ${USEDNODES[1]}

	    # Create template for:
	    # Create directories for collecting data and the geth processes
	    # Create file for killing the blockchain proceeses on these nodes
	    sed -e "s|NODEA|${USEDNODES[0]}|g" -e "s|NODEB|${USEDNODES[1]}|g" -e "s|BLOCKCHAINPATH|$BLOCKCHAINPATH|g" -e "s|PWD|$(pwd)|g" regenerate_template.sh > $REGENERATEFILE
	    # and apply the regeneration file for the blockchain folders
	    bash $REGENERATEFILE
	    
	fi
	
	RADIX=$(printf 'num%d_black%d_byz%d_run%d' $k $PERCENT_BLACK $y $i)
	
	# Create template
	sed -e "s|BASEDIR|$BASEDIR|g" -e "s|NUMRUNS|$NUMRUNS|g" -e "s|DATADIR|$DATADIR|g" -e "s|RADIX|$RADIX|g" -e "s|NUMROBOTS|$k|g" -e "s|R0|$R0|g" -e "s|B0|$B0|g" -e "s|PERCENT_BLACK|$PERCENT_BLACK|g" -e "s|PERCENT_WHITE|$PERCENT_WHITE|g" -e "s|DECISIONRULE|$DECISIONRULE|g" -e "s|USEMULTIPLENODES|$USEMULTIPLENODES|g" -e "s|MININGDIFF|$MININGDIFF|g" -e "s|MINERNODE|$MINERNODE|g" -e "s|MINERID|$MINERID|g" -e "s|BASEPORT|$BASEPORT|g" -e "s|USEBACKGROUNDGETHCALLS|$USEBACKGROUNDGETHCALLS|g" -e "s|BLOCKCHAINPATH|$BLOCKCHAINPATH|g" -e "s|MAPPINGPATH|$MAPPINGPATH|g" -e "s|THREADS|$THREADS|g" -e "s|USECLASSICALAPPROACH|$USECLASSICALAPPROACH|g" -e "s|NUMBYZANTINE|$y|g" -e "s|BYZANTINESWARMSTYLE|$BYZANTINESWARMSTYLE|g" -e "s|SUBSWARMCONSENSUS|$SUBSWARMCONSENSUS|g" -e "s|REGENERATEFILE|$REGENERATEFILE|g" $TEMPLATE > $OUTFILE
	
	# Start experiment
	argos3 -c $OUTFILE
	
	if [ USECLASSICALAPPROACH == "false" ]; then
	    
	    # Clean up
	    bash "${BLOCKCHAINPATH}/bckillerccall"
	    #mkdir -p "${DATADIR}${p}-${i}"
	    #mv "${BLOCKCHAINPATH}"* "${DATADIR}${p}-${i}"
	    rm -rf "${BLOCKCHAINPATH}"*
	    rm $REGENERATEFILE
	    
	fi
	
	 done
	 
     done
    
 done


sendmail volker.strobel87@gmail.com < finished.txt
     
done