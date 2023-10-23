# Data Warehouse Transformation

This readme provides a template to execute data transformations within our DWH. It includes getting started and general recommendations for working with dbt and Airflow. Each team of course should adjust this template based on their needs.

* [Getting Started](#Getting-Started)
* [Developing in dbt](#Developing-in-dbt)
* [Create Airflow DAGs](#Create-Airflow-DAGs)

## Getting Started

### Requirements

1. Team specific role for AWS. Details could be find [here](https://diva.teliacompany.net/confluence/display/CIRRUS/Application+Team+TIGA+Roles), you need Application Developers / Data Engineers role.
1. Team specific role and user in Redshift. Details could be find [here](https://diva.teliacompany.net/confluence/display/CIRRUS/Redshift+Database+Access+Process). environment = dev, because that is where we develop with dbt. 
1. Team specific github repository write access.
1. Github personal token. If you don't have one, follow steps [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token), save it for future access and [configure](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on) SSO for telia organization. 
*Token scope: **repo** - Full control of private repositories.*

### Resources:
1. Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction).
1. Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers.
1. Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support.
1. Find [dbt events](https://events.getdbt.com) near you.
1. Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices.
1. Open source [repository](https://github.com/dbt-labs/dbt-core) for dbt-core.
1. General best practices with dbt is available [here](https://docs.getdbt.com/docs/guides/best-practices).

### Environment

#### Cloud9

AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run, and debug your code with just a browser.

Development with dbt and Airflow happens in Cloud9 environment. The decision log can be found [here](https://diva.teliacompany.net/confluence/display/CIRRUS/DBT+development+environment).

Steps for setting the environment can be found [here](https://diva.teliacompany.net/confluence/display/CIRRUS/Cloud9+for+DBT+and+Airflow+development).

#### Local Airflow

For faster development we are using local Airflow in our Cloud9 instance. Airflow can access dags folder in the airflow/ directory of the project.

In order to access Airflow locally follow these steps:

1. To be added..


## Developing in dbt

### Version control

Suggested process is a combination of Gitflow workflow with our existing development process.

1. Checkout `dev` branch.

```bash
git checkout dev
```

If your `dev` branch is not up to date with `main`, it is best to update `dev` branch first.

```bash
# Update to latest of dev branch
git pull

# Sync with main branch as well
git checkout main
git pull
git checkout develop
git merge main
```

2. Create a feature branch.

```bash
git checkout -b feature_meaingful_feature_name
```

3. After the development is done, make a PR to `dev` for the feature.

### CI / CD

To be added..

### Generic guidelines

#### Development schemas

We suggest to use separate schema for each developer to develop their models. This is managed for you when you setup cloud9 enviroment and use variables in `dbt_project.yml` file.

```yml
+schema: "{{ env_var('REDSHIFT_USER') }}_intermediate"
```

### Model configuration

* Model-specific attributes (like sort/dist keys) should be specified in the model.
* If a particular configuration applies to all models in a directory, it should be specified in the `dbt_project.yml` file.
* In-model configurations should be specified like this:

```yml
{{
  config(
    materialized='table',
    sort='id',
    dist='id'
  )
}}
```

### Testing

* Every model should have a yaml `model.yml` counterpart for the `model.sql` file, in which the model is described and tested.
* At a minimum, unique and not_null tests should be applied to the primary key of each model.

### Documentation

We host dbt docs in each team's repository.
When adding documentation, follow the these steps:

1. To be added..
1. Run command `dbt docs generate`.
1. To be added..

### CTEs

* All `{{ ref('...') }}` statements should be placed in CTEs at the top of the file.
* Where performance permits, CTEs should perform a single, logical unit of work.
* CTE names should be as verbose as needed to convey what they do.
* CTEs with confusing or noteable logic should be commented.
* CTEs that are duplicated across models should be pulled out into their own models.
* create a `final` or similar CTE that you select from as your last line of code.
* CTEs should be formatted like this:

``` sql
with source_customer_data as (
    ...
)
-- In this CTE we filter out specific customer data
, final as (
    ...
)
select * 
from final
```

### Backfilling

If you have a model which cannot recreated with a single run, adjust incremental load management.

```sql
{% if is_incremental() %}

and last_updated_date > (select nvl(max(last_updated_date), '2016-10-31') from {{ this }} where source = 'cusin')
and last_updated_date < (select dateadd(month, 1, nvl(max(last_updated_date), '2016-10-31')) from {{ this }} where source = 'cusin')

-- and load_dttm > (select max(greatest(insert_load_dttm, update_load_dttm)) from {{ this }} where source = 'cusin')
-- and load_dttm < getdate()

{% endif %}
```

And run your dbt model in a loop in a cloud9 terminal.

```bash
for i in `seq 1 5`; do dbt run -s my_model_name; done
```

## Create Airflow DAGs

### Using selectors

The moment a model is tagged and can be selected by a `dbt selector` it is available to be added in the Airflow DAG of the selector. 

The framework automatically creates the following 2 sequential tasks:

1. dbt run (to refresh the model)
1. dbt test (to test the model)

* A dbt selector is reflective of an Airflow DAG.
* Models are run together in an Airflow DAG based on the `selectors.yml` file
* The selector name defines the Airflow DAG name
* If a model is dependent on other tasks in the same DAG, it will wait for completion of these upstream tasks. 
* A `.json` file per selector is automatically generated by this `generate_dbt_dags.py`
* the `*.json` file contains the dependencies of all models in the selector
* [This](https://github.com/telia-company/cirrus-engineering-pipelines/blob/master/airflow/dags/dbt/generate_selector_dags.py) DAG parse the `.json` file to construct a different seperate tasks and tests per model.

### Ussing cirrus dbt operators

To create a custom Airflow DAG, we can reuse cirrus dbt operators that are defined [here](https://diva.teliacompany.net/confluence/display/CIRRUS/%5BWIP%5D+Cirrus+airflow+operators).
