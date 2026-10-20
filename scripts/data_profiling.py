import pandas as pd

# Read the file
df = pd.read_parquet(r"C:\Users\isham\Downloads\yellow_tripdata_2026-01.parquet")

# Interactive exploration
df.head()          # First 5 rows
df.info()          # Full schema
df.describe()      # Statistics
df.columns         # Just column names
df.shape           # (rows, columns)
df.dtypes          # Data types

# Check specific things
df['VendorID'].value_counts()  # Unique values in a column
df.isnull().sum()              # Null counts
df.nunique()                   # Unique values per column