#!/bin/sh
#
###########################################################################
#
# convenience script just to re-run the association load
#

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#
# Usage: run_assocload.sh *_assemblyseqload.config
# The assocload config file is configured in each *_assemblyseqload.config
# as is the correct assocload jobstream script

cd `dirname $0`/..
LOG=`pwd`/run_assocload.log
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
. ${CONFIG_ASSOCLOAD}
#
#  Make sure the master configuration file is readable
#

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

##################################################################
##################################################################
#
# main
#
##################################################################
##################################################################

# run sequence/marker assocload
if [ ${ASSOC_JNUMBER} != "0" ]
then
    echo "Running the assocload" | tee -a ${LOG_DIAG} ${LOG_PROC}
    echo "" | tee -a ${LOG_PROC}
    echo "`date`" | tee -a ${LOG_PROC}

	${ASSOCLOADER_SH} ${CONFIG_LOAD} ${CONFIG_ASSOCLOAD}
	STAT=$?
	checkStatus ${STAT} "${ASSOCLOADER_SH}"
fi

exit 0

