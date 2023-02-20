service_requests.db : portal_service_requests.csv attributes.csv	\
                      geo_areas.csv notes.details.csv requests.csv	\
                      notes.csv photos.csv
	csv-to-sqlite $^ $@
	sqlite-utils convert $@ portal_service_requests CREATED_DATE 'r.parsedatetime(value)'
	sqlite-utils convert $@ portal_service_requests LAST_MODIFIED_DATE 'r.parsedatetime(value)'
	sqlite-utils convert $@ portal_service_requests CLOSED_DATE 'r.parsedatetime(value)'
	sqlite-utils transform $@ portal_service_requests --pk SR_NUMBER
	sqlite-utils create-index $@ portal_service_requests CREATED_DATE
	sqlite-utils $@ 'delete from requests where [_key] = 90630'
	sqlite-utils transform $@ requests --pk service_request_id --drop extended_x --drop extended_y --rename extended_duplicate duplicate
	sqlite-utils $@ 'update requests set duplicate = 0 where duplicate is null'
	sqlite-utils transform $@ geo_areas --rename geo_areas area --rename _key service_request_id --rename geo__key type
	 sqlite-utils $@ 'update geo_areas set service_request_id = requests.service_request_id from requests where geo_areas.service_request_id = requests.[_key]'
	sqlite-utils add-foreign-key $@ geo_areas service_request_id requests service_request_id
	sqlite-utils transform $@ attributes --rename _key service_request_id --rename _key.1 ordering
	sqlite-utils $@ 'update attributes as u set service_request_id = requests.service_request_id from requests where u.service_request_id = requests.[_key]'
	sqlite-utils add-foreign-key $@ attributes service_request_id requests service_request_id
	sqlite-utils transform $@ photos --rename _key service_request_id --rename _key.1 ordering
	sqlite-utils $@ 'update photos as u set service_request_id = requests.service_request_id from requests where u.service_request_id = requests.[_key]'
	sqlite-utils add-foreign-key $@ photos service_request_id requests service_request_id
	sqlite-utils transform $@ notes --rename _key service_request_id --rename _key.1 ordering --pk id
	sqlite-utils $@ 'alter table [notes.details] rename to notes_details'
	sqlite-utils $@ 'update notes_details set [_key.1] = notes.id from notes where notes_details.[_key] = notes.service_request_id and notes_details.[_key.1] = notes.ordering'
	sqlite-utils transform $@ notes_details --drop _key --drop _key.2 --rename _key.1 notes_id
	sqlite-utils add-foreign-key $@ notes_details notes_id notes id
	sqlite-utils $@ "create table opened_extended as select id as notes_id, extended_status as status from notes where type = 'opened' and (extended_status is not null)"
	sqlite-utils add-foreign-key $@ opened_extended notes_id notes id
	sqlite-utils $@ "create table activity_extended as select id as notes_id, extended_started_at as started_at, extended_ended_at as ended_at, extended_work_order_number as work_order_number from notes where type = 'activity' and (extended_started_at is not null or extended_ended_at is not null or extended_work_order_number is not null)"
	sqlite-utils add-foreign-key $@ activity_extended notes_id notes id
	sqlite-utils $@ "create table follow_on_created_extended as select id as notes_id, extended_priority as priority, extended_status as status, extended_work_order_number as work_order_number from notes where type = 'follow_on_created' and (extended_priority is not null or extended_status is not null or extended_work_order_number is not null)"
	sqlite-utils add-foreign-key $@ follow_on_created_extended notes_id notes id
	sqlite-utils $@ "create table follow_on_closed_extended as select id as notes_id, extended_work_order_number as work_order_number from notes where type = 'follow_on_closed' and (extended_work_order_number is not null)"
	sqlite-utils add-foreign-key $@ follow_on_closed_extended notes_id notes id
	sqlite-utils transform $@ notes --drop extended_ended_at --drop extended_priority --drop extended_service_request_number --drop extended_started_at --drop extended_status --drop extended_work_order_number
	sqlite-utils $@ 'update notes as u set service_request_id = requests.service_request_id from requests where u.service_request_id = requests.[_key]'
	sqlite-utils add-foreign-key $@ notes service_request_id requests service_request_id
	sqlite-utils transform $@ requests --drop _key

portal_service_requests.csv : portal_service_requests.csv.gz
	gunzip $<

portal_service_requests.csv.gz :
	wget --header="accept-encoding: gzip" -O $@ "https://data.cityofchicago.org/api/views/v6vf-nfxy/rows.csv?accessType=DOWNLOAD"

%.csv : requests.%.csv
	sed -r '1s/[a-z0-9]+\.//g' $< > $@

requests.csv : raw_requests.csv
	sed -r '1s/[a-z0-9]+\.//g' $< > $@

requests.attributes.csv requests.geo_areas.csv requests.notes.details.csv raw_requests.csv requests.notes.csv requests.photos.csv : service_requests_api.json
	json-to-multicsv.pl \
            --path /:table:requests \
            --path /*/extended_attributes/geo_areas:table:geo_areas \
            --path /*/extended_attributes/photos:table:photos \
            --path /*/extended_attributes:column \
            --path /*/notes/:table:notes \
            --path /*/notes/*/extended_attributes:column \
            --path /*/notes/*/extended_attributes/details/:table:details \
            --path /*/attributes/:table:attributes \
            --file $<
	mv requests.csv raw_requests.csv

# json-to-mulicsv can't handle bools, https://github.com/jsnell/json-to-multicsv/issues/5
service_requests_api.json: service_requests_api.ldjson
	cat $< | jq -s '.' > $@

service_requests_api.ldjson :
	chicagorequests --start-date=2018-01-01 | sort | uniq > $@

## Analysis
.PHONY : parameters
parameters : alder_parameters.csv ward_parameters.csv

alder_parameters.csv : 2022_service.csv
	Rscript estimate_alderman_effect.R

ward_parameters.csv : 2022_service.csv
	Rscript estimate_ward_effect.R

2022_service.csv : service_requests.db
	cat scripts/2022_requests.sql | sqlite3 -header -csv $< > $@

