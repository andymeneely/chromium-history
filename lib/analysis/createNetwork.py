#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database, create a list of graph objects
# ARGUMENTS: [username] [database name]

from  math import sqrt
import psycopg2
import sys, getopt
import json
import networkx as nx
from networkx.readwrite import json_graph
from datetime import datetime, timedelta
from collections import OrderedDict

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
	G = nx.MultiGraph(begin=earlyBoundary,end=lateBoundary)
	# query for this time boundary
	try:
		string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary + "' AND review_date < '" + lateBoundary + "'";
		cur.execute(string)
		for row in cur:
			# add each edge between two nodes, with the issue amd issue_owner
			G.add_edge( row[1], row[2], issue=row[4], issue_owner=row[3] )
			G.node[row[1]]["sec_exp"] = row[6]
			G.node[row[1]]["sher_hrs"] = row[8]
			G.node[row[1]]["bugsec_exp"] = row[10]
			G.node[row[2]]["sec_exp"] = row[7]
			G.node[row[2]]["sher_hrs"] = row[9]
			G.node[row[2]]["bugsec_exp"] = row[11]
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
# for each graph, let's categorize developers by their degree and begin
# some analysis
grnum = 0
for gr in graphArray:
	# return a dictionary of this graph's node degrees
	node_deg = gr.degree()
	num_nodes = len(node_deg)
	if num_nodes == 0:
		continue
	# move the node degree items into an ascending list of degrees for quartile ranges
	sorted_deg = OrderedDict( sorted( node_deg.items(), key=lambda(k,v):(v,k) ) )
	median = 0
	low_quart = 0
	upper_quart = 0
	outlier_quart = 0
	sorted_deg_values = sorted_deg.values()
	if ( num_nodes % 2 ) == 0:
		mid_lo = (num_nodes / 2) - 1
		mid_hi = num_nodes / 2
		median = (sorted_deg_values[mid_lo] + sorted_deg_values[mid_hi])/2
	else:
		median = sorted_deg_values[ ((num_nodes + 1) / 2)-1 ]
	low_mid = int( round( (num_nodes+1)/4 )-1 )
	low_quart = sorted_deg_values[low_mid]
	high_mid = int( round( (num_nodes-1)*0.75 ) )
	upper_quart = sorted_deg_values[high_mid]
	outlier_quart = upper_quart * 3
	print "\nFor graph #" + str(grnum) + " IN TIME FRAME: " + gr.graph["begin"] + " UNTIL " + gr.graph["end"]
	print "lower q:%d , median: %d, upper q:%d, outlier q:%d" %( low_quart, median, upper_quart, outlier_quart) 
	# now group the developers by their degree values
	qrt1_devs = []
	qrt2_devs = []
	qrt3_devs = []
	qrt4_devs = []
	qrto_devs = []	
	for dev in sorted_deg:	
		gr.node[dev]["degree"] = sorted_deg[dev]
		if sorted_deg[dev] <= low_quart:
			qrt1_devs.append(dev)	
		elif sorted_deg[dev] <= median:
			qrt2_devs.append(dev)
		elif sorted_deg[dev] <= upper_quart:
			qrt3_devs.append(dev)
		elif sorted_deg[dev] <= outlier_quart:
			qrt4_devs.append(dev)
		else:
			qrto_devs.append(dev) 
	#print "quartile 1:"
	#for elem in qrt1_devs:
	#	sys.stdout.write( str(elem) + "," )
	#print "\nquartile 2:"
	#for elem in qrt2_devs:
	#	sys.stdout.write( str(elem) + "," )
	#print "\nquartile 3:"
	#for elem in qrt3_devs:
	#	sys.stdout.write( str(elem) + "," )
	# generate an ownership_count of issues this developer worked on
	# during this specific time period
	for elem in qrt1_devs:
		owner_count = 0
		for edge in list(gr.edges_iter(elem, data=True)):
			if elem == edge[2]["issue_owner"]:
				owner_count = owner_count + 1
			gr.node[elem]["own_count"] = owner_count
		print "dev_id:%d, dev_deg:%d, sher_hrs:%d, sec_exp:%s, bugsec_exp:%s, own_count:%d" %(elem, gr.node[elem]["degree"], gr.node[elem]["sher_hrs"], gr.node[elem]["sec_exp"], gr.node[elem]["bugsec_exp"], gr.node[elem]["own_count"])
	grnum = grnum + 1	

# AT THIS POINT EACH EDGE OF THE GRAPH HAS TWO ATTRIBUTES: issue and issue_owner
# EACH NODE (DEVELOPER) HAS 5 ATTRIBUTES, SHERIFF HOURS, SEC EXP, BUGSEC EXP, DEGREE
#       AND OWNERSHIP COUNT

# THIS CODE WILL BE MODIFIED NEXT WEEK TO PRODUCE COMMA-DELIMITED TEXT FILES WHICH CAN BE 
# EASILY IMPORTED INTO EXCEL FOR ANALYZATION
	#fileCount = 0
	#node_deg = G.degree()
	# write information for this time period to the text file	
	#theFile = open( "../../../../graph_degree_files/graph" +str(fileCount)+ ".txt" , 'w' ) 
	#theFile.write( "dev_id,dev_degree," +earlyBoundary+ "," +lateBoundary+ "\n" )
	#for key in sorted(node_deg, key=node_deg.get, reverse=True):
		#count_node += 1
		#avg_deg += node_deg[key]
	#	theFile.write( str(key) +","+ str(node_deg[key])+ "\n" )
	#theFile.close()	
	#fileCount = fileCount + 1
	
