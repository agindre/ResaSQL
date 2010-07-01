--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: projetibd; Type: DATABASE; Schema: -; Owner: simon
--

CREATE DATABASE projetibd WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'fr_FR.utf8' LC_CTYPE = 'fr_FR.utf8';


ALTER DATABASE projetibd OWNER TO simon;

\connect projetibd

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: simon
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO simon;

SET search_path = public, pg_catalog;

--
-- Name: dom_jour_semaine; Type: DOMAIN; Schema: public; Owner: simon
--

CREATE DOMAIN dom_jour_semaine AS character varying(9)
	CONSTRAINT chk_dom_jour_semaine CHECK (((VALUE)::text = ANY ((ARRAY['LUNDI'::character varying, 'MARDI'::character varying, 'MERCREDI'::character varying, 'JEUDI'::character varying, 'VENDREDI'::character varying, 'SAMEDI'::character varying, 'DIMANCHE'::character varying])::text[])));


ALTER DOMAIN public.dom_jour_semaine OWNER TO simon;

--
-- Name: dom_num_jour; Type: DOMAIN; Schema: public; Owner: simon
--

CREATE DOMAIN dom_num_jour AS smallint
	CONSTRAINT chk_dom_num_jour CHECK (((VALUE >= 1) AND (VALUE <= 31)));


ALTER DOMAIN public.dom_num_jour OWNER TO simon;

--
-- Name: dom_num_mois; Type: DOMAIN; Schema: public; Owner: simon
--

CREATE DOMAIN dom_num_mois AS integer
	CONSTRAINT chk_num_mois CHECK (((VALUE >= 1) AND (VALUE <= 12)));


ALTER DOMAIN public.dom_num_mois OWNER TO simon;

--
-- Name: dom_phone_num_fr; Type: DOMAIN; Schema: public; Owner: simon
--

CREATE DOMAIN dom_phone_num_fr AS character varying(15)
	CONSTRAINT chk_dom_phone_num_fr CHECK (((VALUE)::text ~ '^0[1-7]([-. ]?[0-9]{2}){4}$'::text));


ALTER DOMAIN public.dom_phone_num_fr OWNER TO simon;

--
-- Name: dom_unsigned_int; Type: DOMAIN; Schema: public; Owner: simon
--

CREATE DOMAIN dom_unsigned_int AS integer DEFAULT 0
	CONSTRAINT chk_dom_ui CHECK ((VALUE >= 0));


ALTER DOMAIN public.dom_unsigned_int OWNER TO simon;

--
-- Name: funct_del_reserv_nb_places(); Type: FUNCTION; Schema: public; Owner: simon
--

CREATE FUNCTION funct_del_reserv_nb_places() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
statut_del varchar(2);
BEGIN
SELECT INTO statut_del statut FROM reservation WHERE code_passager = OLD.code_passager AND num_vol = OLD.num_vol AND jour = OLD.jour AND mois = OLD.mois;
IF statut_del = 'OK' THEN
UPDATE depart SET nb_places_disp = nb_places_disp + 1 WHERE num_vol = OLD.num_vol AND jour = OLD.jour AND mois = OLD.mois;
END IF;
RETURN OLD;
END;
$$;


ALTER FUNCTION public.funct_del_reserv_nb_places() OWNER TO simon;

--
-- Name: funct_ins_reserv_nb_places(); Type: FUNCTION; Schema: public; Owner: simon
--

CREATE FUNCTION funct_ins_reserv_nb_places() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                              
DECLARE
statut_ins varchar(2);
nb_places integer;
BEGIN
SELECT INTO statut_ins statut FROM reservation WHERE code_passager = NEW.code_passager AND num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois;
IF statut_ins = 'OK' THEN
SELECT INTO nb_places nb_places_disp FROM depart WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois;
IF nb_places <> 0 THEN
UPDATE depart SET nb_places_disp = nb_places_disp - 1 WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois;
END IF;
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.funct_ins_reserv_nb_places() OWNER TO simon;

