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

fileCount = 1

while earlyBoundary < '2014-11-15 00:00:00.000000':
	G = nx.MultiGraph(begin=earlyBoundary,end=lateBoundary)
	# query for this time boundary
	try:
		string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary + "' AND review_date < '" + lateBoundary + "'";
		cur.execute(string)
		for row in cur:
			# add each edge between two nodes, with the issue associated
			G.add_edge( row[1], row[2], issue=row[3] )
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
	# THIS CODE IS USED TO GENERATE COMMA-DELIMITED TEXT FILES WHICH CAN BE 
	# EASILY IMPORTED INTO EXCEL FOR DISTRIBUTION ANALYZATION
	# DEGREE DISTRIBUTION FOLLOWS POWER LAW
	# adds this new graph's node_ids and degrees to a file
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
	
	# change boundaries and add G to array of graph
	earlyTime = lateTime
	lateTime += timedelta(days=61)
	earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
	graphArray.append(G)
# close the connection to the database
#if con:
#	con.close()
grnum = 1

for gr in graphArray:
	# return a dictionary of this graph's node degrees
	node_deg = gr.degree()
	num_nodes = len(node_deg)
	if num_nodes == 0:
		continue
	# move the node degree items into an ascending list of degrees for quartile ranges
	sorted_deg = OrderedDict( sorted( node_deg.items(), key=lambda(k,v):(v,k) ) )
	#length = len(sorted_deg)
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
	grnum = grnum + 1

	# now group the developers by their degree values
	qrt1_devs = []
	qrt2_devs = []
	qrt3_devs = []
	qrt4_devs = []
	qrto_devs = []	
	#print "dev and nodes: "
	#print node_deg
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
	#	sys.stdout.write(str(dev) + ": "+ str(gr.node[dev]["degree"]) + ",")
	#print "quartile 1:"
	#for elem in qrt1_devs:
	#	sys.stdout.write( str(elem) + "," )
	#print "\nquartile 2:"
	#for elem in qrt2_devs:
	#	sys.stdout.write( str(elem) + "," )
	#print "\nquartile 3:"
	#for elem in qrt3_devs:
	#	sys.stdout.write( str(elem) + "," )
	earlyBound = gr.graph["begin"]
	lateBound = gr.graph["end"]
	#print "total number of devs: " + str(len(nodes)) +"- qrt1: " + str(len(qrt1_devs)) + " qrt2: " + str(len(qrt2_devs)) + " qrt3: " + str(len(qrt3_devs)) + " outliers: " + str(len(qrto_devs))
	for elem in qrt1_devs:
		#qry_str = "SELECT owner_id, issue, created FROM code_reviews WHERE owner_id = "+ str(elem) + " AND created > " + earlyBound + " AND created <= " + lateBound	
		qry_str = "SELECT p1.dev_id, p1.owner_id, p1.issue, p1.review_date, p1.sheriff_hours, p1.security_experienced, p1.bug_security_experienced "
		qry_str = qry_str + "FROM participants p1 INNER JOIN participants p2 ON (p1.issue = p2.issue AND p1.dev_id < p2.dev_id )"
		qry_str = qry_str + " WHERE (p1.dev_id = " +str(elem) +" OR p2.dev_id = " +str(elem)+") AND  p1.review_date > '" + str(earlyBound) + "' AND p1.review_date <= '" + str(lateBound) + "'"
		cur.execute(qry_str)
		rows = 0
		shr_hrs = 0
		owns = 0
		sec_exp = 0
		bug_exp = 0
		for row in cur:
			rows = rows + 1
			shr_hrs = row[4]
			if row[0] == row[1]:
				owns = owns + 1
			sec_exp = row[5]
			bug_exp = row[6] 
		if rows != 0:
			owns = int(round( (float(owns)/float(rows)), 2) * 100)
		print "dev_id: "+str(elem)+", deg: "+str(gr.node[elem]["degree"])+", cols:"+str(rows)+" shr_hrs:"+str(shr_hrs)+" own(%):"+str(owns)+" sec/bug exp:"+str(sec_exp)+"/"+str(bug_exp)
		#sys.stdout.write( str(elem) + ":" + str(node_deg.get(elem)) + "," )

# Kayla Stuff
	#make data json and dump to file
	#data = json_graph.node_link_data(gr)
	#with open('jsongraphs/data' + str(grnum) + '.json', 'w') as outfile:
   	#	json.dump(data, outfile)
	#grnum += 1
if con:
	con.close()	
#print "*************************************"
