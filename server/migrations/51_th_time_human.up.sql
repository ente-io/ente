create or replace function th(epochTimeinMircoSeconds bigint)
returns TIMESTAMP WITH TIME ZONE
language plpgsql
as
$$
begin
   return to_timestamp(cast(epochTimeinMircoSeconds/1000000 as bigint));
end;
$$;
