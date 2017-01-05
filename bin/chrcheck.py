#!/usr/local/bin/python

'''
#
# Purpose:
#
# Report chromosome inconsistencies between markers and gene models
#
# Usage:
#       chrcheck.py
#
# History
#
# 5/31/2007 	sc
#	- new
''' 

import sys
import os
import string
import db

TAB = '\t'
NL = '\n'

logicalDB = os.environ['COORD_LOGICALDB']
ldbKey = ''
collection = os.environ['COORD_COLLECTION_NAME']
collKey = ''
reportFileName = '%s/chrcheck.rpt' % os.environ['RPTDIR']

reportFile = open(reportFileName, 'w')

db.useOneConnection(1)

# Resolve logical db name to key
results = db.sql('''select _LogicalDB_key from ACC_LogicalDB where name = '%s' ''' % logicalDB, 'auto')
ldbKey = results[0]['_LogicalDB_key']
if ldbKey == '':
    print 'Invalid Coordinate LogicalDB name'
    exit(1)

# Resolve collection name to key
results = db.sql('''select _Collection_key from MAP_Coord_Collection where name = '%s' ''' % collection, 'auto')
collKey = results[0]['_Collection_key']
if collKey == '':
    print 'Invalid Coordinate Collection name'
    exit(1)

# query for inconsistencies
results = db.sql('''select a1.accID, m.symbol, cc.chromosome as geneModelChr, m.chromosome as markerChr
    from MAP_Coordinate c, MRK_Chromosome cc, MAP_Coord_Feature f, 
         ACC_Accession a1, ACC_Accession a2, MRK_Marker m 
    where c._Collection_key = %s 
    and c._MGIType_key = 27 
    and c._Object_key = cc._Chromosome_key 
    and c._Map_key = f._Map_key 
    and f._Object_key = a1._Object_key 
    and a1._MGIType_key = 19 
    and a1._LogicalDB_key = %s 
    and a1.accID = a2.accID 
    and a2._MGIType_key = 2 
    and a2._LogicalDB_key = %s 
    and a2._Object_key = m._Marker_key 
    and cc.chromosome != m.chromosome 
    ''' % (collKey, ldbKey, ldbKey), 'auto')

reportFile.write('%s with different Chromosome that its associated Marker%s%s' % (logicalDB, NL, NL))
reportFile.write('Gene Model ID%sSymbol%sGene Model Chr%sMarker Chr%s' % (TAB, TAB, TAB, NL))
reportFile.write('----------------------------------------------------------------------%s' % NL)

for r in results:
    reportFile.write('%s%s%s%s%s%s%s%s' % (r['accID'], TAB, r['symbol'], TAB, r['geneModelChr'], TAB, r['markerChr'], NL))

reportFile.write('%sTotal: %s%s' % (NL, len(results), NL))
reportFile.close()
db.useOneConnection(0)
