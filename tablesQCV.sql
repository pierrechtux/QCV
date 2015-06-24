BEGIN TRANSACTION;      -- embeds all script within a transaction

-- Question générale: on laisse les noms de champs en français, ou on suit les bonnes pratiques du moment, à savoir de tout coder en anglois? Si l'outil a une vocation uniquement nationale, on peut laisser en français; si on le veut plus international, la langue de Shakespeare serait préférable à celle de Rabelais.

-- \connect - postgres

--Séquences:--{{{
CREATE SEQUENCE no_quest;
CREATE SEQUENCE no_test;
COMMENT ON SEQUENCE no_quest                IS 'Numérotation automatique des numéros de questions';
COMMENT ON SEQUENCE no_test                 IS 'Numérotation automatique des numéros de tests';
--}}}

CREATE TABLE personnes (--{{{
    nom         character varying(40)       PRIMARY KEY,
    mail        character varying(64)       NOT NULL DEFAULT '?');
COMMENT ON TABLE personnes  IS 'Table personnes: utilisateurs (personnes faisant les tests, rédacteurs de questions et de réponses) ou validateurs ou administrateurs'; --TODO: faire référence à un annuaire LDAP
COMMENT ON COLUMN personnes.nom             IS 'Nom de la personne, clé primaire';
COMMENT ON COLUMN personnes.mail            IS 'Adresse électronique de la personne';
--}}}

CREATE TABLE typemultimedia (--{{{
    typmmd      character varying(24)       PRIMARY KEY);
COMMENT ON TABLE typemultimedia             IS 'Lexique?';      -- TODO pas pigé
COMMENT ON COLUMN typemultimedia.typmmd     IS '??';
--}}}

CREATE TABLE difficultes (--{{{
    difficulte  int4                        PRIMARY KEY,
    libdiff     character varying(44));
COMMENT ON TABLE difficultes                IS 'Lexique des difficultés';
COMMENT ON COLUMN difficultes.difficulte    IS 'Niveau de difficulté';              -- préciser: de 1 à 3, 0 à 5, 0 à 10, 0 à 100?
COMMENT ON COLUMN difficultes.libdiff       IS 'Libellé du niveau de difficulté';   -- on pourrait peut-être faire l'économie d'une table, non?
--}}}

CREATE TABLE pertinences (--{{{
    pertinence  int4                        PRIMARY KEY,
    libpert     character varying(44));
COMMENT ON TABLE pertinences                 IS 'Pertinence';
COMMENT ON COLUMN pertinences.pertinence     IS 'Pertinence';                        --...
COMMENT ON COLUMN pertinences.libpert        IS 'Libellé de pertinence';
--}}}

CREATE TABLE humour (--{{{
    humour      int4                        PRIMARY KEY,
    libhum      character varying(44));
COMMENT ON TABLE humour                     IS 'Humour, rigolade';
COMMENT ON COLUMN humour.humour             IS e'Degré d\'humour';
COMMENT ON COLUMN humour.libhum             IS 'Libellé humoristique';
--}}}

CREATE TABLE testtypes (--{{{
    testtype    character varying(24)       PRIMARY KEY,
    libtype     character varying(44));
COMMENT ON TABLE testtypes                  IS '?';                                 --?
COMMENT ON COLUMN testtypes.testtype        IS 'Type de test';
COMMENT ON COLUMN testtypes.libtype         IS 'Libellé du type de test';           --?
--}}}

CREATE TABLE refthemes (--{{{
    themes      character varying(80)       PRIMARY KEY,
    valideur    character varying(40)                   REFERENCES personnes ON UPDATE CASCADE);
COMMENT ON TABLE refthemes                  IS 'Thèmes de référence';               --?
COMMENT ON COLUMN refthemes.themes          IS 'Thèmes';
COMMENT ON COLUMN refthemes.valideur        IS 'Personne qui valide le thème; fait référence à personnes.nom';
--}}}

CREATE TABLE themes (--{{{
    theme       character varying(80)       PRIMARY KEY REFERENCES refthemes,
    themesup    character varying(80)                   REFERENCES refthemes);
COMMENT ON TABLE themes                     IS 'Thèmes';                            -- ce sont les sous-thèmes? On aurait pu faire un genre de liste chaînée avec une seule table, plutôt, non?
COMMENT ON COLUMN themes.theme              IS 'Thème, fait référence à refthemes.themes';
COMMENT ON COLUMN themes.themesup           IS 'Thème de niveau supérieur';
--}}}

