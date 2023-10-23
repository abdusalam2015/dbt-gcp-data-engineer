## TV-team-pipelines

### Repository secrets
    
The below secrets need to be defined inside repo configuration:

    K8S_API_SERVER
    K8S_TOKEN

### DBT setup
	1. Update brew & add dbt repo: `brew update && brew tap dbt-labs/dbt`
    2. Install dbt with BigQuery adapter: `brew install dbt-bigquery`
