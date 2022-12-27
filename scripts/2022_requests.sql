select
  WARD,
  SR_TYPE,
  STATUS = 'Completed' as completed,
  julianday(CLOSED_DATE) - julianday(CREATED_DATE) as time_to_completion,
  OWNER_DEPARTMENT,
  ORIGIN = 'Alderman''s Office' as aldermanic_request
from
  service_requests
where
  CREATED_DATE > '2022'
  AND SR_TYPE != '311 INFORMATION ONLY CALL'
  AND WARD IS NOT NULL
  AND ORIGIN IN (
    'Phone Call',
    'Internet',
    'Mobile Device',
    'Alderman''s Office'
  )
