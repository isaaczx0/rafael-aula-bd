-- Active: 1787097273941@@127.0.0.1@5432@bd_aula@public
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

SELECT table_name,
       column_name,
       data_type,
       character_maximum_length AS tamanho,
       is_nullable              AS aceita_nulo,
       is_identity              AS e_identidade
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('curso', 'aluno')
ORDER BY table_name, ordinal_position;

SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'curso';

SELECT 
    nome, 
    id_curso 
FROM 
    aluno 
WHERE 
    id_curso = 1
ORDER BY
    nome DESC;

SELECT
    a.nome AS aluno,
    c.nome AS curso
FROM 
    aluno a
JOIN aluno c
ON c.id_curso = a.id_curso
ORDER BY c.nome;


SELECT  c.nome AS curso, c.id_curso FROM curso c WHERE nome = 'S.I.'

SELECT c.nome AS curso, COUNT (a.id_aluno) FROM curso c JOIN aluno a ON a.id_curso = c.id_curso 
GROUP BY c.nome;