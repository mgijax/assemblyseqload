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

echo "Running assembly sequence loads" | tee ${LOG}
date
assemblyseqload.sh ensembl_assemblyseqload.config
#assemblyseqload.sh ncbi_assemblyseqload.config

#
# run the cache loads
#

echo "Running cache loads" | tee ${LOG}
date
${SEQ_MARKER_CACHELOAD}
${SEQ_COORD_CACHELOAD}

date | tee ${LOG}
