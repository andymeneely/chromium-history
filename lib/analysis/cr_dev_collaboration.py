#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley
# connect to psql database, make some queries, populate the necessary columns
# ARGUMENTS: [username] [database name]
import psycopg2
import sys, getopt
import os
from datetime import datetime, timedelta
from collections import OrderedDict

def main():
	username = sys.argv[1]
	db = sys.argv[2]
	data = est_connection( username, db )
	# data is the connection to the database
	populate_cr_vuln_misses( data )

# estabilishes connection
def est_connection( username, db ):
	con = None
	try:
		con = psycopg2.connect( database=db, user=username )
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
	return con

# counts the number of files in a code_review patch set that 
# are fixed in a vulnerability within a few months time
def populate_cr_vuln_misses( data ):
	cur = data.cursor()
	try:
		qry_crs = "SELECT issue, created, owner_id, commit_hash from code_reviews"
		cur.execute(qry_crs)
		for row in cur:
			issue = row[0]
			earlyTime = row[1]
			lateTime = earlyTime + timedelta(days=365)
			try:
				earlyBoundary = datetime.strptime( str(earlyTime) ,"%Y-%m-%d %H:%M:%S.%f" )
				lateBoundary = 	datetime.strptime( str(lateTime) , "%Y-%m-%d %H:%M:%S.%f" )
			except ValueError:
				earlyBoundary = datetime.strptime( str(earlyTime) ,"%Y-%m-%d %H:%M:%S" )
				lateBoundary = 	datetime.strptime( str(lateTime) , "%Y-%m-%d %H:%M:%S" )
			
			qry = "SELECT DISTINCT ON( cur_psf.filepath ) "
			qry = qry + "cur_cr.issue, cur_ps.composite_patch_set_id, cur_psf.filepath, vuln_cr.issue, "
			qry = qry + "vuln_cve.cvenum_id, vuln_cf.filepath "
			qry = qry + "FROM code_reviews AS cur_cr "
			qry = qry + "INNER JOIN patch_sets AS cur_ps ON cur_cr.issue = cur_ps.code_review_id "	
			qry = qry + "INNER JOIN patch_set_files AS cur_psf ON cur_ps.composite_patch_set_id = cur_psf.composite_patch_set_id "
			qry = qry + "INNER JOIN commit_filepaths AS vuln_cf ON cur_psf.filepath = vuln_cf.filepath "
			qry = qry + "INNER JOIN commits AS vuln_co ON vuln_cf.commit_hash = vuln_co.commit_hash "
			qry = qry + "INNER JOIN code_reviews AS vuln_cr ON vuln_co.commit_hash = vuln_cr.commit_hash "
			qry = qry + "INNER JOIN code_reviews_cvenums AS vuln_cve ON vuln_cr.issue = vuln_cve.code_review_id "
			qry = qry + "WHERE cur_cr.issue = " + str(issue) 
			qry = qry + " AND vuln_cr.created > '" + str(earlyTime) + "' AND vuln_cr.created <= '" + str(lateTime) + "'"
			
			cur2 = data.cursor()
			cur2.execute(qry)
			#print "HERE WE GOOOOOOOOOOO"
			count = 0
			for rows in cur2:
			#	print str(rows[0]) +" : "+ str(rows[1]) +" : "+ str(rows[2]) +" : "+ str(rows[3]) +" : "+ str(rows[4]) +" : " +str(rows[5])
				count = count + 1
			#print "count = "+str(count)+"\n------------------------------------"
			if count != 0:
				cur2.execute("UPDATE code_reviews SET vuln_missed = TRUE WHERE issue = " + str(issue))
				cur2.execute("UPDATE code_reviews SET vuln_misses = " + str(count) + " WHERE issue = " + str(issue))
				data.commit()					
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
if __name__ == "__main__":
	main()
