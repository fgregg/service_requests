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
	sqlite3 -header -csv $< "select WARD, SR_TYPE, STATUS = 'Completed' as completed, julianday(CLOSED_DATE) - julianday(CREATED_DATE) as time_to_completion, OWNER_DEPARTMENT, ORIGIN = 'Alderman''s Office' as aldermanic_request from service_requests where CREATED_DATE > '2022' AND SR_TYPE != '311 INFORMATION ONLY CALL' AND WARD IS NOT NULL AND ORIGIN IN ('Phone Call', 'Internet', 'Mobile Device', 'Alderman''s Office')"  > $@
