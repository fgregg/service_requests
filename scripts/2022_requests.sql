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
  and SR_TYPE IN (
    'Abandoned Vehicle Complaint',
    'Alley Pothole Complaint',
    'Building Violation',
    'Garbage Cart Maintenance',
    'Graffiti Removal Request',
    'Inspect Public Way Request',
    'Pothole in Street Complaint',
    'Rodent Baiting/Rat Complaint',
    'Sewer Cleaning Inspection Request',
    'Street Light Out Complaint',
    'Traffic Signal Out Complaint',
    'Tree Debris Clean-Up Request',
    'Water On Street Complaint'
  )
  AND WARD IS NOT NULL
  AND ORIGIN IN (
    'Phone Call',
    'Internet',
    'Mobile Device',
    'Alderman''s Office'
  )
