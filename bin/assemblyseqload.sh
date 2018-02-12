#!/bin/sh
#
#  assemblyseqload.sh
###########################################################################
#
#  Purpose:  This script controls the execution of the assembly loads
#             this includes sequence, coordinate, and optionally
#             association loads
#
  Usage="assemblyseqload.sh config_file"
#
#     e.g. "assemblyseqload.sh ncbi_seqload.config" 
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Common configuration file -
#		/usr/local/mgi/live/mgiconfig/master.config.sh
#      - Common Assembly configuration file - assembly_common.config
#      - Specific Assembly configuration file - e.g. ncbi_assemblyseqload.config
#      - assembly input file 
#      - gene model/marker association file (optional)
#
#  Outputs:
#
#      - An archive file
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - BCP files for for inserts to each database table to be loaded
#      - Records written to the database tables
#      - Exceptions written to standard error
#      - Configuration and initialization errors are written to a log file
#        for the shell script
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#      2:  Non-fatal error occurred
#
#  Assumes:  Nothing
#
#  Implementation:  
#
#  Notes:  None
#
###########################################################################

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#

cd `dirname $0`/..
LOG=`pwd`/assemblyseqload.log
rm -f ${LOG}

#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 1 ]
then
    echo ${Usage} | tee -a ${LOG}
    exit 1
fi

#
#  Establish the configuration file names.
#
CONFIG_LOAD=`pwd`/$1
CONFIG_LOAD_COMMON=`pwd`/assembly_common.config

#
#  Make sure the configuration files are readable
#

if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}"
    exit 1
fi

if [ ! -r ${CONFIG_LOAD_COMMON} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD_COMMON}"
    exit 1
fi

#
# source config files - order is important
#
. ${CONFIG_LOAD_COMMON}
. ${CONFIG_LOAD}

#
#  Make sure the master configuration file is readable
#

if [ ! -r ${CONFIG_MASTER} ]
then
    echo "Cannot read configuration file: ${CONFIG_MASTER}"
    exit 1
fi

# reality check for important configuration vars
echo "javaruntime:${JAVARUNTIMEOPTS}"
echo "classpath:${CLASSPATH}"
echo "dbserver:${MGD_DBSERVER}"
echo "database:${MGD_DBNAME}"

#
#  Source the DLA library functions.
#
if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
        . ${DLAJOBSTREAMFUNC}
    else
        echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}"
        exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined."
    exit 1
fi

#
# check that INFILE_NAME has been set and readable
#
if [ "${INFILE_NAME}" = "" ]
then
     # set STAT for endJobStream.py called from postload in shutDown
    STAT=1
    checkStatus ${STAT} "INFILE_NAME not defined"
fi

if [ ! -r ${INFILE_NAME} ]
then
    # set STAT for endJobStream.py called from postload in shutDown
    STAT=1
    checkStatus ${STAT} "Cannot read from input file: ${INFILE_NAME}"
fi

##################################################################
##################################################################
#
# main
#
##################################################################
##################################################################

#
# createArchive including OUTPUTDIR, startLog, getConfigEnv, get job key
#

preload ${OUTPUTDIR}

#
# rm files and dirs from OUTPUTDIR and RPTDIR
#

cleanDir ${OUTPUTDIR} ${RPTDIR}

#
# Run the assembly sequence load
#

echo "Running assemblyseqload" | tee -a ${LOG_DIAG} ${LOG_PROC}


# log time and input files to process
echo "" >> ${LOG_DIAG} ${LOG_PROC}
echo "`date`" >> ${LOG_DIAG} ${LOG_PROC}

echo "Processing input file ${INFILE_NAME}" >> ${LOG_DIAG} ${LOG_PROC}

# run the load

