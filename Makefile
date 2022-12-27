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

## Analysis
parameters.csv : 2022_service.csv
	Rscript estimate_alderman_effect.R

2022_service.csv : service_requests.db
	cat scripts/2022_requests.sql | sqlite3 -header -csv $< > $@
