import mysql.connector
from modules.runTimeSecrets import HOST, DB, USER, PASS, HOST2, DB2, USER2, PASS2, HOST3, DB3, USER3, PASS3

conn = mysql.connector.connect(host=HOST, database=DB, user=USER, password=PASS)
if conn.is_connected():
    print("DB Connected.")
else:
    print("DB Not Connected.")
