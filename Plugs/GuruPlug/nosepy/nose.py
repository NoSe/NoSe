#!/usr/bin/env python

import sys
import logging
import struct
import array
import tos
import json
import time
import socket
import select
import threading
import sqlite3
import logging

import avahi
import dbus
import logging

SERVICE_HOST = 'NoSeGateway'
SERVICE_NAME = '_NoSeService._tcp'
DB_FILE_NAME = 'test1.db'
SERVICE_PORT = 6666

"""
This software provide the following features:
    - A thread that is able to download packets from
      a TinyOS source and save data into an SQLite
      database
      
    - A simple socket server that on reception of a given
      message, return on socket the oldest record in SQLite
      database removing it
      
    - Using Avahi the socket server is exposed under name
      of _NoSeService._tcp
"""

class Controller:
    
    def start(self):
        logging.info('System starting')
        
        # Start sql recorder (download packets and save them in SQLite database)
        self.backgroundRecorder = SQLPacketRecorder(DB_FILE_NAME)
        self.backgroundRecorder.setDaemon(True)
        self.backgroundRecorder.start()

        # Turn on data provider        
        self.dataProvider = DataProvider(SERVICE_PORT, DB_FILE_NAME);
        self.dataProvider.setDaemon(True)
        self.dataProvider.start();

        logging.info('System started')

    def stop(self):
        logging.info('System closing')
        
        self.dataProvider.close();
        self.backgroundRecorder.close();
        
        self.backgroundRecorder.join();
        self.dataProvider.join();
        logging.info('System terminated')

"""
DataProvider is an background service that on reception of data from
socket, send back oldest record in SQLite database and remove it.
It uses internally DataDeleter helper class and ZeroconfService to
publish this service on network
"""

class DataProvider(threading.Thread):
    
    def __init__(self, port, dbFileName):
        threading.Thread.__init__(self)
        self.port = port
        self.dbFileName = dbFileName
        self._stop = threading.Event()

    def close(self):
        print("REQUEST to close DataProvider")
        self._stop.set()
    
    # Send length of packet and packet
    def sendPacket(self, data):
        # self.conn.send(struct.pack('B', len(data)))
        self.conn.sendall(chr(len(data)))
        self.conn.sendall(data)
        # logging.info('DataProvider:SENT: ' + data + ", len: " + repr(len(data)))
        
    def sendHello(self, num_packets):
        buffer = chr(0)
        while num_packets > 0:
            v = num_packets % 256
            num_packets = int(num_packets / 256)
            buffer = buffer + chr(v)
        buffer = buffer + chr(0)
        self.sendPacket(buffer)
            
    def run(self):
        
        s = None
        
        for res in socket.getaddrinfo(None, self.port, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
            af, socktype, proto, canonname, sa = res
            try:
                logging.info('DataProvider:Starting server')
                s = socket.socket(af, socktype, proto)
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)        
            except socket.error as msg:
                s = None
                continue
            try:
                s.bind(sa)
                s.listen(1)
            except socket.error as msg:
                s.close()
                s = None
                continue
            break
        
        if s is None:
            logging.error('DataProvider:Could not open socket')
            return
        
        service = ZeroconfService(name=SERVICE_HOST, port=self.port)
        service.publish()

        while not self._stop.isSet():
            
            r, w, e = select.select([s], [], [], 0.5)
            if not s in r:
                continue

            try:
                self.conn, addr = s.accept()
                logging.info('DataProvider:Connected by: ' + json.dumps(addr))

                data = self.conn.recv(1024)
                if not data: break
                logging.info('DataProvider:Received: ' + data)
                
                # Open connection with data deleter        
                dataDeleter = DataDeleter(self.dbFileName)
                dataDeleter.open()

                # 1 packet missing
                num_packets = dataDeleter.getNumPackets()
                
                if num_packets > 1000:
                    num_packets = 1000

                logging.info('DataProvider:will send: ' + str(num_packets) + ' packets')

                # Send Hello (type: 0)
                self.sendHello(num_packets)
                                    
                for i in range(0, num_packets):
                    obj = dataDeleter.getOldestPacket();
                    msg = json.dumps(obj)
                    self.sendPacket(msg)
                    data = self.conn.recv(1)
                    dataDeleter.removePacket(obj);
                    logging.info('DataProvider:remaining: ' + str(dataDeleter.getNumPackets()) + ' packets')
                    

                # close connection with data deleter
                dataDeleter.close();
    
                logging.info('DataProvider:Disconnected: ' + json.dumps(addr))
                self.conn.close()

            except:
                logging.error('DataProvider:error in connection: detach client')
                continue

        service.unpublish()

"""
DataDeleter is an helper class that get oldest record in SQLite database
and return it after removal
"""

