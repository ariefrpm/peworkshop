CREATE OR REPLACE FUNCTION insert_location(lname TEXT, parent NUMERIC)
RETURNS VOID
AS $$
BEGIN
  INSERT INTO logistic.location (name) VALUES ($1);
  INSERT INTO logistic.location_path (parent_id, child_id, depth)
    SELECT p.parent_id, currval('logistic.location_id_seq'), p.depth+1
      FROM logistic.location_path p
      WHERE p.child_id = $2
  UNION ALL
    SELECT currval('logistic.location_id_seq'), currval('logistic.location_id_seq'), 0;
END
$$ 
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_location(loc NUMERIC)
RETURNS VOID
AS $$
BEGIN
DELETE FROM logistic.location_path
  WHERE parent_id = $1;
DELETE FROM logistic.location
  WHERE id = $1;
END
$$ 
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION migrate_location(l_from numeric, l_to numeric)
RETURNS VOID
AS $$
BEGIN
  DELETE FROM logistic.location_path
    WHERE child_id IN ( SELECT child_id
                      FROM logistic.location_path
                      WHERE parent_id = $1)
    AND parent_id IN ( SELECT parent_id
                     FROM logistic.location_path
                     WHERE child_id = $1
                      AND parent_id != child_id);
                      
  INSERT INTO logistic.location_path (parent_id, child_id, depth)
    SELECT p.parent_id, subp.child_id, (subp.depth+p.depth+1)
    FROM logistic.location_path p
    CROSS JOIN logistic.location_path subp
      WHERE p.child_id = $2
      AND subp.parent_id = $1;
END
$$ 
LANGUAGE plpgsql;
