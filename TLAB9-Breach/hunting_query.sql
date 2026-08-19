SELECT 
    eventtime,
    useridentity.arn as user_identity,
    eventname,
    requestparameters
FROM 
    cloudtrail_logs_tkh
WHERE 
    eventname = 'RunInstances'
ORDER BY 
    eventtime DESC;