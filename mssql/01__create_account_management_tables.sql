create table [dbo].[group] (
  group_id bigint       not null identity primary key,
  name     varchar(255) not null
);

create table [dbo].[user] (
  user_id    bigint       not null identity primary key,
  firstname  varchar(255) not null,
  lastname   varchar(255) not null,
  email      varchar(255) not null unique,
  password   varchar(255) not null,
  user_type  varchar(255) not null,
  status     bigint,
  --locked?,verified?
  created_at timestamp    not null,
  -- Primary Group
  group_id   bigint references [group] (group_id)
);

create table [dbo].[user_group] (
  user_id  bigint references [user] (user_id)
    on update cascade,
  group_id bigint references [group] (group_id)
    on update cascade,
  constraint [user_grp_pk] primary key (user_id, group_id)
);
go

insert into [dbo].[group] (name) values ('root');
insert into [dbo].[user] (firstname, lastname, email, password, user_type, status, group_id)
values ('root', 'root', 'root@techops.jps.net', '', 'root', 1, 1);
insert into [dbo].[user_group] (user_id, group_id) values (1, 1);
go

create function [dbo].[shiftRight](@x bigint, @s int)
  returns bigint
as
  begin
    if @x >= 0
      return cast(@x / power(cast(2 as bigint), @s & 0x1F) as bigint)
    return cast(~(~@x / power(cast(2 as bigint), @s & 0x1F)) as bigint)
  end;
go

create function [check_flag_on](@status bigint, @flag_position int)
  returns bit
as
  begin
    if ([dbo].shiftRight(@status, @flag_position) & 1 = 1)
      return 1
    return 0
  end;
go

create function [check_flag_off](@status bigint, @flag_position int)
  returns bit
as
  begin
    if ([dbo].shiftRight(@status, @flag_position) & 1 = 0)
      return 1
    return 0
  end;
go


