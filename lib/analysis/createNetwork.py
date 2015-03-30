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
grnum = 1

for gr in graphArray:
	# THIS IS EXTREMELY VERBOSE ON CHROMIUM_REAL, FOR DEV DATA ONLY
	# GET LIST OF EDGES WITH THE ISSUE LISTED AS WELL
	#print '++++++++++\nThese are the connected components of each graph\n' 
	#print gr.edges(data=True)
	keys_in_1SD = []
	keys_in_2SD = []
	keys_in_3SD = []
	keys_higher_3SD = []
	keys_lower_3SD = []
	# THIS IS TO SEE A DICTIONARY OF EACH DEV_ID(key)TO THE DEGREE OF THAT DEV(value)
	#print '\n--------\n'
	node_deg = gr.degree()
	#print node_deg
	# FIND THE FIVE HIGHEST DEGREES
	max_deg1 = 0
	max_deg2 = 0
	max_deg3 = 0
	max_deg4 = 0
	max_deg5 = 0
	# initialize values to 0 
	avg_deg = 0
	count_node = 0
	variance = 0
	std_dev = 0
	oneSD_up = 0
	oneSD_down = 0
	twoSD_up = 0
	twoSD_down = 0
	thrSD_up = 0
	thrSD_down = 0
	#find maximum degree values and begin adding for mean
	for key in sorted(node_deg, key=node_deg.get, reverse=True):
		count_node += 1
		avg_deg += node_deg[key]
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
	print "For this time period : "
	# just to clear up when this is run on developer data
	# Max_deg is outdated now that we have a standard deviation
	#if max_deg1 == 0 or max_deg2 == 0 or max_deg3 == 0 or max_deg4 == 0 or max_deg5 == 0:
	#	print "Max degrees not calculated, sample sufficiently small."
	#else:
	#	print "Maximum degrees for this period: %d:%d, %d:%d, %d:%d, %d:%d, %d:%d." %( max_deg1, node_deg[max_deg1], max_deg2, node_deg[max_deg2], max_deg3, node_deg[max_deg3], max_deg4, node_deg[max_deg4], max_deg5, node_deg[max_deg5])
	
	if count_node != 0:
		# calc average degree (mean) and variance
		avg_deg = avg_deg / count_node
		for key in sorted( node_deg, key=node_deg.get, reverse=True):
			variance += (node_deg[key]-avg_deg)*(node_deg[key]-avg_deg)	
		variance = variance / count_node
		# calc standard deviations, lower cannot be negative 
		std_dev = sqrt(variance) 	
		oneSD_up = avg_deg + std_dev
		oneSD_down = avg_deg - std_dev
		if oneSD_down < 0:
			oneSD_down = 0
		twoSD_up = avg_deg + (2*std_dev)
		twoSD_down = avg_deg - (2*std_dev)
		if twoSD_down < 0:
			twoSD_down = 0
		thrSD_up = avg_deg + (3*std_dev)
		thrSD_down = avg_deg - (3*std_dev)
		if thrSD_down < 0:
			thrSD_down = 0
		print "Mean: %d, Variance: %d, Std Dev: %d" %( avg_deg, variance, std_dev )
		print "Range within 1SD: %d-%d, 2SD: %d-%d, 3SD: %d-%d" %( oneSD_up, oneSD_down, twoSD_up, twoSD_down, thrSD_up, thrSD_down) 
		for key in sorted( node_deg, key=node_deg.get, reverse=True):
			if node_deg[key] > thrSD_up:
				keys_higher_3SD.append(key)
			else:
				if node_deg[key] < thrSD_up and node_deg[key] > thrSD_down:
					keys_in_3SD.append(key)
				if node_deg[key] < twoSD_up and node_deg[key] > twoSD_down:
					keys_in_2SD.append(key)
				if node_deg[key] < oneSD_up and node_deg[key] > oneSD_down:
					keys_in_1SD.append(key)
			if thrSD_down != 0:
				if node_deg[key] < thrSD_down:
					keys_lower_3SD.append(key)
		print "Now listing degrees above 3 standard deviations: "
		for i in keys_higher_3SD:
			prnt = str(i) + ":" + str(node_deg[i]) + " ,"
			sys.stdout.write( prnt )
		print "\nNow listing degrees within 3 SD but not within 2 SD: "
		for i in keys_in_3SD:
			if i in keys_in_2SD:
				break
			prnt = str(i) + ":" + str(node_deg[i]) + " ,"
			sys.stdout.write( prnt )		
		print "\nNow listing degrees within 2 SD but not within 1 SD: "
		for i in keys_in_2SD:
			if i in keys_in_1SD:
				break
			prnt = str(i) + ":" + str(node_deg[i]) + " ,"
			sys.stdout.write( prnt )
		print "\nNow listing degrees within 1 standard deviations: "
		#for i in keys_in_1SD:
		#	prnt = str(i) + ":" + str(node_deg[i]) + " ,"
		#	sys.stdout.write( prnt )
		print "Too verbose, %d degrees are within 1 SD" %( len(keys_in_1SD) )
		print "Now listing degrees below 3 standard deviations: "
		for i in keys_lower_3SD:
			prnt = str(i) + ":" + str(node_deg[i]) + " ,"
			sys.stdout.write( prnt )	
	# NEXT STEP: connect each node (developer id) to the issues they had in this time period
	# check the % of those issues that had bugs/vulnerabilities
	# calculate the average % for each std_dev 
	else:
		print "No nodes to analyze"
	#make data json and dump to file
	#data = json_graph.node_link_data(gr)
	#with open('jsongraphs/data' + str(grnum) + '.json', 'w') as outfile:
   	#	json.dump(data, outfile)
	grnum += 1
	print "*************************************"
