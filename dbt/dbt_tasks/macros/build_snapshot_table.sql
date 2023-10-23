{#% macro build_snapshot_table123(strategy, sql) %}
--Let's rename default column names in the next release
select *,
{{ strategy.updated_at }} as record_start_date,
{{ strategy.updated_at }} as record_end_date
from (
{{ sql }}
) sbq
{% endmacro %#}

{% macro default__snapshot_staging_table(strategy, source_sql, target_relation) -%}

    with snapshot_query as (

        {{ source_sql }}

    ),

    snapshotted_data as (

        select *,
            {{ strategy.unique_key }} as dbt_unique_key

        from {{ target_relation }}
        where dbt_valid_to is null

    ),

    insertions_source_data as (

        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key,
            {{ strategy.updated_at }} as dbt_updated_at,
            {{ strategy.updated_at }} as dbt_valid_from,
            nullif({{ strategy.updated_at }}, {{ strategy.updated_at }}) as dbt_valid_to,
            {{ strategy.scd_id }} as dbt_scd_id

        from snapshot_query
    ),

    updates_source_data as (

        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key,
            {{ strategy.updated_at }} as dbt_updated_at,
            {{ strategy.updated_at }} as dbt_valid_from,
            TIMESTAMP(TIMESTAMP_SUB({{ strategy.updated_at }}, INTERVAL 1 second)) as dbt_valid_to

        from snapshot_query
    ),

    {%- if strategy.invalidate_hard_deletes %}

    deletes_source_data as (

        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key
        from snapshot_query
    ),
    {% endif %}

    insertions as (

        select
            'insert' as dbt_change_type,
            source_data.*

        from insertions_source_data as source_data
        left outer join snapshotted_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
        where snapshotted_data.dbt_unique_key is null
           or (
                snapshotted_data.dbt_unique_key is not null
            and (
                {{ strategy.row_changed }}
            )
        )

    ),

    updates as (

        select
            'update' as dbt_change_type,
            source_data.*,
            snapshotted_data.dbt_scd_id

        from updates_source_data as source_data
        join snapshotted_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
        where (
            {{ strategy.row_changed }}
        )
    )

    {%- if strategy.invalidate_hard_deletes -%}
    ,

    deletes as (

        select
            'delete' as dbt_change_type,
            source_data.*,
            {{ snapshot_get_time() }} as dbt_valid_from,
            {{ snapshot_get_time() }} as dbt_updated_at,
            TIMESTAMP('{{ var("execution_date") }}') as dbt_valid_to,
            snapshotted_data.dbt_scd_id

        from snapshotted_data
        left join deletes_source_data as source_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
        where source_data.dbt_unique_key is null
    )
    {%- endif %}

    select * from insertions
    union all
    select * from updates
    {%- if strategy.invalidate_hard_deletes %}
    union all
    select * from deletes
    {%- endif %}

{%- endmacro %}