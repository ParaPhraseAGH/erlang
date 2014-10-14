from __future__ import division
from collections import Counter
import csv

WORKERS = 4

def read_file(filename):
	data = []
	with open(filename) as csv_file:
		reader = csv.reader(csv_file)
		for row in reader:
			c = Counter(row[:-1]).values()

			diff = WORKERS - len(c)
			if diff != 0:
				c.extend([0] * diff)

			gini_coef = gini(c)
			print c, gini_coef

			data.append(gini_coef)
	return data

def gini(list_of_values):
	sorted_list = sorted(list_of_values)
	height, area = 0, 0
	for value in sorted_list:
		height += value
		area += height - value / 2.
	fair_area = height * len(list_of_values) / 2
	return (fair_area - area) / fair_area

def main():
	data = read_file('arenas12.csv')
	print max(data), min(data)
	print sum(data) / len(data)

main()