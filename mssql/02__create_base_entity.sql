-- An Entity represents any object within the application
create table [dbo].[entity] (
  entity_id   bigint       not null identity primary key,
  entity_type varchar(255) not null,
  permissions bigint       not null,
  created_at  timestamp    not null,
  user_id     bigint       not null references [dbo].[user] (user_id)
    on update cascade,
  group_id    bigint       not null references [dbo].[group] (group_id)
    on update cascade
);

-- The Access Control List for users/users on entities
create table [dbo].[user_entity_acl] (
  entity_id   bigint not null,
  user_id     bigint not null references [dbo].[user] (user_id)
    on update cascade,
  permissions bigint not null,
  constraint user_entity_acl_pk primary key (entity_id, user_id)
);

-- The Access Control List for groups/groups on entities
create table [dbo].[group_entity_acl] (
  entity_id   bigint not null,
  group_id    bigint not null references [dbo].[group] (group_id)
    on update cascade,
  permissions bigint not null,
  constraint group_entity_acl_pk primary key (entity_id, group_id)
);
go

create type temp_user_groups as table (group_id bigint);
create type temp_entity_groups as table (group_id bigint);
go

create function [dbo].[has_permissions](@entity_entity_id bigint, @entity_permissions bigint, @entity_user_id bigint,
                                        @entity_group_id  bigint, @uid bigint, @type varchar(1))
  returns bit
as
  begin
    declare @user_pos int = 0;
    declare @group_pos int = 2;
    declare @other_pos int = 4;
    declare @user_group_id bigint;
    declare @result bigint;
    declare @entity_g_id bigint;
    declare @user_groups as temp_user_groups;
    declare @entity_groups as temp_entity_groups;
    declare user_group_curs cursor for select group_id
                                       from [dbo].[user_group]
                                       where user_id = @uid;
    declare user_acl_curs cursor for select user_id
                                     from [dbo].[user_entity_acl]
                                     where user_id = @uid and entity_id = @entity_entity_id and
                                           [dbo].check_flag_on(permissions, @user_pos) = 1;
    declare group_acl_curs cursor for select group_id
                                      from [dbo].[group_entity_acl]
                                      where
                                        entity_id = @entity_entity_id and [dbo].check_flag_on(permissions, @user_pos) = 1;


    if @type = 'w'
      begin
        set @user_pos = 1;
        set @group_pos = 3;
        set @other_pos = 5;
      end;

    if @entity_user_id = @uid and [dbo].check_flag_on(@entity_permissions, @user_pos) = 1
      return 1;

    open user_acl_curs;
    begin
      fetch next from user_acl_curs
      into @result
      while @@fetch_status = 0
        begin
          if @result is not null
            begin
              close user_acl_curs;
              deallocate user_acl_curs;
              return 1;
            end
          fetch next from user_acl_curs
          into @result
        end
    end
    close user_acl_curs;
    deallocate user_acl_curs;

    open user_group_curs;
    begin
      fetch next from user_group_curs
      into @user_group_id;
      while @@fetch_status = 0
        begin
          insert into @user_groups (group_id) values (@user_group_id);
          if @entity_group_id = @user_group_id and [dbo].check_flag_on(@entity_permissions, @group_pos) = 1
            begin
              close user_group_curs;
              deallocate user_group_curs;
              return 1;
            end;
          fetch next from user_group_curs
          into @user_group_id;
        end;
    end;
    close user_group_curs;
    deallocate user_group_curs;

    open group_acl_curs;
    begin
      fetch next from group_acl_curs into @entity_g_id
      while @@fetch_status = 0
      begin
        insert into @entity_groups (group_id) values (@entity_g_id);
        fetch next from group_acl_curs into @entity_g_id
      end
    end
    close group_acl_curs;
    deallocate group_acl_curs;

    if exists(select 1 from @user_groups where group_id in (select group_id from @entity_groups)) and [dbo].check_flag_on(@entity_permissions, @group_pos) = 1
      return 1;

    if [dbo].check_flag_on(@entity_permissions, @other_pos) = 1
      return 1;

    return 0;
  end;
go
