import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="glue_client_data_test",
    table_name="rawclientdata",
    transformation_ctx="S3bucket_node1",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
select SearchSuburb,SearchState,Count(*) from myDataSource
GROUP BY SearchSuburb,SearchState;
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"myDataSource": S3bucket_node1},
    transformation_ctx="ApplyMapping_node2",
)

glueContext.write_dynamic_frame_from_options(
    frame=ApplyMapping_node2,
    connection_type="dynamodb",
    connection_options={"dynamodb.output.tableName": "ClientData",
        "dynamodb.throughput.write.percent": "1.0"
    }
)

job.commit()
