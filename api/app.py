from flask import Flask, jsonify
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import pyodbc
import os
import logging

app = Flask(__name__)

if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)
else:
    logging.basicConfig(level=logging.INFO)
    app.logger.setLevel(logging.INFO)

# Load Key Vault values
vault_url = os.environ.get("KEYVAULT_URL") or "https://kv-rabo.vault.azure.net/" 
credential = DefaultAzureCredential()
client = SecretClient(vault_url=vault_url, credential=credential)

sql_server = client.get_secret("SQL-SERVER").value
sql_db = client.get_secret("SQL-DATABASE").value
sql_user = client.get_secret("SQL-USER").value
sql_password = client.get_secret("SQL-PASSWORD").value

conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={sql_server};"
    f"DATABASE={sql_db};"
    f"UID={sql_user};"
    f"PWD={sql_password}"
)

@app.route("/heatlhcheck")
def get_home():
    result = [{"hello": "world"}]
    return jsonify(result)

@app.route("/invalids")
def get_invalids():
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT Reference, Description FROM InvalidTransactions")
    rows = cursor.fetchall()
    result = [{"reference": r[0], "description": r[1]} for r in rows]
    return jsonify(result)

if __name__ == "__main__":
    app.run()
    app.logger.info("Starting Flask app")
