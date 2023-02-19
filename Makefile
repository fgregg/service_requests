service_requests.db : service_requests.csv
	csv-to-sqlite -f service_requests.csv -o service_requests.db
	sqlite-utils convert $@ service_requests CREATED_DATE 'r.parsedatetime(value)'
	sqlite-utils convert $@ service_requests LAST_MODIFIED_DATE 'r.parsedatetime(value)'
	sqlite-utils convert $@ service_requests CLOSED_DATE 'r.parsedatetime(value)'
	sqlite-utils transform $@ service_requests --pk SR_NUMBER
	sqlite-utils create-index $@ service_requests CREATED_DATE

service_requests.csv : service_requests.csv.gz
	gunzip $<

service_requests.csv.gz :
	wget --header="accept-encoding: gzip" -O $@ "https://data.cityofchicago.org/api/views/v6vf-nfxy/rows.csv?accessType=DOWNLOAD"

requests.csv requests.attributes.csv requests.notes.extended.csv requests.notes.extended.details.csv requests.notes.csv: service_requests_api.json
	json-to-multicsv.pl \
            --path /:table:requests \
            --path /*/extended_attributes/geo_areas:table:geo_areas \
            --path /*/extended_attributes/photos:table:photos \
            --path /*/extended_attributes:table:extended_attributes \
            --path /*/notes/:table:notes \
            --path /*/notes/*/extended_attributes/:table:extended \
            --path /*/notes/*/extended_attributes/details/:table:details \
            --path /*/attributes/:table:attributes \
            --file $<

# json-to-mulicsv can't handle bools, https://github.com/jsnell/json-to-multicsv/issues/5
service_requests_api.json: service_requests_api.ldjson
	grep -v '"duplicate": true' $< | jq -s '.' > $@

service_requests_api.ldjson :
	chicagorequests --start-date=2023-01-01 > $@

## Analysis
.PHONY : parameters
parameters : alder_parameters.csv ward_parameters.csv

alder_parameters.csv : 2022_service.csv
	Rscript estimate_alderman_effect.R

ward_parameters.csv : 2022_service.csv
	Rscript estimate_ward_effect.R

2022_service.csv : service_requests.db
	cat scripts/2022_requests.sql | sqlite3 -header -csv $< > $@

