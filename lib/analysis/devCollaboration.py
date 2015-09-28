#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# connect to the psql database, create a list of graph objects each 2 month intervals
# generates attributes for the graph's nodes (developers) and edges (collaborations)
# outputs these graphs to files in a folder "graph_degree_files" outside of chromium folder
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


def main():
	# locate database files
	con = None
	data = est_database(con)
	arr = create_graph(data.cursor())
	dev_graph(arr,data.cursor())

def est_database(con):
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
	return con

def create_graph(cur):
	# we will need to create an array of graph objects 
	# each graph object will be for a specific time frame
	graphArray = []		
	earlyBoundary = '2008-09-01 00:00:00.000000'
	earlyTime = datetime.strptime( earlyBoundary, "%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = '2008-11-01 00:00:00.000000'
	lateTime = datetime.strptime( lateBoundary, "%Y-%m-%d %H:%M:%S.%f")

	while earlyBoundary < '2014-11-06 00:00:00.000000':
		G = nx.MultiGraph(begin=earlyBoundary, end=lateBoundary)
		# query for this time boundary
		try:
			string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary + "' AND review_date < '" + lateBoundary + "'";
			cur.execute(string)
			for row in cur:
				if not row[1]==19 or row[2]==19: #remove this line if ou want to get data w/o truck factor on dev 19
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
		# change/iterate boundaries and add G to array of graph
		earlyTime = lateTime
		lateTime += timedelta(days=61)
		earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
		lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
		graphArray.append(G)
	return graphArray

def dev_graph(graphArray,cur):
	# for each graph, let's categorize developers by their degree and begin
	# to gather other useful information about them
	grnum = 0
	dirname = "graph_degree_files" 
	cur.execute("delete from developer_snapshots")
	for gr in graphArray:
		# return a dictionary for each node's degree and closeness centrality
		node_deg = gr.degree()
		closeness = nx.closeness_centrality(gr)
		betweenness = nx.betweenness_centrality(gr)_deg)
		if num_nodes == 0:
			continue
		# move the node degree items into an ascending list of degree values
		sorted_deg = OrderedDict( sorted( node_deg.items(), key=lambda(k,v):(v,k) ) )	
		for dev in sorted_deg:
			# we store degree and centrality as an attribute to the node 	
			gr.node[dev]["degree"] = sorted_deg[dev]
			gr.node[dev]["closeness"] = round( closeness[dev], 4)
			gr.node[dev]["betweenness"] = round( betweenness[dev], 8)
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
			qry_shr_hrs = "SELECT dev_id, start, duration FROM sheriff_rotations WHERE dev_id =" + str(dev) + "AND start >= '" +str(gr.graph["begin"])+ "' AND start < '" + str(gr.graph["end"]) + "'"
			cur.execute(qry_shr_hrs) 
			hrs_count = 0
			for row in cur:
				hrs_count = hrs_count + row[2]
			gr.node[dev]["shr_hrs"] = hrs_count
			# this should be writing into the database... 
			cur.execute("INSERT INTO developer_snapshots( dev_id, degree, own_count, closeness,betweenness, sheriff_hrs, sec_exp, bugsec_exp, start_date, end_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (dev, gr.node[dev]["degree"], gr.node[dev]["own_count"], gr.node[dev]["closeness"],gr.node[dev]["betweenness"], gr.node[dev]["shr_hrs"], gr.node[dev]["sec_exp"],gr.node[dev]["bugsec_exp"], gr.graph["begin"], gr.graph["end"]) )
		con.commit()
		grnum = grnum + 1
		closing(con,theFile)

def closing(con,theFile):	
	# Close all connections and files
	if con:
		con.close()
	if theFile:
		theFile.close()

if __name__ == "__main__":
	main()


