-- An Entity represents any object within the application
create table `entity` (
  entity_id   bigint not null auto_increment primary key,
  entity_type varchar(255) not null,
  permissions bigint not null,
  created_at  timestamp not null default CURRENT_TIMESTAMP,
  user_id     bigint not null references `user` (user_id) on update cascade,
  group_id    bigint not null references `group` (group_id) on update cascade
);

-- The Access Control List for users/users on entities
create table `user_entity_acl`(
  entity_id   bigint not null,
  user_id     bigint not null references `user` (user_id) on update cascade,
  permissions bigint not null,
  constraint user_entity_acl_pk primary key (entity_id, user_id)
);

-- The Access Control List for groups/groups on entities
create table `group_entity_acl` (
  entity_id   bigint not null,
  group_id    bigint not null references `group` (group_id) on update cascade,
  permissions bigint not null,
  constraint group_entity_acl_pk primary key (entity_id, group_id)
);

delimiter $$
create function `has_permissions`(entity_entity_id bigint, entity_permissions bigint, entity_user_id bigint, entity_group_id bigint, uid bigint, type varchar(1))
  returns boolean deterministic
  begin
    declare user_pos int default 0;
    declare group_pos int default 2;
    declare other_pos int default 4;
    declare user_group_id bigint;
    declare result bigint;
    declare entity_g_id bigint;
    declare user_group_curs cursor for select group_id from `user_group` where user_id = uid;
    declare user_acl_curs cursor for select user_id from `user_entity_acl` where user_id = uid and entity_id = entity_entity_id and check_flag_on(permissions, user_pos);
    declare group_acl_curs cursor for select group_id from `group_entity_acl` where entity_id = entity_entity_id and check_flag_on(permissions, user_pos);

    create temporary table if not exists `user_groups`(group_id bigint);
    create temporary table if not exists `entity_groups`(group_id bigint);

    if type = 'w'
    then
      set user_pos = 1;
      set group_pos = 3;
      set other_pos = 5;
    end if;

    if entity_user_id = uid and check_flag_on(entity_permissions, user_pos)
    then
      return true;
    end if;

    open user_acl_curs;
    begin
      declare done int default 0;
      declare continue handler for not found set done = 1;
      get_user_acl: loop
        fetch user_acl_curs into result;
        if done = 1
        then
          leave get_user_acl;
        end if;
        if result is not null
        then
          close user_acl_curs;
          return true;
        end if;
      end loop;
    end;
    close user_acl_curs;

    open user_group_curs;
    begin
      declare done int default 0;
      declare continue handler for not found set done = 1;
      get_user_group: loop
        fetch user_group_curs into user_group_id;
        if done = 1
        then
          leave get_user_group;
        end if;
        insert into user_groups (group_id) values (user_group_id);
        if entity_group_id = user_group_id and check_flag_on(entity_permissions, group_pos)
        then
          close user_group_curs;
          return true;
        end if;
      end loop;
    end;
    close  user_group_curs;

    open group_acl_curs;
    begin
      declare done int default 0;
      declare continue handler for not found set done = 1;
      get_group_acl: loop
        fetch group_acl_curs into entity_g_id;
        if done = 1
        then
          leave get_group_acl;
        end if;
        insert into entity_groups (group_id) values (entity_g_id);
      end loop;
    end;
    close group_acl_curs;

    if exists(select 1 from user_groups where group_id in (select group_id from entity_groups)) and check_flag_on(entity_permissions, group_pos)
    then
       return true;
    end if;

    if check_flag_on(entity_permissions, other_pos)
    then
      return true;
    end if;

    return false;
  end $$
delimiter ;