--
-- Name: funct_nb_places(); Type: FUNCTION; Schema: public; Owner: simon
--

CREATE FUNCTION funct_nb_places() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
nb_places_max integer;
BEGIN
SELECT into nb_places_max nb_places FROM type_avion NATURAL JOIN vol WHERE vol.num_vol = NEW.num_vol;
IF NEW.nb_places_disp > nb_places_max THEN
RAISE EXCEPTION 'Le nombre de places disponibles est superieur au nombre total de places';
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.funct_nb_places() OWNER TO simon;

--
-- Name: funct_passage_la_ok(); Type: FUNCTION; Schema: public; Owner: simon
--

CREATE FUNCTION funct_passage_la_ok() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
nb_la integer;
BEGIN
SELECT INTO nb_la COUNT(code_passager) FROM reservation WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois AND statut = 'LA';
IF nb_la > 0 THEN
UPDATE reservation SET statut = 'OK' WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois AND code_passager = (SELECT code_passager FROM reservation WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois AND statut = 'LA' GROUP BY num_vol, jour, mois HAVING date_reserv = MAX(date_reserv));
UPDATE depart SET nb_places_disp = nb_places_disp - 1 WHERE num_vol = NEW.num_vol AND jour = NEW.jour AND mois = NEW.mois;
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.funct_passage_la_ok() OWNER TO simon;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: continent; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE continent (
    code_continent smallint NOT NULL,
    nom_cont character varying(20) NOT NULL,
    num_dernier_vol integer,
    CONSTRAINT chk_code_continent CHECK (((code_continent >= 1) AND (code_continent <= 8)))
);


ALTER TABLE public.continent OWNER TO simon;

--
-- Name: seq_num_avion; Type: SEQUENCE; Schema: public; Owner: simon
--

CREATE SEQUENCE seq_num_avion
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_num_avion OWNER TO simon;

--
-- Name: seq_num_avion; Type: SEQUENCE SET; Schema: public; Owner: simon
--

SELECT pg_catalog.setval('seq_num_avion', 1, false);


--
-- Name: depart; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE depart (
    num_vol bigint NOT NULL,
    jour dom_num_jour NOT NULL,
    mois dom_num_mois NOT NULL,
    nb_places_disp dom_unsigned_int,
    num_avion integer DEFAULT nextval('seq_num_avion'::regclass)
);


ALTER TABLE public.depart OWNER TO simon;

--
-- Name: escale; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE escale (
    num_vol bigint NOT NULL,
    num_escale smallint NOT NULL,
    e_continent smallint,
    e_nom_ville character varying(100),
    e_h_arr timestamp with time zone,
    e_h_dep timestamp with time zone NOT NULL
);


ALTER TABLE public.escale OWNER TO simon;

--
-- Name: passager; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE passager (
    code_passager character varying(10) NOT NULL,
    nom_pass character varying(50) NOT NULL,
    prenom_pass character varying(50) NOT NULL,
    adresse_pass character varying(255) NOT NULL,
    departmt_pass character varying(3) NOT NULL,
    tel_pass dom_phone_num_fr,
    mail_pass character varying(255) NOT NULL,
    mdp_pass character varying(255) NOT NULL
);


ALTER TABLE public.passager OWNER TO simon;

--
-- Name: reservation; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE reservation (
    code_passager character varying(10) NOT NULL,
    num_vol bigint NOT NULL,
    jour dom_num_jour NOT NULL,
    mois dom_num_mois NOT NULL,
    date_reserv timestamp without time zone DEFAULT now() NOT NULL,
    date_limite_reserv timestamp without time zone DEFAULT now() NOT NULL,
    statut character(2) NOT NULL,
    CONSTRAINT chk_date_reserv CHECK ((date_reserv < date_limite_reserv)),
    CONSTRAINT chk_statut CHECK ((statut = ANY (ARRAY['OK'::bpchar, 'LA'::bpchar])))
);


