#!/bin/sh

#
# convenience script just to re-run the association load
#

cd `dirname $0`/..
LOG=`pwd`/assemblyseqload.log
rm -f ${LOG}

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

##################################################################
##################################################################
#
# main
#
##################################################################
##################################################################

#
# run the genaccload
#

echo ${ASSOC_JNUMBER}
echo ${ACC_LOAD}
echo ${ASSOC_OBJECTTYPE}

if [ ${ASSOC_JNUMBER} != "0" ]
then
    echo "Running the genaccload" | tee -a ${LOG_DIAG} ${LOG_PROC}
    echo "\n`date`" >> ${LOG_PROC}

    echo ${ACC_LOAD} ${MGD_DBSERVER} ${MGD_DBNAME} ${MGD_DBUSER} ${MGD_DBPASSWORDFILE} ${JOBSTREAM} ${ASSOC_OBJECTTYPE} ${ASSOC_JNUMBER} ${ASSOCFILE} ${ASSOCFILE}.log
    ${ACC_LOAD} ${MGD_DBSERVER} ${MGD_DBNAME} ${MGD_DBUSER} ${MGD_DBPASSWORDFILE} ${JOBSTREAM} ${ASSOC_OBJECTTYPE} ${ASSOC_JNUMBER} ${ASSOCFILE} ${ASSOCFILE}.log >> ${LOG_PROC}

    STAT=$?
    if [ ${STAT} -ne 0 ]
    then
        echo "genaccload processing failed.  Return status: ${STAT}" >> ${LOG_PROC}
        shutDown
        exit 1
    fi
    echo "genaccload completed successfully" | tee -a  ${LOG_DIAG} ${LOG_PROC} 
fi

