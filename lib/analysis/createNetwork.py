#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database

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
	#cur.execute('SELECT version()');
	#ver = cur.fetchone()
	#print ver
except psycopg2.DatabaseError, e:
	print 'Error %s' % e
	sys.exit(1)
# we will need to create an array of graph objects 
# each graph object will be for a specific time frame
graphArray = []		
earlyBoundary = '2006-01-01 00:00:00.000000'
earlyTime = datetime.strptime( earlyBoundary, "%Y-%m-%d %H:%M:%S.%f")
lateBoundary = '2006-04-01 00:00:00.000000'
lateTime = datetime.strptime( lateBoundary, "%Y-%m-%d %H:%M:%S.%f")
while earlyBoundary < '2015-01-01 00:00:00.000000':
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
			#print 'edge added for %d + %d on %d\n' % (row[1],row[2],row[3])
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
	print '-------------IN TIME FRAME: %s - %s ---------\n' % (earlyBoundary, lateBoundary)
	#print G.edges(data=True) # disabled becuase this is SUPER verbose on chromium_real (Andy)
	print '----------------------------------------------\n'	
	# change boundaries and add G to array of graph
	#molen = lateTime.
	earlyTime = lateTime
	#if (lp_yr % 4) == 0:
	#	lateTime += timedelta(days=366)
	#else:
	lateTime += timedelta(days=90)
	earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	graphArray.append(G)
# close the connection to the database
if con:
	con.close()
	#print '++++++++++\nThese are the connected components of each graph\n'
for gr in graphArray:
	#print gr.edges(data=True)
	node_deg = gr.degree()
	print node_deg
	max_deg1 = 0
	max_deg2 = 0
	max_deg3 = 0
	#find highest three degree values for each time period
	for key in sorted(node_deg, key=node_deg.get, reverse=True):
		if max_deg1 == 0:
			max_deg1 = key
		elif max_deg2 == 0:
			max_deg2 = key
		elif max_deg3 == 0:
			max_deg3 = key
	print "Maximum degrees for this period: %d, %d, %d" %( max_deg1, max_deg2, max_deg3 )	
		






