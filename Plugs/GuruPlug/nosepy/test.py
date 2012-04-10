
import tos
import tinyos.message.MoteIF
import sys
import array

am = tos.AM()

while True:
	p = am.read()
	if p:
		print p
		# data = array.array('B', p.data).tostring()

