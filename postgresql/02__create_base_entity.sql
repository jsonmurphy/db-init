-- An Entity represents any object within the application
create table entity (
  entity_id   bigserial not null primary key,
  permissions bigint,
  account_id  bigint references account (account_id) on update cascade,
  cluster_id  bigint references cluster (cluster_id) on update cascade
);

-- The Access Control List for accounts/users on entities
create table account_entity_acl (
  entity_id   bigint,
  account_id  bigint references account (account_id) on update cascade,
  permissions bigint,
  constraint account_entity_acl_pk primary key (entity_id, account_id)
);

-- The Access Control List for clusters/groups on entities
create table cluster_entity_acl (
  entity_id   bigint,
  cluster_id  bigint references cluster (cluster_id) on update cascade,
  permissions bigint,
  constraint cluster_entity_acl_pk primary key (entity_id, cluster_id)
);

create or replace function has_permissions(entity, bigint, varchar(1))
  returns boolean as $$
declare
  entity alias for $1;
  aid alias for $2;
  type alias for $3;

  user_pos        int := 0;
  group_pos       int := 2;
  other_pos       int := 4;
  result          bigint;
  acc_clusters    bigint [];
  entity_clusters bigint [];

    acc_clusters_curs cursor for select array_agg(cluster_id)
                                 from account_cluster
                                 where
                                   account_id = aid;
    account_acl_curs cursor for select account_id
                                from account_entity_acl
                                where
                                  account_id = aid and
                                  entity_id = entity.entity_id and
                                  check_flag_on(permissions, user_pos);
    cluster_acl_curs cursor for select array_agg(cluster_id)
                                from cluster_entity_acl
                                where
                                  entity_id = entity.entity_id and
                                  check_flag_on(permissions, user_pos);
begin
  if type = 'w'
  then
    user_pos := 1;
    group_pos := 3;
    other_pos := 5;
  end if;

  if entity.account_id = aid and check_flag_on(entity.permissions, user_pos)
  then
    return true;
  end if;

  open account_acl_curs;
  fetch account_acl_curs into result;
  if found
  then
    close account_acl_curs;
    return true;
  end if;
  close account_acl_curs;

  open acc_clusters_curs;
  fetch acc_clusters_curs into acc_clusters;
  if entity.cluster_id = any (acc_clusters) and check_flag_on(entity.permissions, group_pos)
  then
    close acc_clusters_curs;
    return true;
  end if;
  close acc_clusters_curs;

  open cluster_acl_curs;
  fetch cluster_acl_curs into entity_clusters;
  if acc_clusters && entity_clusters and check_flag_on(entity.permissions, group_pos)
  then
    close cluster_acl_curs;
    return true;
  end if;
  close cluster_acl_curs;

  if check_flag_on(entity.permissions, other_pos)
  then
    return true;
  end if;

  return false;
end
$$ language plpgsql;
