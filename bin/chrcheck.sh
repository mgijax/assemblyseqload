#!/bin/sh 
#
#  chrcheck.sh
###########################################################################
#
#  Purpose:  This script controls execution of chrcheck.py
#	     which checks for chromosome consistencies between
#            markers and gene models
#
  Usage="chrcheck.sh config_file1 [config_file2... config_fileN], where config_file is full path"
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - 1 to n config files sourced in command line order
#      - mgd database
#
#  Outputs:
#
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - report written to RPTDIR
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
#  Assumes:  mgiconfig master config has been sourced OR is passed in on command
#	     line 
#  Implementation:  
#
#  Notes:  None
#
###########################################################################

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#

cd `dirname $0`
LOG=`pwd`/chrcheck.log
rm -f ${LOG}

#
#  Verify the argument(s) to the shell script.
#
if [ $# -lt 1 ]
then
    echo ${Usage} | tee -a ${LOG}
    exit 1
fi


# Verify and source the command line config files.
#

config_files=""
for config in $@
do
    if [ ! -r ${config} ]
    then
        echo "Cannot read configuration file: ${config}" | tee -a ${LOG}
        exit 1
    fi
    . ${config}
done

#
#  Source the common DLA functions script.
#
if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
        . ${DLAJOBSTREAMFUNC}
    else
        echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}" | tee -a
${LOG}
        exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined." | tee -a
${LOG}
    exit 1
fi

# reality check for important configuration vars
echo "COORD_COLLECTION_NAME: ${COORD_COLLECTION_NAME}"
echo "COORD_LOGICALDB: ${COORD_LOGICALDB}"
echo "MGD_DBSERVER: ${MGD_DBSERVER}"
echo "MGD_DBNAME: ${MGD_DBNAME}"

##################################################################
##################################################################
#
# main
#
##################################################################
##################################################################

echo "Running chrcheck.py" | tee -a ${LOG}
chrcheck.py | tee -a ${LOG} 
STAT=$?
checkStatus ${STAT} "chrcheck.py"

exit 0

