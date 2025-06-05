# Collect data checksums and wal_log_hints info
${CHECK_HOST_CMD} "${_PSQL} -f -" <<'SQL'
select json_build_object(
  'data_checksums', (select setting from pg_settings where name = 'data_checksums'),
  'wal_log_hints', (select setting from pg_settings where name = 'wal_log_hints')
);
SQL
