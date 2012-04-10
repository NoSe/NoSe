
DROP TABLE folder;

CREATE TABLE folder
(
  id serial,
  parent_id integer,
  description character varying(64) DEFAULT ''::character varying,
  CONSTRAINT folder_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE folder OWNER TO postgres;

DROP TABLE instrument;

CREATE TABLE instrument
(
  id serial,
  folder_id integer,
  code character varying(64) DEFAULT ''::character varying,
  description character varying(64) DEFAULT ''::character varying,
  CONSTRAINT instrument_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE instrument OWNER TO postgres;
