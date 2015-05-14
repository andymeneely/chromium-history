#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database, create a list of graph objects
# generates attributes for the graphs and outputs to a bunch of files
# ARGUMENTS: [username] [database name]

from  math import sqrt
import psycopg2
import sys, getopt
import json
import networkx as nx
import os
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

while earlyBoundary < '2014-11-06 00:00:00.000000':
	G = nx.MultiGraph(begin=earlyBoundary, end=lateBoundary)
	# query for this time boundary
	try:
		string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary + "' AND review_date < '" + lateBoundary + "'";
		cur.execute(string)
		for row in cur:
			# add each edge between two nodes, with the issue amd issue_owner
			G.add_edge( row[1], row[2], issue=row[4], issue_owner=row[3] )
			# add atrributes for whether or not this developer is experienced
			G.node[row[1]]["sec_exp"] = row[6]
			G.node[row[1]]["bugsec_exp"] = row[10]
			G.node[row[2]]["sec_exp"] = row[7]
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
# for each graph, let's categorize developers by their degree and begin
# some analysis
grnum = 0
dirname = "graph_degree_files" 
for gr in graphArray:
	# what is done in this loop will be written to an appropriate file for each graph
	if not os.path.exists("../../../../"+dirname):
    		os.makedirs("../../../../"+dirname)
	theFile = open( "../../../../"+dirname+"/graph" +str(grnum)+ ".csv" , 'w' )
	theFile.write( "Graph: " +gr.graph["begin"]+ ", " +gr.graph["end"]+ "\n" )

	# return a dictionary for each node's degree and closeness centrality
	node_deg = gr.degree()
	centrality = nx.closeness_centrality(gr)
	num_nodes = len(node_deg)
	# skip if this graph has no nodes for some reason
	if num_nodes == 0:
		continue
	# move the node degree items into an ascending list of degrees for quartile ranges
	sorted_deg = OrderedDict( sorted( node_deg.items(), key=lambda(k,v):(v,k) ) )
	# print to screen if you want to see what's up in real time
	#print "\nFor graph #" + str(grnum) + " IN TIME FRAME: " + gr.graph["begin"] + " UNTIL " + gr.graph["end"]

	# column names for the data we will write to the file
	theFile.write("dev_id, degree, centrality, shriff_hrs, sec_exp, bugsec_exp, own_count, start_date, end_date\n") 
	for dev in sorted_deg:
		# we store degree and centrality as an attribute to the node 	
		gr.node[dev]["degree"] = sorted_deg[dev]
		gr.node[dev]["centrality"] = round( centrality[dev], 4)
		owner_count = 0
		hrs_count = 0
		unique_issues = []
		# for each unique issue on this dev, how many of them does 
		# this developer own?
		for edge in list(gr.edges_iter(dev, data=True)):
			if edge[2]["issue"] in unique_issues:
				continue
			unique_issues.append(edge[2]["issue"])
			if dev == edge[2]["issue_owner"]:
				owner_count = owner_count + 1
			gr.node[dev]["own_count"] = owner_count
		# query for the developer's sheriff hours IN THIS TIME PERIOD
		qry_shr_hrs = "SELECT * FROM sheriff_rotations WHERE dev_id =" + str(dev) + "AND start >= '" +str(gr.graph["begin"])+ "' AND start < '" + str(gr.graph["end"]) + "'"
		cur.execute(qry_shr_hrs) 
		hrs_count = 0
		for row in cur:
			hrs_count = hrs_count + row[3]
		gr.node[dev]["shr_hrs"] = hrs_count	
		# at this point we have everything we need stored as an attribute
		# to each developer node, now we write to the file with this dev's info
		theFile.write(str(dev)+","+str(gr.node[dev]["degree"])+","+str(gr.node[dev]["centrality"])+","+str(gr.node[dev]["shr_hrs"])+","+str(gr.node[dev]["sec_exp"])+","+str(gr.node[dev]["bugsec_exp"])+","+str(gr.node[dev]["own_count"])+","+str(gr.graph["begin"])+","+str(gr.graph["end"])+"\n")
		# print to screen to check values
		#print "dev_id:%d, dev_deg:%d, centrality:%f, sher_hrs:%d, sec_exp:%s, bugsec_exp:%s, own_count:%d" %(dev, gr.node[dev]["degree"],gr.node[dev]["centrality"], gr.node[dev]["shr_hrs"], gr.node[dev]["sec_exp"], gr.node[dev]["bugsec_exp"], gr.node[dev]["own_count"])
	grnum = grnum + 1	
# Close all connections and files
if con:
	con.close()
if theFile:
	theFile.close()

# THIS CODE IS NO LONGER USEFUL, WILL BE DELETED SOON
#median = 0
	#low_quart = 0
	#upper_quart = 0
	#outlier_quart = 0
	#sorted_deg_values = sorted_deg.values()
	#if ( num_nodes % 2 ) == 0:
	#	mid_lo = (num_nodes / 2) - 1
	#	mid_hi = num_nodes / 2
	#	median = (sorted_deg_values[mid_lo] + sorted_deg_values[mid_hi])/2
	#else:
	#	median = sorted_deg_values[ ((num_nodes + 1) / 2)-1 ]
	#low_mid = int( round( (num_nodes+1)/4 )-1 )
	#low_quart = sorted_deg_values[low_mid]
	#high_mid = int( round( (num_nodes-1)*0.75 ) )
	#upper_quart = sorted_deg_values[high_mid]
	#outlier_quart = upper_quart * 3
#print "lower q:%d , median: %d, upper q:%d, outlier q:%d" %( low_quart, median, upper_quart, outlier_quart) 
	# now group the developers by their degree values
	#qrt1_devs = []
	#qrt2_devs = []
	#qrt3_devs = []
	#qrt4_devs = []
	#qrto_devs = []	
	#	if sorted_deg[dev] <= low_quart:
	#		#qrt1_devs.append(dev)
	#		gr.node[dev]["qrtl"] = 1	
	#	elif sorted_deg[dev] <= median:
	#		#qrt2_devs.append(dev)
	#		gr.node[dev]["qrtl"] = 2
	#	elif sorted_deg[dev] <= upper_quart:
	#		#qrt3_devs.append(dev)
	#		gr.node[dev]["qrtl"] = 3
	#	elif sorted_deg[dev] <= outlier_quart:
	#		#qrt4_devs.append(dev)
	#		gr.node[dev]["qrtl"] = 4
	#	else:
	#		#qrto_devs.append(dev) 
	#		gr.node[dev]["qrtl"] = 5
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
	#for elem in qrto_devs:

