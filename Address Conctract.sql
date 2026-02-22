select
    address as contract_address
    , name as contract_name
    , namespace
    , "from" as deployer_address
        , created_at as deploy_time
        , dynamic
        , base
        , factory
        , detection_source
from plume.contracts
where LOWER(name) like '%plume%'
order by
    created_at asc;