ALTER TABLE public.reservation OWNER TO simon;

--
-- Name: seq_code_passager; Type: SEQUENCE; Schema: public; Owner: simon
--

CREATE SEQUENCE seq_code_passager
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_code_passager OWNER TO simon;

--
-- Name: seq_code_passager; Type: SEQUENCE SET; Schema: public; Owner: simon
--

SELECT pg_catalog.setval('seq_code_passager', 21, true);


--
-- Name: seq_type_avion; Type: SEQUENCE; Schema: public; Owner: simon
--

CREATE SEQUENCE seq_type_avion
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_type_avion OWNER TO simon;

--
-- Name: seq_type_avion; Type: SEQUENCE SET; Schema: public; Owner: simon
--

SELECT pg_catalog.setval('seq_type_avion', 1, false);


--
-- Name: type_avion; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE type_avion (
    num_type integer DEFAULT nextval('seq_type_avion'::regclass) NOT NULL,
    fabriquant character varying(50),
    modele character varying(30) NOT NULL,
    nb_places dom_unsigned_int,
    CONSTRAINT chk_nb_places CHECK (((nb_places)::integer < 800))
);


ALTER TABLE public.type_avion OWNER TO simon;

--
-- Name: ville_desservie; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE ville_desservie (
    code_continent integer NOT NULL,
    nom_ville character varying(100) NOT NULL
);


ALTER TABLE public.ville_desservie OWNER TO simon;

--
-- Name: vol; Type: TABLE; Schema: public; Owner: simon; Tablespace: 
--

CREATE TABLE vol (
    num_vol bigint NOT NULL,
    num_type integer,
    duree_vol interval DEFAULT '01:00:00'::interval NOT NULL,
    code_continent smallint,
    destination character varying(100),
    vol_h_depart timestamp with time zone NOT NULL,
    vol_h_arrivee timestamp with time zone NOT NULL,
    nb_h_vol interval DEFAULT '01:00:00'::interval NOT NULL,
    frequence dom_jour_semaine
);


ALTER TABLE public.vol OWNER TO simon;

--
-- Data for Name: continent; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (1, 'Europe', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (2, 'Amerique du Nord', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (3, 'Amerique du Sud', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (4, 'Asie', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (5, 'Afrique', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (6, 'Océanie', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (7, 'Arabie', NULL);
INSERT INTO continent (code_continent, nom_cont, num_dernier_vol) VALUES (8, 'Antarctique', NULL);


--
-- Data for Name: depart; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000002, 14, 7, 174, 37284);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000001, 16, 7, 73, 78072);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000001, 23, 7, 156, 78072);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000001, 26, 7, 219, 12345);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000001, 2, 8, 259, 75284);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000001, 30, 7, 106, 39285);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000001, 6, 8, 130, 9475);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000002, 28, 7, 217, 28594);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000002, 4, 8, 162, 3385);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000002, 8, 7, 43, 84902);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000002, 22, 7, 116, 18944);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000002, 29, 7, 184, 64599);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000002, 5, 8, 193, 27310);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (3000000001, 13, 7, 119, 19450);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (3000000001, 20, 7, 153, 1853);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (3000000001, 27, 7, 231, 63321);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (3000000001, 3, 8, 274, 73485);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (4000000001, 8, 7, 18, 28843);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (4000000001, 15, 7, 97, 84937);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (4000000001, 22, 7, 178, 30473);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (4000000001, 29, 7, 293, 30473);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (4000000001, 5, 8, 354, 74100);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (3000000001, 6, 7, 132, 1853);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000001, 12, 7, 132, 31454);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000001, 19, 7, 150, 85948);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000002, 21, 7, 73, 39610);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000001, 5, 7, 190, 12345);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000001, 9, 7, 67, 98321);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (2000000002, 15, 7, 81, 73422);
INSERT INTO depart (num_vol, jour, mois, nb_places_disp, num_avion) VALUES (1000000002, 7, 7, 35, 37284);


