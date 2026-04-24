#!/usr/bin/python


#!/usr/bin/python

import socket
import time

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-n", "--nb-messages", help="nombre de messages total (100)", type=int, default=100)
parser.add_argument("-m", "--marker", help="marqueur dans la chaine (MYMARKER)", type=str, default="MYMARKER")
parser.add_argument("-b", "--batch-size", help="messages par batch (500)", type=int, default=500)
parser.add_argument("-r", "--rate", help="messages par secondes (10)", type=int, default=10)
parser.add_argument("-p", "--port", help="port de destination (514)", type=int, default=514)
parser.add_argument("-H", "--host", help="adresse ou nom cible (127.0.0.1)", type=str, default="127.0.0.1")


args = parser.parse_args()


HOST = args.host
PORT = args.port
RATE = args.rate       # logs/sec
NB = args.nb_messages # messages
BATCH_SIZE = args.batch_size
MARKER = args.marker
PRINTER_INTERVAL = 5

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((HOST, PORT))
print(f"CONNECTED. Will inject {NB} messages at {RATE}/s rate.")
start = time.time()
counter = 0
elapsed = 0
last_print_time = 0
while counter < NB:
    batch = []
    for _ in range(min(BATCH_SIZE, NB-counter)):
        counter += 1
        batch.append(f"log_>{MARKER}<_{counter} {time.time()}\n")
    
    sock.sendall("".join(batch).encode())

    # contrôle du débit
    elapsed = time.time() - start 
    advance = counter - (elapsed * RATE) 
    if elapsed >= last_print_time + PRINTER_INTERVAL:
        print (f"Elapsed: {elapsed:.0f} seconds. Sent: {counter} messages")
        last_print_time = elapsed
    if advance > 0: 
        time.sleep(advance / RATE)
    

end = time.time()
delta = end - start
sock.close()
print(f"Sent {counter} messages in {delta:.1f}s which was actually {counter / elapsed :.0f} message/s.")
