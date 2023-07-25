-- UDF to determine what each entry in the column is
CREATE OR REPLACE FUNCTION determine_type(col varchar)
RETURNS varchar
AS
$$
DECLARE
	data_type varchar;
BEGIN
	RETURN (
		SELECT
			CASE
				WHEN col IS NULL
					THEN 'Null'
				WHEN col SIMILAR TO '%\d%' AND col NOT SIMILAR TO '%.%' AND col NOT SIMILAR TO '%[A-Za-z]%'
					THEN 'Integer'
				WHEN col SIMILAR TO '%\d%' AND col SIMILAR TO '%.%' AND col NOT SIMILAR TO '%[A-Za-z]%'
					THEN 'Numeric'
				WHEN col SIMILAR TO '%\D%'
					THEN 'Varchar'
			END AS data_type
	);
END;
$$
LANGUAGE PLPGSQL;