from pyspark.sql.functions import col, expr
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

keyvault_url = "https://kv-rabo.vault.azure.net/"
credential = DefaultAzureCredential()
client = SecretClient(vault_url=keyvault_url, credential=credential)
sql_server = client.get_secret("SQL-SERVER")
sql_database = client.get_secret("SQL-DATABASE")
sql_user = client.get_secret("SQL-USER")
sql_password = client.get_secret("SQL-PASSWORD")

jdbc_url = f"jdbc:sqlserver://{sql_server}.database.windows.net:1433;" \
           f"database={sql_database};" \
           f"user={sql_user}@{sql_server};" \
           f"password={sql_password};" \
           "encrypt=true;trustServerCertificate=false;" \
           "hostNameInCertificate=*.database.windows.net;loginTimeout=30;"


# 1. Read the CSV file from Azure Data Lake Storage Gen2
df = spark.read.option("header", True).csv("abfss://statements@datastorage28069.dfs.core.windows.net/transactions.csv")

# 2. Convert column types
df = df.withColumn("Reference", col("Reference").cast("long")) \
       .withColumn("Start Balance", col("Start Balance").cast("double")) \
       .withColumn("Mutation", col("Mutation").cast("double")) \
       .withColumn("End Balance", col("End Balance").cast("double"))

# 3. Calculate the expected end balance
df = df.withColumn("Computed_End", expr("`Start Balance` + Mutation"))

# 4. Filter valid records (unique reference and matching end balance)
valid_df = df.dropDuplicates(["Reference"]) \
             .filter(col("End Balance") == col("Computed_End"))

# 5. Identify invalid records
invalid_df = df.subtract(valid_df)

# 6. Write invalid records (Reference and Description) to a separate folder
invalid_df.select("Reference", "Description") \
          .write.mode("overwrite") \
          .option("header", True) \
          .csv("abfss://statements@datastorage28069.dfs.core.windows.net/output/invalid")

# (Optional) Display valid records
valid_df.show()

valid_df.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "validated_transactions") \
    .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
    .mode("overwrite") \
    .save()