--
-- Data for Name: escale; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO escale (num_vol, num_escale, e_continent, e_nom_ville, e_h_arr, e_h_dep) VALUES (4000000001, 1, 7, 'Dubai', '2010-07-07 14:00:00+02', '2010-07-07 14:30:00+02');


--
-- Data for Name: passager; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('LAU91 0020', 'Laubet-Xavier', 'Simon', '42 cours Blaise Pascal', '91', '06-65-75-05-94', 'laubet.simon@gmail.com', '123456');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('LAU9750001', 'laudnf', 'qgqsg', 'Tapez votqdfsgdre adresse ici...', '975', NULL, 'fsdf.cdsff@dsfsd.com', 'qsdfsq');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('LAU9750002', 'laudnf', 'qgqsg', 'Tapez votqdfsgdre adresse ici...', '975', NULL, 'fsdf.cdsff@dsfsd.com', 'sdfgsd');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('LAU9750003', 'laudnf', 'qgqsg', 'Tapez votqdfsgdre adresse ici...', '975', NULL, 'fsdf.cdsff@dsfsd.com', 'sefdg');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('DFG0100001', 'dfgdf', 'fgdfg', 'Tapezdfgdfg votre adresse ici...', '01', NULL, 'dfgdf.dsq@qsdf.com', 'sdfsd');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('DFG0100002', 'dfgdf', 'fgdfg', 'Tapezdfgdfg votre adresse ici...', '01', NULL, 'dfgdf.dsq@qsdf.com', 'sdfsd');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('DFG0100003', 'dfgdf', 'fgdfg', 'Tapezdfgdfg votre adresse ici...', '01', NULL, 'dfgdf.dsq@qsdf.com', '&é"''');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('DFG0100004', 'dfgdf', 'fgdfg', 'Tapezdfgdfg votre adresse ici...', '01', NULL, 'dfgdf.dsq@qsdf.com', '&é"''');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('DFG0100005', 'dfgdf', 'fgdfg', 'Tapezdfgdfg votre adresse ici...', '01', NULL, 'dfgdf.dsq@qsdf.com', '-è');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('QSD0100001', 'qsdf', 'qsdf', 'Tapez voqsdfre adresse ici...', '01', NULL, 'sdqf.qsdf@sdf.com', '&é"''');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('QSD0100002', 'qsdf', 'qsdf', 'Tapez voqsdfre adresse ici...', '01', NULL, 'sdqf.qsdf@sdf.com', '&é"''');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('QSD0100003', 'qsdf', 'qsdf', 'Tapez voqsdfre adresse ici...', '01', NULL, 'sdqf.qsdf@sdf.com', '&é"');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('QSD0100004', 'qsdf', 'qsdf', 'Tapez voqsdfre adresse ici...', '01', NULL, 'sdqf.qsdf@sdf.com', '&é"');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('HGN0100001', 'hgng', 'hhng', 'Tapegnhz votre adresse ici...', '01', NULL, 'gnh.dfg@sfg.com', '&é"');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('SFE0100001', 'sfegfsd', 'Sfsd', 'Tapez votsdfre adresse ici...', '01', NULL, 'sdfsd.dsf@fsdf.com', 'éé&"');
INSERT INTO passager (code_passager, nom_pass, prenom_pass, adresse_pass, departmt_pass, tel_pass, mail_pass, mdp_pass) VALUES ('SDF1800001', 'sdfsdf', 'ssdf', 'Tapesdfsdz votre adresse ici...', '18', NULL, 'sdfsd.dsf@fsdf.com', 'sdfdsf');


