from pyspark.sql.functions import col, expr
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# 1. Retrieve secrets from Azure Key Vault
keyvault_url = "https://kv-rabo.vault.azure.net/"
credential = DefaultAzureCredential()
client = SecretClient(vault_url=keyvault_url, credential=credential)

sql_server   = client.get_secret("SQL-SERVER").value
sql_database = client.get_secret("SQL-DATABASE").value
sql_user     = client.get_secret("SQL-USER").value
sql_password = client.get_secret("SQL-PASSWORD").value

# 2. Configure JDBC URL for Azure SQL Database
jdbc_url = f"jdbc:sqlserver://{sql_server}.database.windows.net:1433;" \
           f"database={sql_database};" \
           f"user={sql_user}@{sql_server};" \
           f"password={sql_password};" \
           "encrypt=true;trustServerCertificate=false;" \
           "hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

# 3. Read the CSV file from Azure Data Lake Storage Gen2
df = spark.read.option("header", True).csv(
    "abfss://cnt-rabodata-dev-northeurope@strabodatadevnortheurope.dfs.core.windows.net/transactions.csv"
)

# 4. Cast numeric fields to proper data types
df = df.withColumn("Reference", col("Reference").cast("long")) \
       .withColumn("Start Balance", col("Start Balance").cast("double")) \
       .withColumn("Mutation", col("Mutation").cast("double")) \
       .withColumn("End Balance", col("End Balance").cast("double"))

# 5. Calculate the expected end balance
df = df.withColumn("Computed_End", expr("`Start Balance` + Mutation"))

# 6. Filter valid records (unique Reference and matching End Balance)
valid_df = df.dropDuplicates(["Reference"]) \
             .filter(col("End Balance") == col("Computed_End"))

# 7. Identify invalid records by subtracting valid ones
invalid_df = df.subtract(valid_df)

# 8. Save invalid records (Reference + Description) to ADLS as CSV
invalid_df.select("Reference", "Description") \
    .write.mode("overwrite") \
    .option("header", True) \
    .csv("abfss://cnt-rabodata-dev-northeurope@strabodatadevnortheurope.dfs.core.windows.net/output/invalid")

# 9. Save valid records into Azure SQL table
valid_df.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "ValidTransactions") \
    .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
    .mode("overwrite") \
    .save()

# 10. Save invalid records into Azure SQL table
invalid_df.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "InvalidTransactions") \
    .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
    .mode("overwrite") \
    .save()
