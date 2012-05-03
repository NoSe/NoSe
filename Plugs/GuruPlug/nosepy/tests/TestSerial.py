#!/usr/bin/env python

import sys
import tos
import threading
import time

class TestMsg(tos.Packet):
	def __init__(self, packet = None):
		tos.Packet.__init__(self, [('counter', 'int', 2)], packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    print "      ", sys.argv[0], "network@host:port"
    sys.exit()


class DataSender(threading.Thread):

	def __init__(self):
		threading.Thread.__init__(self)
		self.am = tos.AM()

	def run(self):
		self.pack = TestMsg()
		self.pack.counter = 0
		while True:
			try:
				self.am.write(self.pack, 137, 1000, True)
				# print "Sent: ", self.pack.counter
				self.pack.counter = self.pack.counter + 1
			except:
				print "Error in sending"

class DataReceiver(threading.Thread):

	def __init__(self):
		threading.Thread.__init__(self)
		self.am = tos.AM()

	def run(self):
		while True:
			try:
				p = self.am.read()
				if p:
					if isinstance(p, tos.ActiveMessage):
						if p.type == 137:
							p1 = TestMsg(p.data)
							print "Received: ", p1.counter
					else:
						print p
			except:
				print "Error in receiving"

dataSender = DataSender();
dataSender.setDaemon(True)
dataSender.start();

dataReceiver = DataReceiver();
dataReceiver.setDaemon(True)
dataReceiver.start();

while True:
	count = 0    