--
-- Data for Name: reservation; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO reservation (code_passager, num_vol, jour, mois, date_reserv, date_limite_reserv, statut) VALUES ('LAU91 0020', 1000000001, 5, 7, '2010-07-01 19:03:22', '2010-07-15 19:03:22', 'OK');
INSERT INTO reservation (code_passager, num_vol, jour, mois, date_reserv, date_limite_reserv, statut) VALUES ('LAU91 0020', 2000000001, 9, 7, '2010-07-01 19:03:45', '2010-07-15 19:03:45', 'OK');
INSERT INTO reservation (code_passager, num_vol, jour, mois, date_reserv, date_limite_reserv, statut) VALUES ('LAU91 0020', 2000000002, 15, 7, '2010-07-01 19:04:24', '2010-07-15 19:04:24', 'OK');


--
-- Data for Name: type_avion; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (1, 'Boeing', '777', 450);
INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (2, 'Boeing', '747', 400);
INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (3, 'Boeing', '737', 180);
INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (4, 'Airbus', 'A380', 700);
INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (6, 'Airbus', 'A340', 350);
INSERT INTO type_avion (num_type, fabriquant, modele, nb_places) VALUES (5, 'Airbus', 'A320', 300);


--
-- Data for Name: ville_desservie; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Paris');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Londres');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Copenhague');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Madrid');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'New York');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (3, 'Rio de Janeiro');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Shanghai');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Johannesbourg');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (6, 'Sydney');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Dubai');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Los Angeles');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Montreal');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Vancouver');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Chicago');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'San Francisco');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Miami');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (2, 'Mexico');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (3, 'Montevideo');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (3, 'Santiago');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (3, 'Buenos Aires');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Pekin');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'New Dehli');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Tokyo');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Kyoto');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Bangkok');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (4, 'Taipei');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Alger');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Le Caire');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Bamako');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Marrakech');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (5, 'Nairobi');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (6, 'Melbourne');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (6, 'Auckland');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Medine');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Abu Dhabi');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Beyrouth');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Jerusalem');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (7, 'Bagdad');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Istambul');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Rome');
INSERT INTO ville_desservie (code_continent, nom_ville) VALUES (1, 'Reykjavik');


--
-- Data for Name: vol; Type: TABLE DATA; Schema: public; Owner: simon
--

INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (1000000001, 5, '02:00:00', 1, 'Londres', '2010-07-10 13:00:00+02', '2010-07-10 15:00:00+02', '02:00:00', 'LUNDI');
INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (2000000001, 2, '08:00:00', 2, 'New York', '2010-07-10 09:00:00+02', '2010-07-10 17:00:00+02', '08:00:00', 'VENDREDI');
INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (1000000002, 5, '02:30:00', 1, 'Copenhague', '2010-07-10 13:00:00+02', '2010-07-10 15:30:00+02', '02:30:00', 'MERCREDI');
INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (2000000002, 2, '11:00:00', 2, 'Los Angeles', '2010-07-10 08:30:00+02', '2010-07-10 19:30:00+02', '11:00:00', 'JEUDI');
INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (4000000001, 4, '09:00:00', 4, 'Shanghai', '2010-07-10 09:30:00+02', '2010-07-10 18:30:00+02', '09:00:00', 'JEUDI');
INSERT INTO vol (num_vol, num_type, duree_vol, code_continent, destination, vol_h_depart, vol_h_arrivee, nb_h_vol, frequence) VALUES (3000000001, 1, '11:45:00', 3, 'Rio de Janeiro', '2010-07-10 06:00:00+02', '2010-07-11 03:30:00+02', '11:45:00', 'MARDI');


--
-- Name: pk_continent; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY continent
    ADD CONSTRAINT pk_continent PRIMARY KEY (code_continent);


--
-- Name: pk_depart; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY depart
    ADD CONSTRAINT pk_depart PRIMARY KEY (num_vol, jour, mois);


--
-- Name: pk_escale; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY escale
    ADD CONSTRAINT pk_escale PRIMARY KEY (num_vol, num_escale);


