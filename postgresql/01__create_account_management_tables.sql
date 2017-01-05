-- Enumerated account types
create type account_type as enum ('candidate', 'enterprise');
-- Enumerated cluster types
create type cluster_type as enum ('user', 'system');

-- A Cluster represents different account groups
create table cluster (
  cluster_id   bigserial    not null primary key,
  name         varchar(256) not null,
  cluster_type cluster_type not null
);

-- An Account represents a user within the system
create table account (
  account_id   bigserial    not null primary key,
  firstname    varchar(256) not null,
  lastname     varchar(256) not null,
  email        varchar(256) not null unique,
  password     varchar(256) not null,
  account_type account_type not null,
  status       bigint,
  created_at   date         not null default CURRENT_DATE,
  -- Primary Cluster/Group
  cluster_id   bigint references cluster (cluster_id)
);

-- Many to Many relationship between accounts and clusters
create table account_cluster (
  account_id bigint references account (account_id) on update cascade,
  cluster_id bigint references cluster (cluster_id) on update cascade,
  constraint account_acl_pk primary key (account_id, cluster_id)
);

create or replace function check_flag_on(status bigint, flag_position int)
  returns boolean as $$
select (status >> flag_position) & 1 = 1;
$$ language sql;

create or replace function check_flag_off(status bigint, flag_position int)
  returns boolean as $$
select (status >> flag_position) & 1 = 0;
$$ language sql;

