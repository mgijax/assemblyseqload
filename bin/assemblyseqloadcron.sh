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
date | tee  -a ${LOG}
assemblyseqload.sh ensembl_assemblyseqload.config
#assemblyseqload.sh ncbi_assemblyseqload.config

#
# run the cache loads
#

echo "Running seq/marker cacheload" | tee -a ${LOG}
date | tee -a ${LOG}
${SEQ_MARKER_CACHELOAD}

echo "Running seq/coordinate cacheload" | tee -a ${LOG}
date | tee -a ${LOG}
${SEQ_COORD_CACHELOAD}

echo "Running seq description cacheload" | tee -a ${LOG}
date | tee -a ${LOG}
${SEQ_MARKER_DESCRIPT_CACHELOAD}

date | tee -a ${LOG}
