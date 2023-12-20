import os
from faker import Faker
import random
from kafka import KafkaProducer
import json
import time
import datetime
from threading import Thread

def ack(err, msg):
    if err is not None:
        print("Failed to send message:", err)
    else:
        print("Sent message to topic: ", msg.topic())

def main():
    # Initialize Faker
    fake = Faker()
    fake.seed_instance(4321)
    f_names = []
    for _ in range(1000):
        f_names.append(fake.name())

    f_comments = []
    for _ in range(1000):
        f_comments.append(fake.sentence(nb_words = 5))
    o_orderstates = [ 'O', 'P', 'F' ]
    o_orderpriorities = [
        '1-URGENT',
        '2-HIGH',
        '4-NOT SPECIFIED',
        '3-MEDIUM',
        '5-LOW'
    ]
    o_shippriorities = [0,1]
    l_shipmodes = [
        'MAIL',
        'FOB',
        'RAIL',
        'AIR',
        'REG AIR',
        'SHIP',
        'TRUCK'
    ]
    l_shipinstructs = [
        'DELIVER IN PERSON',
        'TAKE BACK RETURN',
        'COLLECT COD',
        'NONE'
    ]
    l_linestatus = ['O', 'F']
    l_returnflags = ['A', 'N', 'R']
    # Helper function to generate an order
    def generate_order(o_orderkey, o_orderdate):
        order = {
                'o_orderkey': o_orderkey,
                'o_custkey': random.randrange(1,14999999),
                'o_orderstatus': random.choice(o_orderstates),
                'o_totalprice': 0,
                'o_orderdate': o_orderdate,
                'o_orderpriority': random.choice(o_orderpriorities),
                'o_clerk': random.choice(f_names),
                'o_shippriority': random.choice(o_shippriorities),
                'o_comment': random.choice(f_comments)
        }
        return (order)

    # Helper function to generate a line item
    def generate_lineitem(o_orderkey, o_orderdate, l_num):
        l_shipdate      = fake.date_between_dates(datetime.datetime.strptime(o_orderdate, "%Y-%m-%d"),datetime.datetime.strptime(o_orderdate, "%Y-%m-%d") + datetime.timedelta(days=60))
        l_commitdate    = fake.date_between_dates(l_shipdate, l_shipdate + datetime.timedelta(days=7))
        l_receiptdate   = fake.date_between_dates(l_commitdate + datetime.timedelta(days=1), l_commitdate + datetime.timedelta(days=30))

        lineitem = {
            'l_orderkey': o_orderkey,
            'l_partkey': random.randrange(1,20000000),
            'l_suppkey': random.randrange(1,1000000),
            'l_linenumber': l_num,
            'l_quantity': random.randrange(1,10),
            'l_extendedprice': round(random.uniform(1.99,99.99), 2),
            'l_discount': round(random.uniform(0.00,0.10), 2),
            'l_tax': round(random.uniform(0.00,0.08),2),
            'l_returnflag': random.choice(l_returnflags),
            'l_linestatus': random.choice(l_linestatus),
            'l_shipdate': l_shipdate.strftime("%Y-%m-%d"),
            'l_commitdate': l_commitdate.strftime("%Y-%m-%d"),
            'l_receiptdate': l_receiptdate.strftime("%Y-%m-%d"),
            'l_shipinstruct': random.choice(l_shipinstructs),
            'l_shipmode': random.choice(l_shipmodes),
            'l_comment': random.choice(f_comments)
        }
        return (lineitem)

    broker = os.environ.get("BROKER_HOST_PORT")
    # Creating a pool of producer
    pool_of_producers = [KafkaProducer(bootstrap_servers=broker, batch_size=1024*16) for _ in range(5)]
    while True:
        # Generate orders and line items
        o_orderdate = fake.date_between(datetime.date(2023,1,1),datetime.date(2025,12,31)).strftime("%Y-%m-%d")
        o_orderkey  = random.randrange(600000000,9223372036854775807)
        order = generate_order(o_orderkey, o_orderdate)
        lineitems = []
        l_num = 1
        # Generate multiple line items for the order
        for l in range(random.randrange(1,10)):
            lineitem = generate_lineitem(o_orderkey, o_orderdate, l_num)
            lineitems.append(lineitem)
            l_num = l_num + 1
        o_totalprice = 0
        for l in lineitems:
            o_totalprice = round(o_totalprice + (l['l_extendedprice'] - ( l['l_discount'] * l['l_discount'])),2)

        msg = {
                'o_orderkey': order['o_orderkey'],
                'o_custkey': order['o_custkey'],
                'o_orderstatus': order['o_orderstatus'],
                'o_totalprice': o_totalprice,
                'o_orderdate': order['o_orderdate'],
                'o_orderpriority': order['o_orderpriority'],
                'o_clerk': order['o_clerk'],
                'o_shippriority': order['o_shippriority'],
                'o_comment': order['o_comment'],
                'lineitems': lineitems
        }
        # Asynchronously send message to kafka
        t = Thread(target=send_message, args=(random.choice(pool_of_producers), msg))
        t.start()
        print("Sent message with order id: ", o_orderkey)

def send_message(producer, msg):
    producer.send("tpch", json.dumps(msg).encode('utf-8'))
    producer.flush()

if __name__ == '__main__':
    main()
