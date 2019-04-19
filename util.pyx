import os


save_path = 'out/'
directory = os.path.dirname(save_path)
if not os.path.exists(directory):
    os.makedirs(directory)
import cython

HOUR = 3.6e12
PREV_TIME = 0
CURR_TIME = 0

buy_orders = dict()  # order_id: [price,qty,locate_id]
stock_names = dict()  # locate_id: symbol
executed_orders = dict()  # locate_id: [price, qty, order_id,match_id]



def output_vwap(dict executed_orders, dict stock_names, CURR_TIME):
    # vwap=dict.fromkeys(stock_names.values())
    vwap=dict()
    cdef unsigned short locate_id
    cdef unsigned long long volume,vp
    
    for locate_id, trades in executed_orders.items():
        volume, vp = 0, 0
        volume =sum(trade[1] for trade in trades)
        vp = sum(trade[0]*trade[1] for trade in trades)
        symbol = stock_names[locate_id]
        if volume>0:
            vwap[symbol]=vp/(volume*1e4)
    fout = save_path+str(CURR_TIME)+".txt"
    with open(fout, "w+") as fo:
        for k, v in vwap.items():
            fo.write(str(k) + ' '+ str(v)+ '\n')