class DataDeleter:
    
    def __init__(self, dbFileName):
        self.dbFileName = dbFileName
        
    def open(self):
        logging.info('DataDeleter:open connection to DB: ' + self.dbFileName)
        self.connection = sqlite3.connect(self.dbFileName)
        self.cursor = self.connection.cursor()

    def close(self):
        self.cursor.close();
        self.connection.close();
        logging.info('DataDeleter:closed connection to DB: ' + self.dbFileName)

    def dumpRows(self):
        self.cursor.execute('SELECT count(*) FROM packets')
        row = self.cursor.fetchone();
        logging.info("DataDeleter:Num rows: " + repr(self.getNumPackets()))
        
    def getNumPackets(self):
        self.cursor.execute('SELECT count(*) FROM packets')
        row = self.cursor.fetchone();
        if row:
            return row[0]
        return 0
        
    def dumpRow(self, obj):
        logging.info('DataDeleter:' + json.dumps(obj))
        
    def insertFakeData(self):
        data = json.dumps([1, 2, 3, 4, 5])
        self.cursor.execute('INSERT INTO packets VALUES (null, ?, ?)', ("Fake", data))
        self.connection.commit();
        logging.info('DataDeleter:Packet received: ' + data)
        
    def getOldestPacket(self):
        self.cursor.execute('SELECT min(id) FROM packets')
        row = self.cursor.fetchone();
        id = row[0]

        if not id:
            logging.warning('DataDeleter:No Data')
            return None
        
        self.cursor.execute('SELECT * FROM packets WHERE id = ?', (repr(id),))
        obj = self.cursor.fetchone()
        return obj
    
    def removePacket(self, packet):
        if not packet:
            return
        
        id = packet[0]
        if not id:
            return
        
        self.cursor.execute('DELETE FROM packets WHERE id = ?', (repr(id),))
        self.connection.commit()
        # logging.info("DataDeleter:Removed: " + repr(id))

"""
    def downloadAndDelete(self):
        self.dumpRows();
    
        self.cursor.execute('SELECT min(id) FROM packets')
        row = self.cursor.fetchone();
        id = row[0]

        if not id:
            logging.warning('DataDeleter:No Data')
            print ''
            return
        
        logging.info("DataDeleter:Removing: " + repr(id))

        self.cursor.execute('SELECT * FROM packets WHERE id = ?', (repr(id),))
        obj = self.cursor.fetchone()
        self.dumpRow(obj)

        self.cursor.execute('DELETE FROM packets WHERE id = ?', (repr(id),))
        self.connection.commit()

        logging.info("DataDeleter:Removed: " + repr(id))

        self.dumpRows();
        return obj;
"""

"""
ZeroconfService is a simple class to publish a network service
with zeroconf using avahi and dbus.
"""

class ZeroconfService:

    def __init__(self, name, port, stype=SERVICE_NAME, domain="", host="", text=""):
        self.name = name
        self.stype = stype
        self.domain = domain
        self.host = host
        self.port = port
        self.text = text

    def publish(self):
        logging.info('ZeroconfService:publishing service - ' + self.stype + ' - ' + self.name)
        bus = dbus.SystemBus()
        server = dbus.Interface(
                         bus.get_object(
                                 avahi.DBUS_NAME,
                                 avahi.DBUS_PATH_SERVER),
                        avahi.DBUS_INTERFACE_SERVER)

        g = dbus.Interface(
                    bus.get_object(avahi.DBUS_NAME,
                                   server.EntryGroupNew()),
                    avahi.DBUS_INTERFACE_ENTRY_GROUP)

        g.AddService(avahi.IF_UNSPEC, avahi.PROTO_UNSPEC,dbus.UInt32(0),
                     self.name, self.stype, self.domain, self.host,
                     dbus.UInt16(self.port), self.text)

        g.Commit()
        self.group = g

        logging.info('ZeroconfService:published')

    def unpublish(self):
        self.group.Reset()
        logging.info('ZeroconfService:unpublished service - ' + self.stype + ' - ' + self.name)

"""
SQLPacketRecorder is a simple daemon that is connected to TOS
specified in parameters that save on local SQLite database any
packet received
"""

class SQLPacketRecorder(threading.Thread):

    def __init__(self, dbFileName):
        threading.Thread.__init__(self)

        self._stop = threading.Event()
        self.dbFileName = dbFileName

        logging.info('Connectect to packet source: ' + sys.argv[1])
        self.am = tos.AM()
    
    def close(self):
        self._stop.set()

    def run(self):

        # Create Sql lite connection
        logging.info('SQLPacketRecorder:Connectect to SQLite: ' + self.dbFileName)
        self.connection = sqlite3.connect(self.dbFileName)

        # Cursor to database    
        self.cursor = self.connection.cursor()

        # Create table
        logging.info('SQLPacketRecorder:Prepare DB')
        self.cursor.execute('CREATE TABLE IF NOT EXISTS packets (id INTEGER PRIMARY KEY, description VARCHAR(50), data VARCHAR(200))')

        self.cursor.execute('SELECT count(*) FROM packets')
        row = self.cursor.fetchone();
        if row:
            logging.info('Packets in DB: ' + row[0])
        else:
            logging.info('Packets in DB: 0')
        
        logging.info('SQLPacketRecorder:Start receiving packets')
        while not self._stop.isSet():
            
            p = self.am.read(0.5)

            if p:
                while True:
                    data = json.dumps(p.data)
                    logging.info('SQLPacketRecorder:Packet received: ' + data)
                    
                    try:
                        self.cursor.execute('INSERT INTO packets VALUES (null, ?, ?)', ("Packet", data))
                        self.connection.commit();
                        break
                    except:
                        logging.error('Error in saving packet: retry...')

        # Close connection
        logging.info('SQLPacketRecorder:Closing connection')
        self.cursor.close();
        self.connection.close();

if '-h' in sys.argv:
    print("Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600")
    print("      ", sys.argv[0], "network@host:port")
    sys.exit()

############################################################
# Main
############################################################

# Setup log level
logging.basicConfig(level=logging.DEBUG)

controller = Controller()
controller.start()

while True:
    count = 0    
#time.sleep( 100 )

controller.stop()