${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
-DCONFIG=${CONFIG_MASTER},${CONFIG_LOAD_COMMON},${CONFIG_LOAD} \
-DJOBKEY=${JOBKEY} ${DLA_START}

STAT=$?
checkStatus ${STAT} "${ASSEMBLYSEQLOAD}"

# update serialization on mgi_reference_assoc, seq_source_assoc
cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 | tee -a $LOG

select setval('mgi_reference_assoc_seq', (select max(_Assoc_key) from MGI_Reference_Assoc));
select setval('seq_source_assoc_seq', (select max(_Assoc_key) from SEQ_Source_Assoc));

EOSQL

#
# Run the assembly coordinate load
#

echo "Running coordload" | tee -a ${LOG_DIAG} ${LOG_PROC}

# log time and input files to process
echo "" >> ${LOG_DIAG} ${LOG_PROC}
echo "`date`" >> ${LOG_DIAG} ${LOG_PROC}

echo "Processing input file ${INFILE_NAME}" >> ${LOG_DIAG} ${LOG_PROC}

# Here we override the Configured value of DLA_LOADER
# and set it to the Configured coordload class
${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
-DCONFIG=${CONFIG_MASTER},${CONFIG_LOAD_COMMON},${CONFIG_LOAD} \
-DDLA_LOADER=${COORD_DLA_LOADER} \
-DJOBKEY=${JOBKEY} ${DLA_START}

STAT=$?
checkStatus ${STAT} "${COORDLOAD}"

if [ ${OK_LOAD_SEQ_CACHE_TABLES} = 'true' ]
then
    echo "loading SEQ_Coord_Cache table" | tee -a ${LOG_DIAG} ${LOG_PROC}
    ${SEQCACHELOAD}/seqcoord.csh | tee -a ${LOG_DIAG}
    STAT=$?
    checkStatus ${STAT} "${SEQCACHELOAD}/seqcoord.csh"
fi

# run sequence/marker assocload and chromosome check
if [ ${ASSOC_JNUMBER} != "0" ]
then
    echo "Running the assocload" | tee -a ${LOG_DIAG} ${LOG_PROC}
    echo "" >> ${LOG_PROC}
    echo "`date`" >> ${LOG_PROC}

    ${ASSOCLOADER_SH} ${CONFIG_LOAD} ${CONFIG_ASSOCLOAD}
    STAT=$?
    checkStatus ${STAT} "${ASSOCLOADER_SH}"

    echo "Running Chromosome Report" | tee -a ${LOG_DIAG} ${LOG_PROC}
    echo "" >> ${LOG_PROC}
    echo "`date`" >> ${LOG_PROC}
    ${ASSEMBLYSEQLOAD}/bin/chrcheck.sh ${CONFIG_LOAD_COMMON} ${CONFIG_LOAD} | tee -a ${LOG_DIAG}
    STAT=$?
    checkStatus ${STAT} "chrcheck.sh"


    if [ ${OK_LOAD_MRK_CACHE_TABLES} = 'true' ]
    then
	echo "loading SEQ_Marker_Cache table" | tee -a ${LOG_DIAG} ${LOG_PROC}
	${SEQCACHELOAD}/seqmarker.csh | tee -a ${LOG_DIAG}
	STAT=$?
	checkStatus ${STAT} "${SEQCACHELOAD}/seqmarker.csh"

	echo "loading MRK_Label cache table" | tee -a ${LOG_DIAG} ${LOG_PROC}
        ${MRKCACHELOAD}/mrklabel.csh | tee -a ${LOG_DIAG}
        STAT=$?
        checkStatus ${STAT} "${MRKCACHELOAD}/mrklabel.csh"

        echo "loading MRK_Location_Cache table" | tee -a ${LOG_DIAG} ${LOG_PROC}
        ${MRKCACHELOAD}/mrklocation.csh | tee -a ${LOG_DIAG}
        STAT=$?
        checkStatus ${STAT} "${MRKCACHELOAD}/mrklocation.csh"

        echo "loading MRK_Reference cache table" | tee -a ${LOG_DIAG} ${LOG_PROC}
        ${MRKCACHELOAD}/mrkref.csh | tee -a ${LOG_DIAG}
        STAT=$?
        checkStatus ${STAT} "${MRKCACHELOAD}/mrkref.csh"

    fi
    

fi

#
# run postload cleanup and email logs
#
shutDown

exit 0

