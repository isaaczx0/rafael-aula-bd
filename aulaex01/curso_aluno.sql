-- Active: 1787005321470@@127.0.0.1@5432@bd_aula@public
CREATE TABLE curso(
    id_curso INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE
);
CREATE TABLE aluno(
    id_aluno INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE,
    id_curso INTEGER NOT NULL REFERENCES curso (id_curso)
);
INSERT INTO curso(nome) VALUES ('S.I.'),
('Adm'),
('volkswagem'),
('Fisio');

INSERT INTO aluno(nome, id_curso) VALUES ('isaac', '3'),
('pedro', '3'),
('linyker', '3'),
('nael', '3');