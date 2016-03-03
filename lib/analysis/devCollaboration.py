#!/usr/bin/python
# -*- coding: utf-8 -*-

# Samantha Oxley & Kayla Davis
# Refactored by: Kayla Nussbaum
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
	username = sys.argv[1]
	db = sys.argv[2]
	
	# establish connection with the database
	data = est_connection(username, db)
	# this will do every query necessary to build the bones of the graph
	array = create_graph_array(data.cursor())
	# after initial queries are complete, extrapolate some information
	# from the structure 
	finished_array = graph_extrapolate(array)
	# now we simply push the data from the graph into the table
	dev_graph(finished_array, data.cursor(), data)

def est_connection(username, db):
	# connection to database 
	con = None
	try:
		con = psycopg2.connect(database=db, user=username)
	except psycopg2.DatabaseError, e:
		print 'Error %s' % e
		sys.exit(1)
	return con

def create_graph_array(cur):
	# we will need to create an array of graph objects 
	# each graph object will be for a specific time frame
	graphArray = []		
	earlyBoundary = '2008-09-01 00:00:00.000000'
	earlyTime = datetime.strptime( earlyBoundary, "%Y-%m-%d %H:%M:%S.%f")
	lateBoundary = '2010-01-26 00:00:00.000000'
	lateTime = datetime.strptime( lateBoundary, "%Y-%m-%d %H:%M:%S.%f")

	while earlyBoundary < '2014-11-06 00:00:00.000000':
		thisGraph = nx.MultiGraph(begin=earlyBoundary, end=lateBoundary)
		# query for this time boundary
		try:
			string = "SELECT * FROM adjacency_list WHERE review_date >= '" + earlyBoundary 
			string = string + "' AND review_date < '" + lateBoundary + "'";
			
			cur.execute(string)
			for row in cur:
				# add each edge between two nodes, with the issue amd issue_owner
				thisGraph.add_edge( row[1], row[2], issue=row[4], issue_owner=row[3] )
				# add atrributes for whether or not this developer is experienced
				thisGraph.node[row[1]]["sec_exp"] = row[6]
				thisGraph.node[row[1]]["bugsec_exp"] = row[10]
				thisGraph.node[row[1]]["missed_vuln"] = 0
				thisGraph.node[row[1]]["missed_vuln_6mo"] = 0
				thisGraph.node[row[1]]["fixed_vuln_own"] = 0
				thisGraph.node[row[1]]["fixed_vuln"] = 0
				thisGraph.node[row[2]]["sec_exp"] = row[7]
				thisGraph.node[row[2]]["bugsec_exp"] = row[11]
				thisGraph.node[row[2]]["missed_vuln"] = 0
				thisGraph.node[row[2]]["missed_vuln_6mo"] = 0
				thisGraph.node[row[2]]["fixed_vuln_own"] = 0
				thisGraph.node[row[2]]["fixed_vuln"] = 0
		except psycopg2.DatabaseError, e:
			print 'Error %s' % e
			sys.exit(1)
		qry_mv = "SELECT DISTINCT ON(code_reviews_cvenums.cvenum_id, code_reviews.issue, missed_code_reviews.issue, participants.dev_id) "
		qry_mv = qry_mv + "code_reviews_cvenums.cvenum_id, code_reviews.issue, fix_commits.created_at, missed_code_reviews.issue, missed_commits.created_at, participants.dev_id, missed_commit_filepaths.filepath "
		qry_mv = qry_mv + "FROM code_reviews INNER JOIN code_reviews_cvenums ON code_reviews.issue = code_reviews_cvenums.code_review_id "
		qry_mv = qry_mv + "INNER JOIN commits AS fix_commits ON code_reviews.commit_hash = fix_commits.commit_hash "
		qry_mv = qry_mv + "INNER JOIN commit_filepaths AS fix_commit_filepaths  ON fix_commits.commit_hash = fix_commit_filepaths.commit_hash "
		qry_mv = qry_mv + "INNER JOIN commit_filepaths AS missed_commit_filepaths ON missed_commit_filepaths.filepath = fix_commit_filepaths.filepath "
		qry_mv = qry_mv + "INNER JOIN commits AS missed_commits ON missed_commits.commit_hash = missed_commit_filepaths.commit_hash AND missed_commits.created_at >= (fix_commits.created_at - interval '6 months') AND missed_commits.created_at < fix_commits.created_at "
		qry_mv = qry_mv + "INNER JOIN code_reviews AS missed_code_reviews ON missed_code_reviews.commit_hash = missed_commits.commit_hash "
		qry_mv = qry_mv + "INNER JOIN participants ON participants.issue = missed_code_reviews.issue "
		qry_mv = qry_mv + "WHERE missed_code_reviews.created >= '" + earlyBoundary+ "' AND missed_code_reviews.created < '" + lateBoundary + "' "
		qry_mv = qry_mv + "ORDER BY code_reviews_cvenums.cvenum_id, code_reviews.issue, missed_code_reviews.issue, participants.dev_id"
		
		cur.execute(qry_mv)
		for row in cur:
			if thisGraph.has_node(row[5]):
				thisGraph.node[row[5]]["missed_vuln_6mo"] = int(thisGraph.node[row[5]]["missed_vuln_6mo"]) + 1
		# COUNT ONLY WITHIN 6 MONTHS
		qry_mv = "SELECT DISTINCT ON(code_reviews_cvenums.cvenum_id, code_reviews.issue, missed_code_reviews.issue, participants.dev_id) "
		qry_mv = qry_mv + "code_reviews_cvenums.cvenum_id, code_reviews.issue, fix_commits.created_at, missed_code_reviews.issue, missed_commits.created_at, participants.dev_id, missed_commit_filepaths.filepath "
		qry_mv = qry_mv + "FROM code_reviews INNER JOIN code_reviews_cvenums ON code_reviews.issue = code_reviews_cvenums.code_review_id "
		qry_mv = qry_mv + "INNER JOIN commits AS fix_commits ON code_reviews.commit_hash = fix_commits.commit_hash "
		qry_mv = qry_mv + "INNER JOIN commit_filepaths AS fix_commit_filepaths  ON fix_commits.commit_hash = fix_commit_filepaths.commit_hash "
		qry_mv = qry_mv + "INNER JOIN commit_filepaths AS missed_commit_filepaths ON missed_commit_filepaths.filepath = fix_commit_filepaths.filepath "
		qry_mv = qry_mv + "INNER JOIN commits AS missed_commits ON missed_commits.commit_hash = missed_commit_filepaths.commit_hash AND missed_commits.created_at >= (fix_commits.created_at - interval '1 year') AND missed_commits.created_at < fix_commits.created_at "
		qry_mv = qry_mv + "INNER JOIN code_reviews AS missed_code_reviews ON missed_code_reviews.commit_hash = missed_commits.commit_hash "
		qry_mv = qry_mv + "INNER JOIN participants ON participants.issue = missed_code_reviews.issue "
		qry_mv = qry_mv + "WHERE missed_code_reviews.created >= '" + earlyBoundary+ "' AND missed_code_reviews.created < '" + lateBoundary + "' "
		qry_mv = qry_mv + "ORDER BY code_reviews_cvenums.cvenum_id, code_reviews.issue, missed_code_reviews.issue, participants.dev_id"
		
		cur.execute(qry_mv)
		for row in cur:
			if thisGraph.has_node(row[5]):
				thisGraph.node[row[5]]["missed_vuln"] = int(thisGraph.node[row[5]]["missed_vuln"]) + 1


		# COUNT FIX REVIEW OWNERSHIPS
		qry_mv = "SELECT cvenum_id, issue, owner_id, created FROM "
		qry_mv = qry_mv + "code_reviews INNER JOIN code_reviews_cvenums ON code_reviews.issue = code_reviews_cvenums.code_review_id "
		qry_mv = qry_mv + "WHERE created >= '" + earlyBoundary + "' AND created < '" + lateBoundary + "' "
		qry_mv = qry_mv + "ORDER BY cvenum_id, issue desc"	
		cur.execute(qry_mv)
		for row in cur:
			if thisGraph.has_node(row[3]):
				thisGraph.node[row[3]]["fixed_vuln_own"] = int(thisGraph.node[row[3]]["fixed_vuln_own"]) + 1	

		# COUNT PARTICIPATIONS ON THESE COMMITS
		qry_mv = "SELECT cvenum_id, code_reviews.issue, code_reviews.owner_id, dev_id, created, review_date FROM "
		qry_mv = qry_mv + "code_reviews INNER JOIN code_reviews_cvenums ON code_reviews.issue = code_reviews_cvenums.code_review_id "
		qry_mv = qry_mv + "INNER JOIN participants ON participants.issue = code_reviews.issue "
		qry_mv = qry_mv + "WHERE created >= '" + earlyBoundary + "' AND created < '" + lateBoundary + "' "
		qry_mv = qry_mv + "ORDER BY cvenum_id, issue desc"	
		cur.execute(qry_mv)
		for row in cur:
			if thisGraph.has_node(row[4]):
				thisGraph.node[row[4]]["fixed_vuln"] = int(thisGraph.node[row[4]]["fixed_vuln"]) + 1
		
		# COUNT SHERIFF HOURS
		for dev in nx.nodes(thisGraph):
			# query for the developer's sheriff hours IN THIS TIME PERIOD
			qry_shr_hrs = "SELECT dev_id, start, duration FROM sheriff_rotations WHERE dev_id =" 
			qry_shr_hrs = qry_shr_hrs + str(dev) + "AND start >= '" +earlyBoundary+ "' AND start < '" + lateBoundary + "'"
			
			cur.execute(qry_shr_hrs) 
			hrs_count = 0
			for row in cur:
				hrs_count = hrs_count + row[2]
			thisGraph.node[dev]["shr_hrs"] = hrs_count			
		# change/iterate boundaries and add G to array of graph
		earlyTime = lateTime
		lateTime += timedelta(days=365)
		earlyBoundary = earlyTime.strftime("%Y-%m-%d %H:%M:%S.%f")
		lateBoundary = lateTime.strftime("%Y-%m-%d %H:%M:%S.%f")
		graphArray.append(thisGraph)
	return graphArray