--
-- Name: pk_passager; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY passager
    ADD CONSTRAINT pk_passager PRIMARY KEY (code_passager);


--
-- Name: pk_reservation; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY reservation
    ADD CONSTRAINT pk_reservation PRIMARY KEY (code_passager, num_vol, jour, mois);


--
-- Name: pk_type_avion; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY type_avion
    ADD CONSTRAINT pk_type_avion PRIMARY KEY (num_type);


--
-- Name: pk_ville_desservie; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY ville_desservie
    ADD CONSTRAINT pk_ville_desservie PRIMARY KEY (code_continent, nom_ville);


--
-- Name: pk_vol; Type: CONSTRAINT; Schema: public; Owner: simon; Tablespace: 
--

ALTER TABLE ONLY vol
    ADD CONSTRAINT pk_vol PRIMARY KEY (num_vol);


--
-- Name: trig_del_reserv; Type: TRIGGER; Schema: public; Owner: simon
--

CREATE TRIGGER trig_del_reserv
    BEFORE DELETE ON reservation
    FOR EACH ROW
    EXECUTE PROCEDURE funct_del_reserv_nb_places();


--
-- Name: trig_depart_nb_places; Type: TRIGGER; Schema: public; Owner: simon
--

CREATE TRIGGER trig_depart_nb_places
    BEFORE INSERT OR UPDATE ON depart
    FOR EACH ROW
    EXECUTE PROCEDURE funct_nb_places();


--
-- Name: trig_ins_reserv; Type: TRIGGER; Schema: public; Owner: simon
--

CREATE TRIGGER trig_ins_reserv
    AFTER INSERT ON reservation
    FOR EACH ROW
    EXECUTE PROCEDURE funct_ins_reserv_nb_places();


--
-- Name: trig_up_depart_la_ok; Type: TRIGGER; Schema: public; Owner: simon
--

CREATE TRIGGER trig_up_depart_la_ok
    AFTER UPDATE ON depart
    FOR EACH ROW
    EXECUTE PROCEDURE funct_passage_la_ok();


--
-- Name: fk_code_continent; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY vol
    ADD CONSTRAINT fk_code_continent FOREIGN KEY (code_continent) REFERENCES continent(code_continent);


--
-- Name: fk_code_continent; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY ville_desservie
    ADD CONSTRAINT fk_code_continent FOREIGN KEY (code_continent) REFERENCES continent(code_continent) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_code_passager; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY reservation
    ADD CONSTRAINT fk_code_passager FOREIGN KEY (code_passager) REFERENCES passager(code_passager);


--
-- Name: fk_escale_ville_desservie; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY escale
    ADD CONSTRAINT fk_escale_ville_desservie FOREIGN KEY (e_continent, e_nom_ville) REFERENCES ville_desservie(code_continent, nom_ville);


--
-- Name: fk_num_dernier_vol; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY continent
    ADD CONSTRAINT fk_num_dernier_vol FOREIGN KEY (num_dernier_vol) REFERENCES vol(num_vol);


--
-- Name: fk_num_vol; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY depart
    ADD CONSTRAINT fk_num_vol FOREIGN KEY (num_vol) REFERENCES vol(num_vol);


--
-- Name: fk_num_vol_escale; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY escale
    ADD CONSTRAINT fk_num_vol_escale FOREIGN KEY (num_vol) REFERENCES vol(num_vol);


--
-- Name: fk_reserv_depart; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY reservation
    ADD CONSTRAINT fk_reserv_depart FOREIGN KEY (num_vol, jour, mois) REFERENCES depart(num_vol, jour, mois);


--
-- Name: fk_type_avion; Type: FK CONSTRAINT; Schema: public; Owner: simon
--

ALTER TABLE ONLY vol
    ADD CONSTRAINT fk_type_avion FOREIGN KEY (num_type) REFERENCES type_avion(num_type);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