CREATE TABLE questions (--{{{
    noq         int4                        PRIMARY KEY DEFAULT nextval('no_quest'),
    question    text,
    reponse     text,
    auteur      character varying(40)       DEFAULT CURRENT_USER, -- pas de FK
    valideur    character varying(40)                   REFERENCES personnes ON UPDATE CASCADE,
    date date                               DEFAULT CURRENT_DATE);
COMMENT ON TABLE questions                  IS 'Table des questions';
COMMENT ON COLUMN questions.noq             IS 'Numéro de question, auto-incrémenté';
COMMENT ON COLUMN questions.question        IS 'Libellé de la question';
COMMENT ON COLUMN questions.reponse         IS 'Réponse';                       -- j'ai toujours pas pigé, mais ça va venir...
COMMENT ON COLUMN questions.auteur          IS 'Personne (username au sens rôle postgresql) auteur de la question';        -- on pourrait faire référence à personnes, en passant par un login sur la base basé sur le LDAP, à terme.
COMMENT ON COLUMN questions.valideur        IS 'Personne ayant validé la question; fait référence à personnes.nom';
COMMENT ON COLUMN questions.date            IS 'Date courante';                 -- on pourrait mettre un timestamp

--}}}

CREATE TABLE choix (--{{{
    noq       int4                          REFERENCES questions,
    noc       int4                          CHECK (noc BETWEEN 1 AND 99),
    val       int4                          NOT NULL DEFAULT 0,
    choix     character varying(256),
    comment   character varying(80),
    humour    int4                          REFERENCES humour DEFAULT 0,
    valideur  character varying(40)         REFERENCES personnes ON UPDATE CASCADE,
    date 		date                        DEFAULT CURRENT_DATE,
    PRIMARY KEY (noq,noc));
COMMENT ON TABLE choix                 IS 'Table des choix';
COMMENT ON COLUMN choix.noq            IS 'Numéro de question, fait référence à questions.';
--}}}

CREATE TABLE multimedia (--{{{
    noq int4 REFERENCES questions,
    typmmd character varying(24) REFERENCES typemultimedia,
    url character varying(128),
    legende character varying(80));
--}}}

CREATE TABLE sujets (--{{{
    noq int4 REFERENCES questions,
    theme character varying(80) REFERENCES themes ,
    pertinence int4 REFERENCES pertinences DEFAULT 9 ,
    difficulte int4 REFERENCES difficultes DEFAULT 9,
    humour int4 REFERENCES humour DEFAULT 0);
--}}}

CREATE TABLE memoire (--{{{
    notest int4 PRIMARY KEY DEFAULT nextval('no_test'),
    utilisateur character varying(40) REFERENCES personnes ON UPDATE CASCADE,
    theme character varying(80) REFERENCES themes,
    nbq   int4 NOT NULL DEFAULT 0,
    score int4 NOT NULL DEFAULT 0,
    ideal int4 NOT NULL DEFAULT 0,
    duree INTERVAL,
    datedeb timestamp  DEFAULT CURRENT_TIMESTAMP,
    datefin timestamp  DEFAULT CURRENT_TIMESTAMP,
    pertinence int4 REFERENCES pertinences DEFAULT 0,
    difficulte int4 REFERENCES difficultes DEFAULT 0,
    testtype character varying(24) REFERENCES testtypes );
--}}}

CREATE TABLE details (--{{{
    utilisateur character varying(40) REFERENCES personnes ON UPDATE CASCADE,
    datetest date  DEFAULT CURRENT_DATE,
    noq int4 REFERENCES questions,
    notest int4 REFERENCES memoire,
    score int4 NOT NULL DEFAULT 0); -- (note_max - resultat)
--}}}

CREATE FUNCTION calc_duree(timestamp,timestamp)--{{{
RETURNS interval
AS 'SELECT CAST(($1 - $2) AS INTERVAL);'
LANGUAGE SQL;
--}}}

COMMIT;                     -- end of transaction

