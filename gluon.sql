-- Gluon engine rules v0.1
-- PostgreSQL script
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA pllua;
CREATE EXTENSION IF NOT EXISTS pllua WITH SCHEMA pllua;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;

CREATE SCHEMA gluon;

SET search_path = public, pg_catalog;


CREATE FUNCTION exec_lua(v_rule text, v_nfo hstore) RETURNS text
    LANGUAGE sql
    AS $$
select exec_lua(v_rule, akeys(v_nfo), avals(v_nfo));
$$;

CREATE FUNCTION exec_lua(v_rule text, v_key text[], v_val text[]) RETURNS text
    LANGUAGE pllua
    AS $$

local function myloadstring(str, name)
  local f, err = loadstring("return function (nfo) " .. str .. " end", name or str)
  if f then return f() else return f, err end
end

local data = {}
for k, v in pairs(v_key) do data[v_key[k]] = v_val[k] end

local chunck = myloadstring(v_rule)
return chunck(data)
$$;

CREATE FUNCTION exec_particle_dyn(v_code_particle text[], v_nfo hstore) RETURNS hstore
    LANGUAGE plpgsql
    AS $$
DECLARE
cur cursor for with particles as (select hstore(array_agg(id::text), array_agg(code)) as nfo_particle from particle)
                select nfo_particle->(input::text[]) as input_particle, 
                  nfo_particle->(output::text) as output_particle, 
                  unnest(rule) as rule, 
                  unnest(switch) as switch, 
                  test, 
                  nfo as nfo_rule
                from solve_particle(v_code_particle)
                inner join particles p on true;
rowvar record;
result text;
nfo_stock hstore;
BEGIN 
nfo_stock = v_nfo;
FOR r IN cur LOOP
  select hstore(r.output_particle, exec_lua(r.rule, slice(nfo_stock||r.nfo_rule, r.input_particle))) || nfo_stock into nfo_stock;
END LOOP ;
return nfo_stock;
END
$$;


CREATE SEQUENCE rule_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rule_id OWNER TO postgres;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE rule (
    id integer DEFAULT nextval('rule_id'::regclass) NOT NULL,
    input integer[],
    output integer,
    rule text[],
    switch hstore[],
    test hstore[],
    nfo hstore
);

CREATE FUNCTION solve_particle(v_code_particle text[]) RETURNS SETOF rule
    LANGUAGE sql
    AS $$
with recursive seeker as (select 1 as rank, r.id as id_rule, p.id as id_particle,  input 
           from particle p 
           inner join rule r on r.output = p.id
           where code = any(v_code_particle)
           union select rank+1 as order, r.id, r.output as id_particle, r.input from seeker s
           inner join rule r on r.output = any(s.input))
select r.* from seeker s inner join rule r on r.id = s.id_rule group by r.id order by min(rank) desc;
$$;


CREATE SEQUENCE particle_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE particle_id OWNER TO postgres;

CREATE TABLE particle (
    id integer DEFAULT nextval('particle_id'::regclass) NOT NULL,
    code text,
    nfo hstore
);

ALTER TABLE ONLY particle
    ADD CONSTRAINT particle_pkey PRIMARY KEY (id);

ALTER TABLE ONLY rule
    ADD CONSTRAINT rule_pkey PRIMARY KEY (id);

