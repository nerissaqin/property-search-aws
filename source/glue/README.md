This is a terraform script for deploying glue related resources.

## includes
- glue catalog table (database, and crawler) for schema
- glue etl job for data processing
- glue trigger to schedule a daily data processing (tigger the glue etl job above)

## steps
- to update glue etl job script and infrastructure (terraform): `./run.sh`