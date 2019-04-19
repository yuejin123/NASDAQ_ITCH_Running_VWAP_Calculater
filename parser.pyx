from struct import unpack
import util


def stock_directory_message(msg):
    cdef unsigned short locate_id = int.from_bytes(msg[1:3],'big')
    stock_name = msg[11:19].decode('ascii','ignore').strip()
    util.stock_names[locate_id]= stock_name
    util.executed_orders[locate_id]=[]


def add_order_no_mpid(msg):

    cdef unsigned short locate_id
    cdef unsigned long long order_id
    cdef unsigned int qty, price

    util.CURR_TIME = int.from_bytes(msg[5:11], 'big')
    _,locate_id, _, _, order_id, _, qty, _, price = unpack('>sHH6sQsI8sI', msg)
    util.buy_orders[order_id] = [price, qty, locate_id]


def order_executed_message(msg):
    util.CURR_TIME = int.from_bytes(msg[5:11],'big')
    cdef unsigned short locate_id
    cdef unsigned long long order_id, match_id
    cdef unsigned int qty,price

    _,locate_id, _, _, order_id, qty, match_id = unpack('>sHH6sQIQ', msg)
    try:
        price, qty_, _ = util.buy_orders.get(order_id)
        if qty_ > qty:
            util.buy_orders.update({order_id: [price, qty_ - qty, locate_id]})
        else:
            del util.buy_orders[order_id]

        
        util.executed_orders[locate_id] = [[price, qty, 0, match_id]]
        
    except:
        return



def order_executed_price_message(msg):

    cdef unsigned short locate_id
    cdef unsigned long long order_id, match_id
    cdef unsigned int qty,price, qty_,price_
    util.CURR_TIME = int.from_bytes(msg[5:11], 'big')
    if str(chr(msg[31])) == 'N': return
    _,locate_id, _, _, order_id, qty, match_id, _, price = unpack('>sHH6sQIQsI', msg)
    # price = float(price)/1e4
    try:
        price_, qty_, _ = util.buy_orders.get(order_id)
        if qty_ > qty:
            util.buy_orders.update({order_id: [price_, qty_ - qty, locate_id]})
        else:
            del util.buy_orders[order_id]
        
        util.executed_orders[locate_id] = [[price, qty, 0, match_id]]
        
    except:
        return


def order_cancel_message(msg):
    cdef unsigned long long order_id
    cdef unsigned int qty
    
    order_id, qty = unpack(">QI", msg[11:23])

    # util.CURR_TIME = int.from_bytes(msg[5:11], 'big')

    if util.buy_orders.get(order_id) is not None:
        util.buy_orders[order_id][1]=util.buy_orders[order_id][1]-qty
        if util.buy_orders[order_id][1] <=0:
            del util.buy_orders[order_id]
    else:
        return


def order_delete_message(msg):
    util.buy_orders.pop(int.from_bytes(msg[11:19],'big'),None)
    

def order_replace_message(msg):
    cdef unsigned short locate_id
    cdef unsigned long long old_order_id, new_order_id
    cdef unsigned int qty,price

    # util.CURR_TIME = int.from_bytes(msg[4:10],'big')
    _,locate_id, _, _, old_order_id, new_order_id, qty, price = unpack('>sHH6sQQII', msg)
    util.buy_orders.pop(old_order_id,None)
    util.buy_orders[new_order_id] = [price, qty, locate_id]
    

def trade_message(msg):
    # Trade Messages should be included in Nasdaq time--­and--­sales displays
    # as well as volume and other market statistics.
    # side should always be 'B' and order number is populated with 0
    cdef unsigned short locate_id
    cdef unsigned long long order_id, match_id
    cdef unsigned int qty,price


    util.CURR_TIME = int.from_bytes(msg[5:11], 'big')
    locate_id = int.from_bytes(msg[1:3],'big')

    qty, _, price, match_id = unpack('>I8sIQ', msg[20:])
    util.executed_orders[locate_id] = [[price, qty, 0, match_id]]
    

def cross_trade_message(msg):
    cdef unsigned short locate_id
    cdef unsigned long long order_id, match_id
    cdef unsigned int qty,price

    util.CURR_TIME = int.from_bytes(msg[5:11],'big')
    locate_id = int.from_bytes(msg[1:3], 'big')
    qty, _, price, match_id = unpack('>Q8sIQ', msg[11:39])
    
    
    util.executed_orders[locate_id] = [[price, qty, 0, match_id]]
    

# Firms that use the ITCH feed to create time-­­and-­­sales displays or
# calculate market statistics should be prepared to process the broken trade message
def broken_trade_execution_message(msg):

    cdef unsigned short locate_id
    cdef unsigned long long match_id

    # util.CURR_TIME = int.from_bytes(msg[4:10],'big')
    locate_id = int.from_bytes(msg[1:3], 'big')
    match_id = int.from_bytes(msg[11:19], 'big')
    try:
        orders = util.executed_orders.get(locate_id)
        if orders is not None:
            new_orders = list(filter(lambda a: not a[3] == match_id, orders))
            util.executed_orders.update({locate_id: new_orders})
    except (TypeError, KeyError) as e:
        return