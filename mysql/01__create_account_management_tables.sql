create table `group` (
  group_id bigint not null auto_increment primary key,
  name varchar(255) not null
);

create table `user` (
  user_id bigint not null auto_increment primary key,
  firstname varchar(255) not null,
  lastname varchar(255) not null,
  email varchar(255) not null unique,
  password varchar(255) not null,
  user_type varchar(255) not null,
  status bigint,
  created_at timestamp not null default CURRENT_TIMESTAMP,
  -- Primary Group
  group_id bigint references `group` (group_id)
);

create table `user_group` (
  user_id bigint references `user` (user_id) on update cascade,
  group_id bigint references `group` (group_id) on update cascade,
  constraint `user_acl_pk` primary key (user_id, group_id)
);


delimiter $$
create function check_flag_on(status bigint, flag_position int)
  returns boolean deterministic
  begin
    return (status >> flag_position) & 1 = 1;
  end $$

create function check_flag_off(status bigint, flag_position int)
  returns boolean deterministic
  begin
    return (status >> flag_position) & 1 = 0;
  end $$
delimiter ;

