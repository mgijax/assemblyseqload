#!/bin/sh
#
#  assemblyseqload.sh
###########################################################################
#
#  Purpose:  This script controls the execution of the assembly loads
#
  Usage="assemblyseqload.sh config_file"
#
#     e.g. ncbi_seqload.config or ensembl_seqload.config
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Common configuration file (/usr/local/mgi/etc/common.config.sh)
#      - Configuration file (assemblyseqload.config)
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
CONFIG_COMMON=`pwd`/common.config.sh
CONFIG_LOAD_COMMON=`pwd`/assembly_common.config
CONFIG_LOAD=`pwd`/$1

echo ${CONFIG_LOAD}

#
#  Make sure the configuration files are readable.
#
if [ ! -r ${CONFIG_LOAD_COMMON} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD_COMMON}"
    exit 1
fi

if [ ! -r ${CONFIG_COMMON} ]
then
    echo "Cannot read configuration file: ${CONFIG_COMMON}"
    exit 1
fi

if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}"
    exit 1
fi

#
# source config files
#
. $CONFIG_COMMON
. $CONFIG_LOAD
. ${CONFIG_LOAD_COMMON}

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
    echo "INFILE_NAME not defined. Return status: ${STAT}" | tee -a ${LOG_DIAG}
    shutDown
    exit 1
fi

if [ ! -r ${INFILE_NAME} ]
then
    # set STAT for endJobStream.py called from postload in shutDown
    STAT=1
    echo "Cannot read from input file: ${INFILE_NAME}" | tee -a ${LOG}
    shutDown
    exit 1
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
echo "\n`date`" >> ${LOG_PROC}

echo "Processing input file ${INFILE_NAME}" | tee -a ${LOG_DIAG} ${LOG_PROC}

# run the load

${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
-DCONFIG=${CONFIG_COMMON},${CONFIG_LOAD},${CONFIG_LOAD_COMMON} \
-DJOBKEY=${JOBKEY} ${DLA_START}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "assemblyseqload processing failed. Return status: ${STAT}" >> ${LOG_PROC}
    shutDown
    exit 1
fi
echo "assemblyseqload completed successfully" >> ${LOG_PROC}

#
# Run the assembly coordinate load
#

echo "Running coordload" | tee -a ${LOG_DIAG} ${LOG_PROC}

# log time and input files to process
echo "\n`date`" >> ${LOG_PROC}

echo "Processing input file ${INFILE_NAME}" | tee -a ${LOG_DIAG} ${LOG_PROC}

# Here we override the Configured value of DLA_LOADER
# and set it to the Configured coordload class
${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
-DCONFIG=${CONFIG_COMMON},${CONFIG_LOAD},${CONFIG_LOAD_COMMON} \
-DDLA_LOADER=${COORD_DLA_LOADER} \
-DJOBKEY=${JOBKEY} ${DLA_START}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "coordload processing failed. Return status: ${STAT}" >> ${LOG_PROC}
    shutDown
    exit 1
fi
echo "coordload completed successfully" >> ${LOG_PROC}

#
# run the genaccload
#

if [ ${ASSOC_JNUMBER} != "0" ]
then
    echo "Running the genaccload" | tee -a ${LOG_DIAG} ${LOG_PROC}
    echo "\n`date`" >> ${LOG_PROC}

    ${ACC_LOAD} ${MGD_DBSERVER} ${MGD_DBNAME} ${MGD_DBUSER} ${MGD_DBPASSWORDFILE} ${JOBSTREAM} ${OBJECTYPE} ${ASSOC_JNUMBER} ${ASSOCFILE} ${ASSOCFILE}.log >> ${LOG_PROC}

    STAT=$?
    if [ ${STAT} -ne 0 ]
    then
        echo "genaccload processing failed.  Return status: ${STAT}" >> ${LOG_PROC}
        shutDown
        exit 1
    fi
    echo "genaccload completed successfully" | tee -a  ${LOG_DIAG} ${LOG_PROC} 
fi

#
# run postload cleanup and email logs
#
shutDown

exit 0

