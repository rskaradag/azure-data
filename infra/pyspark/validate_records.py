from pyspark.sql.functions import col, expr
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# 1. Read the CSV file from Azure Data Lake Storage Gen2
df = spark.read.option("header", True).csv("abfss://cnt-rabodata-dev-northeurope@strabodatadevnortheurope.dfs.core.windows.net/transactions.csv")

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
          .csv("abfss://cnt-rabodata-dev-northeurope@strabodatadevnortheurope.dfs.core.windows.net/output/invalid")

# (Optional) Display valid records
valid_df.show()
