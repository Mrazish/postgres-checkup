# Collect anti-crash related settings
${CHECK_HOST_CMD} "${_PSQL} -f -" <<'SQL'
select json_build_object(
  'fsync', (select setting from pg_settings where name='fsync'),
  'full_page_writes', (select setting from pg_settings where name='full_page_writes'),
  'synchronous_commit', (select setting from pg_settings where name='synchronous_commit')
);
SQL
