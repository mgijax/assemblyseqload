#!/bin/sh
#
#  $Header
#  $Name
#
#  assemblyseqloadcron.sh
###########################################################################
#
#  Purpose:  Wrapper to load ncbi and ensembl sequences and coordinates, and
#            sequence/marker associations. loads seq/marker cache and seq/coord
#            cache
#
  Usage="assemblyseqloadcron.sh"
#
###########################################################################
cd `dirname $0`
LOG=`pwd`/assemblyseqloadcron.log
rm -f ${LOG}

date | tee ${LOG}

# source the common configuration
. ../common.config.sh

# source the common assembly load configuration
. ../assembly_common.config

#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 0 ]
then
    echo ${Usage} | tee -a ${LOG}
    exit 1
fi

#
# run the assembly loads
#

echo "Running assembly sequence loads" | tee -a ${LOG}
assemblyseqload.sh ensembl_assemblyseqload.config

STAT=$?
if [ ${STAT} -ne 0 ]
then
    exit 1
fi

#assemblyseqload.sh ncbi_assemblyseqload.config

#STAT=$?
#if [ ${STAT} -ne 0 ]
#then
#    exit 1
#fi

echo "assemblyseqloads completed successfully" | tee -a ${LOG}

#
# run the cache loads
#

date | tee -a ${LOG} 
echo "Running ${SEQ_MARKER_CACHELOAD}" | tee -a ${LOG} 
${SEQ_MARKER_CACHELOAD}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "${SEQ_MARKER_CACHELOAD} processing failed.  \
        Return status: ${STAT}" | tee -a ${LOG} 
    exit 1
fi
echo "${SEQ_MARKER_CACHELOAD} completed successfully" | tee -a  ${LOG} 


date | tee -a ${LOG} 
echo "Running ${SEQ_COORD_CACHELOAD}" | tee -a ${LOG} 
${SEQ_COORD_CACHELOAD}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    # If SEQ_COORD_CACHELOAD fails SEQ_MARKER_DESCRIPT_CACHELOAD 
    # can still execute
    echo "${SEQ_COORD_CACHELOAD} processing failed.  \
        Return status: ${STAT}" | tee -a ${LOG} 
else
    echo "${SEQ_COORD_CACHELOAD} completed successfully" | tee -a  ${LOG}
fi


date | tee -a ${LOG} 
echo "Running ${SEQ_MARKER_DESCRIPT_CACHELOAD}" | tee -a ${LOG} 
${SEQ_MARKER_DESCRIPT_CACHELOAD}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "${SEQ_MARKER_DESCRIPT_CACHELOAD} processing failed.  \
        Return status: ${STAT}"  | tee -a ${LOG} 
    exit 1
fi

echo "${SEQ_MARKER_DESCRIPT_CACHELOAD} completed successfully" | tee -a  ${LOG}

date | tee -a ${LOG} 
