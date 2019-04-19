from os.path import getsize, dirname, realpath
import mmap
from sys import argv
from time import time
import pyximport
pyximport.install()
import util
import cython
from parser import *


if __name__=='__main__':
    # if user provided the path to the ITCH file:
    if len(argv)>1:
        path = argv[1]
    else:
    #use local file
        path = dirname(realpath(__file__))+'01302019.NASDAQ_ITCH50'
        

    file = open(path, 'rb')
    f_size = getsize(path)
    f = mmap.mmap(file.fileno(), f_size, access=mmap.ACCESS_READ)
    msg_size = int.from_bytes(f.read(2),'big')

    print('start')

    now = time()

    while msg_size:
        message = f.read(msg_size)
        message_type = chr(message[0])

        # only tracking messages that will impact VWAP

        if message_type == "S":
            if chr(message[11])=='C':
                util.CURR_TIME = int.from_bytes(message[5:11], 'big')
                print('end of day')
                util.output_vwap(util.executed_orders, util.stock_names, util.CURR_TIME)
                exit()

        elif message_type == "R":
            stock_directory_message(message)

        # only tracking buy orders to avoid duplicates
        elif message_type == "A":
            if chr(message[19]) == 'B':
                add_order_no_mpid(message)

        elif message_type == "F":
            if chr(message[19]) == 'B':
                add_order_no_mpid(message[:36])

        elif message_type == "E":
            order_executed_message(message)

        elif message_type == "C":
            # Nasdaq recommends that firms ignore messages
            # marked as non-printable to prevent double counting.
            if not chr(message[31]) == 'N':
                order_executed_price_message(message)

        elif message_type == "X":
            order_cancel_message(message)

        elif message_type == "D":
            order_delete_message(message)

        elif message_type == "U":
            order_replace_message(message)

        elif message_type == "P":
            if chr(message[19])=='B':
                trade_message(message)

        elif message_type == "Q":
            cross_trade_message(message)


        elif message_type == "B":
            broken_trade_execution_message(message)


        if util.CURR_TIME - util.PREV_TIME >= util.HOUR:
            util.PREV_TIME = util.CURR_TIME
            print('It is now ', int(util.CURR_TIME/util.HOUR),'hours from midnight', f.tell())
            util.output_vwap(util.executed_orders, util.stock_names, util.CURR_TIME)
            
        try:
            msg_size = int.from_bytes(f.read(2),'big')
        except KeyboardInterrupt:
            exit()
        except:
            continue

    print('Used time:',int(time()-now))


# 5833 seconds
