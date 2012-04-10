
import tos
from TestSerialMsg import *
import tinyos.message.MoteIF
import sys
import array

am = tos.AM()

while True:
	p = am.read()
	if p:
		data = array.array('B', p.data).tostring()
		msg = TestSerialMsg(data)
		print msg
		print msg.get_counter()

