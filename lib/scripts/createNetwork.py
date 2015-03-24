#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database

import psycopg2
import sys
import networkx as nx
from datetime import datetime, timedelta

# connection to database 
con = None
try:
	con = psycopg2.connect(database='sso7159', user='sso7159')
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
earlyBoundary = '2005-01-01 00:00:00.000000'
earlyTime = datetime.strptime( earlyBoundary, "%Y-%m-%d %H:%M:%S.%f")
lateBoundary = '2006-01-01 00:00:00.000000'
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
	print 'IN TIME PHRAME: %s - %s \n' % (earlyBoundary, lateBoundary)
	print G.edges(data=True)
	print '\n'	
	# change boundaries and add G to array of graph
	lp_yr = lateTime.year
	earlyTime = lateTime
	if (lp_yr % 4) == 0:
		lateTime += timedelta(days=366)
	else:
		lateTime += timedelta(days=365)
	earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	graphArray.append(G)
# close the connection to the database
if con:
	con.close()
	print '++++++++++\nThese are the connected components of each graph\n'
#for gr in graphArray:
#	print gr.edges(data=True)

