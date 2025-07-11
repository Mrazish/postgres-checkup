db_name='my_test_db'
current_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

su - postgres -c "psql -A -t -d postgres -c 'SELECT version()'"

su - postgres -c "psql -A -t -d postgres -c \"
	select pg_terminate_backend(pid)
	from pg_stat_activity
	where datname <> current_database() and datname = '"${db_name}"'\""

su - postgres -c "psql -A -t -d postgres -c 'DROP DATABASE if exists ${db_name}'"
su - postgres -c "psql -A -t -d postgres -c 'CREATE DATABASE ${db_name}'"
su - postgres -c "psql -A -t -d ${db_name} -f "${current_dir}"/.ci/test_db_dump.sql"

# ---------------------------------------------------------------------------------------------
echo "=======> Test started: H002_unused_indexes.sh"
test_result=1

rm -Rf ./artifacts
./checkup -h 127.0.0.1 --username postgres --project test --dbname ${db_name} -e 1 \
	--file ./resources/checks/H002_unused_indexes.sh

data_dir=$(cat ./artifacts/test/nodes.json | jq -r '.last_check | .dir') \
	&& result=$(cat ./artifacts/test/json_reports/$data_dir/H002_unused_indexes.json | 
		jq '.results ."127.0.0.1" .data .redundant_indexes ."public.t_with_redundant_idx_id"') \
	&& ([[ "$result" == "[]" ]] || [[ "$result" == "null" ]]) \
	&& echo "ERROR in H002: ${result} in '.results .\"127.0.0.1\" .data .redundant_indexes .\"public.t_with_redundant_idx_id\"'" \
	&& echo $(cat ./artifacts/test/json_reports/$data_dir/H002_unused_indexes.json | jq '.') \
        && test_result=0

data_dir=$(cat ./artifacts/test/nodes.json | jq -r '.last_check | .dir') \
	&& result=$(cat ./artifacts/test/json_reports/$data_dir/H002_unused_indexes.json | 
		jq '.results ."127.0.0.1" .data .redundant_indexes ."public.t_with_redundant_idx_f1_uniq"') \
	&& ([[ ! "$result" == "[]" ]] && [[ ! "$result" == "null" ]]) \
	&& echo "ERROR in H002: ${result} in '.results .\"127.0.0.1\" .data .redundant_indexes .\"public.t_with_redundant_idx_f1_uniq\"'" \
	&& echo $(cat ./artifacts/test/json_reports/$data_dir/H002_unused_indexes.json | jq '.') \
        && test_result=0

if [ "$test_result" -eq "1" ]; then
	echo "<======= Test finished: H002"
else
	echo "<======= Test failed: H002"
fi

# ---------------------------------------------------------------------------------------------
echo "=======> Test started: H003 Non indexed FKs"
test_result=1
su - postgres -c "psql -A -t -d ${db_name} -f "${current_dir}"/.ci/h003_step_1.sql"

rm -Rf ./artifacts
./checkup -h 127.0.0.1 --username postgres --project test --dbname ${db_name} -e 1 \
	--file ./resources/checks/H003_non_indexed_fks.sh

# one record must exist
data_dir=$(cat ./artifacts/test/nodes.json | jq -r '.last_check | .dir') \
	&& result=$(cat ./artifacts/test/json_reports/$data_dir/H003_non_indexed_fks.json | jq '.results ."127.0.0.1" .data') \
	&& ([[ "$result" == "[]" ]] || [[ "$result" == "null" ]]) \
	&& echo "ERROR in H003: ${result} in '.results .\"127.0.0.1\" .data'" \
	&& echo $(cat ./artifacts/test/json_reports/$data_dir/H003_non_indexed_fks.json | jq '.') \
        && test_result=0

su - postgres -c "psql -A -t -d ${db_name} -f "${current_dir}"/.ci/h003_step_2.sql"
rm -Rf ./artifacts

./checkup -h 127.0.0.1 --username postgres --project test --dbname ${db_name} -e 1 \
	--file ./resources/checks/H003_non_indexed_fks.sh

# must be no records
data_dir=$(cat ./artifacts/test/nodes.json | jq -r '.last_check | .dir') \
	&& result=$(cat ./artifacts/test/json_reports/$data_dir/H003_non_indexed_fks.json | jq '.results ."127.0.0.1" .data') \
	&& cat ./artifacts/test/json_reports/$data_dir/H003_non_indexed_fks.json \
	&& (! [[ "$result" == "[]" ]]) \
	&& echo "ERROR in H003: found ${result} in '.results .\"127.0.0.1\" .data'" \
        && test_result=0

if [ "$test_result" -eq "1" ]; then
	echo "<======= Test finished: H003"
else
	echo "<======= Test failed: H003"
fi
# ---------------------------------------------------------------------------------------------