def graph_extrapolate( graphArray ):
	for graph in graphArray:
		# get dictionaries for all of these attributes per developer (node)	
		node_deg = graph.degree()
		closeness = nx.closeness_centrality(graph)
		betweenness = nx.betweenness_centrality(graph)

		for dev in node_deg:
			# we store degree and centrality as an attribute to the node 	
			graph.node[dev]["degree"] = node_deg[dev]
			graph.node[dev]["closeness"] = round( closeness[dev], 4)
			graph.node[dev]["betweenness"] = round( betweenness[dev], 8)
			owner_count = 0
			hrs_count = 0
			unique_issues = []
			# for each unique issue on this dev, how many of them does 
			# this developer own?
			for edge in list(graph.edges_iter(dev, data=True)):
				if edge[2]["issue"] in unique_issues:
					continue
				unique_issues.append(edge[2]["issue"])
				if dev == edge[2]["issue_owner"]:
					owner_count = owner_count + 1
			graph.node[dev]["own_count"] = owner_count
	return graphArray

def dev_graph(graphArray, cur, con ):
	# for each graph, let's categorize developers by their degree and begin
	# to gather other useful information about them
	cur.execute("delete from developer_snapshots")
	for gr in graphArray:
		for dev in nx.nodes(gr): 	
			has_hours = 0
			if(gr.node[dev]["shr_hrs"] != 0):
				has_hours = 1
			# this should be writing into the database... 
			cur.execute("INSERT INTO developer_snapshots( dev_id, degree, own_count, closeness, betweenness, sheriff_hrs, has_sheriff_hrs, vuln_misses_1yr, vuln_misses_6mo, vuln_fixes_owned, vuln_fixes, perc_missed_vuln, sec_exp, bugsec_exp, start_date, end_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (dev, gr.node[dev]["degree"], gr.node[dev]["own_count"], gr.node[dev]["closeness"],gr.node[dev]["betweenness"], gr.node[dev]["shr_hrs"], has_hours, gr.node[dev]["missed_vuln"], gr.node[dev]["missed_vuln_6mo"], gr.node[dev]["fixed_vuln_own"], gr.node[dev]["fixed_vuln"], 0.0, gr.node[dev]["sec_exp"],gr.node[dev]["bugsec_exp"], gr.graph["begin"], gr.graph["end"]) )
		con.commit()
	closing(con) 

def closing(con): 	
	# Close all connections and files
	if con:
		con.close()

if __name__ == "__main__":
	main()


