import pandas as pd
from sqlalchemy import create_engine
import psycopg2
df1=pd.read_csv("category.csv")
engine=create_engine("postgresql+psycopg2://mac:1234@localhost/apple")
df1.to_sql(name='category',con=engine,index='False')
df2=pd.read_csv("products.csv")
df2.to_sql(name='products',con=engine,index="false")
df3=pd.read_csv("sales.csv")
df3.to_sql(name='sales',con=engine,index=False)
df4=pd.read_csv("stores.csv")
df4.to_sql(name='stores',con=engine,index=False)
df5=pd.read_csv("warranty.csv")
df5.to_sql(name='warranty',con=engine,index=False)
