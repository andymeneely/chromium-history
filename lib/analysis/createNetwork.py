#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database, create a list of graph objects
# ARGUMENTS: [username] [database name]

import psycopg2
import sys, getopt
import networkx as nx
from datetime import datetime, timedelta

# Get the username and db from command line
username, db = sys.argv[1], sys.argv[2]
# connection to database 
con = None
try:
	con = psycopg2.connect(database=db, user=username)
	cur = con.cursor()
except psycopg2.DatabaseError, e:
	print 'Error %s' % e
	sys.exit(1)
# we will need to create an array of graph objects 
# each graph object will be for a specific time frame
graphArray = []		
earlyBoundary = '2008-09-01 00:00:00.000000'
earlyTime = datetime.strptime( earlyBoundary, "%Y-%m-%d %H:%M:%S.%f")
lateBoundary = '2008-12-01 00:00:00.000000'
lateTime = datetime.strptime( lateBoundary, "%Y-%m-%d %H:%M:%S.%f")
while earlyBoundary < '2014-11-15 00:00:00.000000':
	G = nx.MultiGraph()
	# query for this time boundary
	try:
		string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary + "' AND review_date < '" + lateBoundary + "'";
		cur.execute(string)
		row_count = 0 
		for row in cur:
			row_count += 1
			# add each edge between two nodes, with the issue associated
			G.add_edge( row[1], row[2], issue=row[3] )
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
	# change boundaries and add G to array of graph
	earlyTime = lateTime
	lateTime += timedelta(days=61)
	earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	graphArray.append(G)
# close the connection to the database
if con:
	con.close()
for gr in graphArray:
	# THIS IS EXTREMELY VERBOSE ON CHROMIUM_REAL, FOR DEV DATA ONLY
	# GET LIST OF EDGES WITH THE ISSUE LISTED AS WELL
	#print '++++++++++\nThese are the connected components of each graph\n' 
	#print gr.edges(data=True)

	# THIS IS TO SEE A DICTIONARY OF EACH DEV_ID(key)TO THE DEGREE OF THAT DEV(value)
	print '\n--------\n'
	node_deg = gr.degree()
	print node_deg
	# FIND THE FIVE HIGHEST DEGREES
	max_deg1 = 0
	max_deg2 = 0
	max_deg3 = 0
	max_deg4 = 0
	max_deg5 = 0
	#find highest five degree values for each time period
	for key in sorted(node_deg, key=node_deg.get, reverse=True):
		if max_deg1 == 0:
			max_deg1 = key
		elif max_deg2 == 0:
			max_deg2 = key
		elif max_deg3 == 0:
			max_deg3 = key
		elif max_deg4 == 0:
			max_deg4 = key
		elif max_deg5 == 0:
			max_deg5 = key
	print "Maximum degrees for this period: %d:%d, %d:%d, %d:%d, %d:%d, %d:%d" %( max_deg1, node_deg[max_deg1], max_deg2, node_deg[max_deg2], max_deg3, node_deg[max_deg3], max_deg4, node_deg[max_deg4], max_deg5, node_deg[max_deg5])
