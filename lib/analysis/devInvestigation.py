#!/usr/bin/python
# -*- coding: utf-8 -*-

# Author: Kayla Nussbaum

# Connect to the psql database.
# Runs a series of queries to show manual investigation of how
# developers are interacting with their code commits, missed 
# vulnerabilities, and sheriff hours over a give time period on
# selected issues.

# ARGUMENTS: [developer] [time period ("yyyy-mm-mm hh:mm:ss")] 

import psycopg2
import sys, getopt
import networkx as nx
from datetime import datetime, timedelta


def main():
	# open database files
	username = sys.argv[1]
	db = sys.argv[2]

	#connection to database
	conn = psycopg2.connect(database=db, user=username)
	curs = conn.cursor()
	dateStart = input("Start Date (yyyy-mm-dd 00:00:00.000000): ")
	dateEnd = input("End Date (yyyy-mm-dd 00:00:00.000000): ")
	closeCon(conn)


def viewCentrality(dateStart, dateEnd, curs):
	# taking in a cursor for the connection to db
	# comparing sheriff hours to centrality
	central = " SELECT * FROM developer_snapshots 
			ORDER BY closeness desc 
			AND ORDER BY sheriff_hrs desc "
	curs.execute(central)
	

def viewBetweenness(dateStart, dateEnd, curs):
	between = " SELECT * FROM developer_snapshots
			ORDER BY betweenness desc
			AND ORDER BY sheriff_hrs desc "
	curs.execute(central)
	

def devInvestigate(dateStart, dateEnd, curs):
	dev = input("Dev ID: ")
	correlations = " SELECT * FROM developer_snapshots 
				WHERE dev_id = " +dev+ "
				"
	curs.execute(correlations)




"""

Closing the database connection
conn = database connection

"""
def closeCon(conn):
	if conn:
		con.close()


if __name__ == "__main__":
	main()



 
