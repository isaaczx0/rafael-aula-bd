# Aula 02. `SELECT`, `FROM` e a ordem lógica de execução

**Disciplina:** Sistemas de Banco de Dados I. Sistemas de Informação. UNIPAM.
**Item da ementa:** 4.3, consulta de recuperação básica em SQL.
**Referência:** ELMASRI, R. NAVATHE, S. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson. Capítulo 6.
**Ambiente:** PostgreSQL 17 em contêiner Docker, acessado pela extensão Database Client.
**Cenário:** tabela `notas_alunos`, com 50 registros. Script em `sql/cenario/03_notas_alunos.sql`.

---

## Sumário

1. Objetivo
2. O cenário: a tabela `notas_alunos`
3. Sintaxe geral da instrução `SELECT`
4. A cláusula `FROM`
5. A cláusula `SELECT`
6. Projeção e linhas repetidas
7. A ausência de ordem no resultado
8. A ordem lógica de execução
9. Formatação da consulta
10. Erros frequentes e leitura das mensagens
11. Script consolidado
12. Exercícios
13. Gabarito
14. Referências

---

## 1. Objetivo

O arquivo 01 percorreu o ciclo completo de um banco de dados e, para que esse ciclo ficasse visível, empregou recursos de consulta que não foram fundamentados. Este documento retoma a linguagem de consulta pelo primeiro degrau e estabelece, de modo completo, apenas dois elementos: a cláusula `FROM` e a cláusula `SELECT`.

Ao final, três resultados devem estar assegurados:

| Resultado | Descrição |
|---|---|
| Projeção | Compreender que `SELECT` escolhe colunas e não altera a quantidade de linhas |
| Origem | Compreender que `FROM` determina quais linhas e quais nomes de coluna existem |
| Ordem de execução | Compreender que a ordem em que as cláusulas são escritas não é a ordem em que são avaliadas |

O terceiro resultado é o mais importante do documento. Ele explica o comportamento de todas as cláusulas acrescentadas nos arquivos seguintes, e sua ausência é a causa mais frequente de erro na escrita de consultas.

Nenhum filtro, nenhuma ordenação e nenhum agrupamento são utilizados aqui. Esses recursos entram um a um, nos arquivos 04, 06, 08 e 26.

---

## 2. O cenário: a tabela `notas_alunos`

O cenário adotado neste arquivo e nos arquivos 04, 06 e 08 é uma tabela única, com volume suficiente para que os efeitos de cada cláusula sejam observáveis. Tabelas de poucas linhas escondem o comportamento das consultas, porque qualquer resultado cabe na tela e a diferença entre uma consulta correta e uma incorreta deixa de ser perceptível.

A tabela é independente das tabelas `curso` e `aluno` do arquivo 01. Nenhuma junção é possível entre elas, e nenhuma é necessária: a tabela única concentra a atenção sobre a instrução em estudo.

### 2.1 Estrutura

Cada linha registra a nota obtida por um aluno em uma disciplina, em uma avaliação.

| Coluna | Tipo | Significado |
|---|---|---|
| `id` | `INTEGER` | Identificador da linha, gerado pelo SGBD |
| `aluno_nome` | `TEXT` | Nome do aluno |
| `turma` | `TEXT` | Turma à qual o aluno pertence |
| `disciplina` | `TEXT` | Disciplina avaliada |
| `nota` | `INTEGER` | Nota obtida, de 0 a 100 |
| `faltas` | `INTEGER` | Quantidade de faltas registradas |
| `data_avaliacao` | `DATE` | Data em que a avaliação ocorreu |

O tipo `TEXT` é adotado nas colunas de texto porque nenhuma regra do domínio estabelece um comprimento máximo. Um limite arbitrário como `VARCHAR(50)` seria uma restrição inventada, e restrições inventadas rejeitam dados legítimos. O critério de escolha entre `TEXT` e `VARCHAR(n)` é tratado no arquivo 11.

### 2.2 Criação e carga

```sql
DROP TABLE IF EXISTS notas_alunos;

CREATE TABLE notas_alunos (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    aluno_nome     TEXT    NOT NULL,
    turma          TEXT    NOT NULL,
    disciplina     TEXT    NOT NULL,
    nota           INTEGER NOT NULL,
    faltas         INTEGER NOT NULL,
    data_avaliacao DATE    NOT NULL
);
```

A instrução `DROP TABLE IF EXISTS` remove a tabela caso ela já exista, de modo que o script possa ser executado mais de uma vez sem erro. A cláusula `IF EXISTS` evita a falha que ocorreria na primeira execução, quando não há o que remover.

A carga dos 50 registros está no arquivo `sql/cenario/03_notas_alunos.sql` e deve ser executada por inteiro. O conteúdo das instruções `CREATE TABLE` e `INSERT` foi tratado no arquivo 01, e volta a ser assunto nos arquivos 11 e 14.

### 2.3 Conferência

```sql
SELECT * FROM notas_alunos;
```

A ferramenta deve informar **50 linhas** e sete colunas. Qualquer número diferente indica que a carga não foi executada por completo, e nesse caso o script deve ser executado novamente desde o `DROP TABLE`.

Primeiras linhas da tabela:

| id | aluno_nome | turma | disciplina | nota | faltas | data_avaliacao |
|---|---|---|---|---|---|---|
| 1 | Aluno 01 | A | Matematica | 85 | 2 | 2026-09-01 |
| 2 | Aluno 02 | A | Matematica | 72 | 0 | 2026-09-01 |
| 3 | Aluno 03 | A | Matematica | 90 | 1 | 2026-09-01 |
| 4 | Aluno 04 | A | Matematica | 60 | 3 | 2026-09-01 |
| 5 | Aluno 05 | A | Matematica | 55 | 0 | 2026-09-01 |
| 6 | Aluno 06 | B | Matematica | 78 | 2 | 2026-09-02 |
| 7 | Aluno 07 | B | Matematica | 88 | 1 | 2026-09-02 |
| 8 | Aluno 08 | B | Matematica | 95 | 0 | 2026-09-02 |

Distribuição dos dados, útil para conferir resultados ao longo dos exercícios:

| Coluna | Valores presentes | Quantidade de linhas |
|---|---|---|
| `disciplina` | `Matematica` | 17 |
| `disciplina` | `Sistemas` | 17 |
| `disciplina` | `Portugues` | 16 |
| `turma` | `A` | 17 |
| `turma` | `B` | 17 |
| `turma` | `C` | 16 |

---

## 3. Sintaxe geral da instrução `SELECT`

A instrução completa possui a forma abaixo. Os colchetes indicam cláusulas opcionais e não fazem parte da sintaxe.

```
SELECT <lista de colunas>
FROM   <origem das linhas>
[WHERE <condicao sobre cada linha>]
[GROUP BY <colunas de agrupamento>]
[HAVING <condicao sobre cada grupo>]
[ORDER BY <colunas de ordenacao> [ASC | DESC]]
[LIMIT <quantidade>];
```

Somente a palavra `SELECT` é obrigatória. Cada cláusula opcional acrescenta uma operação ao processamento, e o material as introduz na seguinte distribuição:

| Cláusula | Função | Onde é estudada |
|---|---|---|
| `SELECT` | Escolhe e calcula as colunas do resultado | arquivo 02 |
| `FROM` | Determina a origem das linhas | arquivo 02 |
| `WHERE` | Descarta linhas que não satisfazem a condição | arquivos 04 e 06 |
| `GROUP BY` | Reúne linhas em grupos | arquivo 26 |
| `HAVING` | Descarta grupos que não satisfazem a condição | arquivo 26 |
| `ORDER BY` | Ordena o resultado | arquivo 08 |
| `LIMIT` | Restringe a quantidade de linhas devolvidas | arquivo 08 |

O ponto e vírgula encerra a instrução e indica ao servidor que ela está completa.

Uma consulta produz sempre **uma tabela**, ainda que de uma única linha e uma única coluna. Essa propriedade chama-se **fechamento** e é característica definidora do modelo relacional. Dela decorrem três fatos.

**A tabela de resultado é temporária.** Ela existe enquanto o resultado é exibido e não é gravada em disco. A tabela de origem permanece inalterada. `SELECT` jamais modifica dados.

**A tabela de resultado possui colunas com nome e tipo.** O cabeçalho exibido pela ferramenta não é decoração.

**O resultado de uma consulta pode servir de origem para outra.** Essa propriedade é o fundamento das subconsultas e das visões, tratadas nos arquivos 27 e 29.

---

## 4. A cláusula `FROM`

A cláusula `FROM` responde a uma única pergunta: **de onde vêm as linhas**.

```sql
SELECT aluno_nome
FROM notas_alunos;
```

O resultado possui 50 linhas e uma coluna. Nenhuma linha foi descartada, porque nenhum critério de descarte foi informado.

Primeiras linhas do resultado:

| aluno_nome |
|---|
| Aluno 01 |
| Aluno 02 |
| Aluno 03 |
| Aluno 04 |
| Aluno 05 |

`FROM` cumpre uma segunda função, menos evidente e mais importante: **estabelece quais nomes de coluna existem** para o restante da consulta. Antes de `FROM` ser avaliada, o nome `aluno_nome` não significa nada. Depois, significa a coluna `aluno_nome` da tabela `notas_alunos`.

A consequência aparece na seção 8, na análise das mensagens de erro: um nome de coluna só pode ser verificado depois que a origem for conhecida.

---

## 5. A cláusula `SELECT`

A cláusula `SELECT` responde a outra pergunta: **quais colunas compõem o resultado**. A operação chama-se **projeção**.

> **Elmasri, seção 6.3.** A projeção seleciona certas colunas da tabela e descarta as demais.

### 5.1 Lista explícita de colunas

```sql
SELECT aluno_nome, disciplina, nota
FROM notas_alunos;
```

Primeiras linhas do resultado:

| aluno_nome | disciplina | nota |
|---|---|---|
| Aluno 01 | Matematica | 85 |
| Aluno 02 | Matematica | 72 |
| Aluno 03 | Matematica | 90 |
| Aluno 04 | Matematica | 60 |
| Aluno 05 | Matematica | 55 |

As colunas `id`, `turma`, `faltas` e `data_avaliacao` existem na tabela e não aparecem no resultado, porque não foram citadas. A projeção descartou quatro colunas.

O número de linhas permanece 50. **A projeção não descarta linhas.** Descartar linhas é função da cláusula `WHERE`, tratada nos arquivos 04 e 06. Essa distinção precisa estar firme antes de qualquer avanço, porque as duas operações são frequentemente confundidas.

| Operação | Cláusula | Atua sobre | Efeito na quantidade de colunas | Efeito na quantidade de linhas |
|---|---|---|---|---|
| Projeção | `SELECT` | colunas | reduz ou mantém | nenhum |
| Seleção | `WHERE` | linhas | nenhum | reduz ou mantém |

### 5.2 A ordem das colunas é a ordem da lista

O resultado apresenta as colunas na ordem em que foram escritas, e não na ordem em que existem na tabela.

```sql
SELECT nota, disciplina, aluno_nome
FROM notas_alunos;
```

Primeiras linhas do resultado:

| nota | disciplina | aluno_nome |
|---|---|---|
| 85 | Matematica | Aluno 01 |
| 72 | Matematica | Aluno 02 |
| 90 | Matematica | Aluno 03 |

A tabela foi declarada com as colunas em outra ordem. O resultado obedece à lista da consulta, e não à declaração da tabela.

### 5.3 O asterisco

O asterisco representa todas as colunas da origem, na ordem de declaração da tabela.

```sql
SELECT *
FROM notas_alunos;
```

O asterisco é adequado para inspeção rápida do conteúdo de uma tabela, como na conferência da seção 2.3. Não é adequado em consultas destinadas a permanecer, por três razões.

**O resultado deixa de ser previsível.** Uma coluna acrescentada à tabela passa a aparecer no resultado sem que a consulta tenha sido alterada.

**A intenção não fica registrada.** A lista explícita documenta quais dados a consulta pretende obter. O asterisco não informa nada.

**Há custo desnecessário.** Colunas não utilizadas são lidas, transportadas pela rede e descartadas pela aplicação. Em uma tabela de sete colunas o desperdício é pequeno. Em tabelas reais, com dezenas de colunas e milhões de linhas, deixa de ser.

A recomendação é usar o asterisco durante a exploração e lista explícita em qualquer código que será conservado.

### 5.4 Repetição de coluna na lista

Nada impede que a mesma coluna apareça mais de uma vez.

```sql
SELECT nota, nota
FROM notas_alunos;
```

O resultado possui duas colunas, ambas chamadas `nota`, com valores idênticos. Isso é permitido porque a tabela de resultado é temporária e não precisa satisfazer as restrições de uma tabela armazenada, entre elas a unicidade dos nomes de coluna.

A consulta não tem utilidade prática. Serve para evidenciar que a lista de projeção é uma lista de expressões a calcular, e não uma seleção de colunas existentes. Essa distinção passa a ter consequência prática no arquivo 04, quando a lista passar a conter expressões aritméticas.

### 5.5 Valores constantes e a ausência de `FROM`

A lista de projeção aceita valores literais, e nesse caso a cláusula `FROM` pode ser omitida.

```sql
SELECT 'Boletim';
```

Resultado:

| ?column? |
|---|
| Boletim |

O resultado é uma tabela de uma linha e uma coluna. O cabeçalho `?column?` é a resposta do PostgreSQL a uma coluna sem nome: um literal não provém de nenhuma coluna e portanto não possui nome a herdar.

Um literal também pode acompanhar colunas reais.

```sql
SELECT 'nota:', aluno_nome, nota
FROM notas_alunos;
```

Primeiras linhas do resultado:

| ?column? | aluno_nome | nota |
|---|---|---|
| nota: | Aluno 01 | 85 |
| nota: | Aluno 02 | 72 |
| nota: | Aluno 03 | 90 |

O literal é repetido em cada uma das 50 linhas, porque a lista de projeção é avaliada uma vez por linha da origem.

A atribuição de um nome próprio à coluna de resultado é feita por meio de alias, recurso tratado no arquivo 08.

---

## 6. Projeção e linhas repetidas

A projeção pode fazer surgir linhas idênticas no resultado.

```sql
SELECT turma
FROM notas_alunos;
```

O resultado possui 50 linhas e apenas três valores distintos: `A`, `B` e `C`. A turma `A` aparece 17 vezes, a `B` 17 vezes e a `C` 16 vezes.

As 50 linhas da tabela diferem entre si, pois cada uma possui `id` próprio. Ao descartar todas as demais colunas, a projeção removeu justamente aquilo que as diferenciava.

O mesmo ocorre com combinações de colunas:

```sql
SELECT turma, disciplina
FROM notas_alunos;
```

O resultado possui 50 linhas. A combinação `A` com `Matematica` aparece nove vezes, porque nove linhas da tabela têm esses dois valores.

Este ponto exige atenção conceitual, porque a álgebra relacional e a linguagem SQL divergem aqui.

| Contexto | Tratamento de linhas repetidas |
|---|---|
| Álgebra relacional | Uma relação é um conjunto. A projeção elimina as repetições automaticamente |
| SQL | Uma tabela é um multiconjunto. As repetições são conservadas, salvo pedido explícito |

> **Elmasri, seção 6.3.1.** SQL não trata uma tabela como um conjunto, mas como um multiconjunto. Linhas repetidas podem existir tanto em tabelas armazenadas quanto em resultados de consulta.

A razão da escolha da linguagem é de custo. Eliminar repetições exige comparar todas as linhas entre si, operação cara. SQL não impõe esse custo a quem não o solicitou. A solicitação é feita pela palavra `DISTINCT`, apresentada no arquivo 08.

---

## 7. A ausência de ordem no resultado

Nenhuma consulta deste documento declara ordenação. A ordem em que as linhas aparecem, portanto, **não é garantida**.

A regra é a seguinte: sem `ORDER BY`, o SGBD devolve as linhas na ordem que lhe for mais conveniente. Essa ordem depende do plano de execução escolhido, da presença de índices, da quantidade de dados e de alterações anteriores nas linhas. Pode variar entre duas execuções da mesma consulta sobre os mesmos dados.

Os trechos de resultado publicados neste documento aparecem na ordem de inserção porque a tabela é pequena, foi recém-criada e nenhuma linha foi alterada depois da carga. Trata-se de uma coincidência observável, não de uma promessa da linguagem. Por essa razão os trechos foram apresentados como primeiras linhas de uma execução, e não como o resultado em sua ordem definitiva.

A consequência prática merece registro claro: **uma consulta cujo resultado precisa estar ordenado deve declarar a ordenação**. Confiar na ordem observada é um defeito que se manifesta apenas quando o volume de dados cresce, e portanto tarde. A cláusula `ORDER BY` é tratada no arquivo 08.

---

## 8. A ordem lógica de execução

Uma consulta SQL não é executada na ordem em que é escrita. A linguagem foi projetada para ser lida como uma frase, e a ordem de leitura difere da ordem de avaliação.

### 8.1 As etapas

| Etapa | Cláusula | Função |
|---|---|---|
| 1 | `FROM` | Determina a origem das linhas e os nomes de coluna disponíveis |
| 2 | `WHERE` | Descarta linhas que não satisfazem a condição |
| 3 | `GROUP BY` | Reúne linhas em grupos |
| 4 | `HAVING` | Descarta grupos que não satisfazem a condição |
| 5 | `SELECT` | Calcula as colunas do resultado e atribui os alias |
| 6 | `DISTINCT` | Elimina linhas repetidas do resultado |
| 7 | `ORDER BY` | Ordena o resultado |
| 8 | `LIMIT` | Restringe a quantidade de linhas devolvidas |

Neste documento apenas as etapas 1 e 5 estão em uso. As demais aparecem para que a estrutura completa fique conhecida desde o princípio, e para que cada arquivo seguinte possa ser situado nela.

O contraste entre as duas ordens:

```
ordem de escrita:    SELECT  ->  FROM  ->  WHERE  ->  GROUP BY  ->  HAVING  ->  ORDER BY  ->  LIMIT

ordem de avaliacao:  FROM  ->  WHERE  ->  GROUP BY  ->  HAVING  ->  SELECT  ->  DISTINCT  ->  ORDER BY  ->  LIMIT
```

A cláusula escrita em primeiro lugar é avaliada em quinto. A inversão não é um detalhe de implementação: dela decorre o comportamento de várias construções da linguagem.

### 8.2 Por que `FROM` precede `SELECT`

A razão é de dependência. A cláusula `SELECT` precisa calcular expressões sobre colunas. Para saber se `nota` é uma coluna válida, e a qual tabela pertence, é necessário conhecer antes o conjunto de tabelas envolvidas. Esse conjunto é justamente o que `FROM` estabelece.

Avaliar `SELECT` primeiro exigiria decidir o significado de um nome antes de conhecer sua origem, o que não é possível.

### 8.3 Consequência observável

A ordem de avaliação pode ser verificada por meio das mensagens de erro. Considere uma consulta com dois problemas simultâneos: a tabela não existe e a coluna também não.

```sql
SELECT sobrenome
FROM notas_aluno;
```

Mensagem produzida:

```
ERROR:  relation "notas_aluno" does not exist
LINE 2: FROM notas_aluno;
             ^
```

O SGBD reclamou da tabela e nada disse a respeito da coluna `sobrenome`, que também não existe. A verificação da origem ocorreu primeiro e interrompeu o processamento antes que a lista de projeção fosse examinada.

Corrigido o nome da tabela, o segundo problema aparece:

```sql
SELECT sobrenome
FROM notas_alunos;
```

Mensagem produzida:

```
ERROR:  column "sobrenome" does not exist
LINE 1: SELECT sobrenome
               ^
```

A sequência das duas mensagens é evidência direta da ordem de avaliação: a etapa 1 é verificada antes da etapa 5.

### 8.4 Consequências que aparecem adiante

Duas outras consequências da ordem lógica serão observadas quando as demais cláusulas entrarem em uso, e ficam registradas aqui para que sejam reconhecidas quando surgirem.

**Alias não pode ser usado em `WHERE`.** O alias é criado na etapa 5, e `WHERE` é avaliado na etapa 2. O caso é examinado no arquivo 08.

**`WHERE` não aceita função de agregação.** `WHERE` é avaliado antes do agrupamento, de modo que não existe grupo sobre o qual calcular. Filtros que dependem de valor agregado pertencem ao `HAVING`, tratado no arquivo 26.

Esta ordem é **lógica**, não física. O otimizador do SGBD é livre para executar as operações em qualquer sequência, desde que o resultado seja idêntico ao da ordem lógica. A ordem lógica descreve o significado da consulta, e não o procedimento de execução.

---

## 9. Formatação da consulta

O SGBD ignora quebras de linha e espaços adicionais. As três instruções abaixo são equivalentes para o servidor.

```sql
SELECT aluno_nome, nota FROM notas_alunos;
```

```sql
SELECT aluno_nome, nota
FROM notas_alunos;
```

```sql
SELECT
    aluno_nome,
    nota
FROM
    notas_alunos;
```

A escolha é dirigida ao leitor humano, e a convenção adotada no material é a seguinte.

| Regra | Motivo |
|---|---|
| Palavras reservadas em caixa alta | Distingue a linguagem dos identificadores do banco |
| Identificadores em caixa baixa, sem acento e sem aspas | O PostgreSQL converte identificadores não delimitados para caixa baixa. O assunto é tratado na seção 13 do arquivo 01 |
| Cada cláusula inicia uma linha | Torna visível a estrutura da consulta |
| Uma coluna por linha em listas longas | Reduz o esforço de conferência e facilita o acréscimo de colunas |

Consultas curtas em uma única linha são aceitáveis durante a exploração. Consultas destinadas a permanecer devem seguir a convenção.

---

## 10. Erros frequentes e leitura das mensagens

A mensagem de erro do PostgreSQL indica a natureza do problema e sua posição. Sua leitura é parte do trabalho e dispensa tentativa e erro.

| Mensagem | Causa | Correção |
|---|---|---|
| `relation "x" does not exist` | A tabela citada em `FROM` não existe, ou está grafada de outro modo | Conferir a grafia e o número gramatical do nome |
| `column "x" does not exist` | O nome citado em `SELECT` não é coluna de nenhuma tabela da cláusula `FROM` | Conferir a grafia e a tabela de origem |
| `syntax error at or near "x"` | A instrução não obedece à gramática da linguagem | Examinar o trecho indicado e o imediatamente anterior |
| `unterminated quoted string` | Um literal de texto foi aberto com aspas simples e não foi fechado | Fechar o literal |

Dois casos merecem observação particular, porque não produzem mensagem alguma.

**Vírgula ausente entre colunas.** A instrução abaixo não produz erro.

```sql
SELECT aluno_nome nota
FROM notas_alunos;
```

O PostgreSQL interpreta `nota` como um nome atribuído à coluna `aluno_nome`, e o resultado tem uma única coluna, chamada `nota`, contendo nomes de alunos. Trata-se de alias sem a palavra `AS`, construção tratada no arquivo 08. O caso é registrado aqui porque um resultado errado sem mensagem de erro é mais difícil de perceber do que um erro declarado.

**Aspas duplas em lugar de aspas simples.** A instrução `SELECT "Boletim";` não produz o texto esperado. Aspas simples delimitam literais de texto. Aspas duplas delimitam identificadores, e o SGBD procurará uma coluna com esse nome, produzindo `column "Boletim" does not exist`.

---

## 11. Script consolidado

```sql
-- =============================================================
-- Aula 02. SELECT, FROM e a ordem logica de execucao
-- Cenario: tabela notas_alunos, 50 registros
-- Pre-requisito: executar sql/cenario/03_notas_alunos.sql
-- =============================================================

-- -------------------------------------------------------------
-- 1. Conferencia da carga: 50 linhas, sete colunas
-- -------------------------------------------------------------

SELECT * FROM notas_alunos;

-- -------------------------------------------------------------
-- 2. A clausula FROM determina a origem das linhas
-- -------------------------------------------------------------

SELECT aluno_nome
FROM notas_alunos;

-- -------------------------------------------------------------
-- 3. A clausula SELECT projeta colunas
-- -------------------------------------------------------------

SELECT aluno_nome, disciplina, nota
FROM notas_alunos;

-- A ordem das colunas do resultado e a ordem da lista
SELECT nota, disciplina, aluno_nome
FROM notas_alunos;

-- A mesma coluna pode aparecer mais de uma vez
SELECT nota, nota
FROM notas_alunos;

-- -------------------------------------------------------------
-- 4. Valores constantes e ausencia de FROM
-- -------------------------------------------------------------

SELECT 'Boletim';

SELECT 'nota:', aluno_nome, nota
FROM notas_alunos;

-- -------------------------------------------------------------
-- 5. A projecao pode produzir linhas repetidas
-- -------------------------------------------------------------

SELECT turma
FROM notas_alunos;

SELECT turma, disciplina
FROM notas_alunos;

-- -------------------------------------------------------------
-- 6. Ordem de avaliacao: a origem e verificada antes da projecao
--    As duas instrucoes abaixo produzem erro, de proposito.
-- -------------------------------------------------------------

SELECT sobrenome
FROM notas_aluno;

SELECT sobrenome
FROM notas_alunos;
```

---

## 12. Exercícios

Os exercícios utilizam a tabela `notas_alunos` com os 50 registros da seção 2. Nenhum deles requer cláusula ainda não apresentada.

1. Recuperar todas as colunas de todas as linhas da tabela.
2. Recuperar apenas a coluna `aluno_nome`.
3. Recuperar as colunas `aluno_nome`, `turma` e `nota`, nessa ordem.
4. Recuperar as mesmas colunas do exercício 3, dispondo `nota` em primeiro lugar.
5. Recuperar as colunas `disciplina` e `data_avaliacao`.
6. Indicar, sem executar, quantas linhas e quantas colunas possui o resultado de `SELECT faltas FROM notas_alunos;`.
7. Indicar, sem executar, quantos valores distintos aparecem no resultado do exercício 6, sabendo que as faltas registradas variam de 0 a 5.
8. Explicar por que o resultado de `SELECT disciplina FROM notas_alunos;` apresenta o valor `Matematica` dezessete vezes, ao passo que a tabela não possui linhas repetidas.
9. Explicar, sem executar, por que a instrução abaixo é recusada e qual das duas cláusulas provoca a recusa.

   ```sql
   SELECT aluno_nome
   FROM notas;
   ```

10. Explicar, sem executar, por que a instrução abaixo é recusada.

    ```sql
    SELECT aluno_nome, media
    FROM notas_alunos;
    ```

11. Determinar, sem executar, o resultado da instrução abaixo, incluindo a quantidade de colunas e o conteúdo de cada uma.

    ```sql
    SELECT turma disciplina
    FROM notas_alunos;
    ```

12. Determinar, sem executar, o resultado da instrução abaixo.

    ```sql
    SELECT 'turma', turma
    FROM notas_alunos;
    ```

13. Ordenar as cláusulas `SELECT`, `FROM`, `ORDER BY` e `WHERE` segundo a ordem de avaliação, e não segundo a ordem de escrita.
14. Justificar, com base na ordem lógica de execução, por que a cláusula `WHERE` pode filtrar por uma coluna que não aparece na lista do `SELECT`.

---

## 13. Gabarito

**1.**

```sql
SELECT *
FROM notas_alunos;
```

Cinquenta linhas e sete colunas. A forma com lista explícita produz resultado idêntico e é preferível em código destinado a permanecer.

**2.**

```sql
SELECT aluno_nome
FROM notas_alunos;
```

**3.**

```sql
SELECT aluno_nome, turma, nota
FROM notas_alunos;
```

**4.**

```sql
SELECT nota, aluno_nome, turma
FROM notas_alunos;
```

A tabela de origem não foi alterada. Apenas a lista de projeção mudou, e com ela a ordem das colunas do resultado.

**5.**

```sql
SELECT disciplina, data_avaliacao
FROM notas_alunos;
```

**6.** Cinquenta linhas e uma coluna. A quantidade de linhas é a da tabela, pois nenhum descarte de linhas foi solicitado. A quantidade de colunas é a da lista de projeção.

**7.** No máximo seis valores distintos, correspondentes a 0, 1, 2, 3, 4 e 5. O resultado continua com 50 linhas, porque a projeção conserva as repetições. A quantidade de valores distintos e a quantidade de linhas do resultado são grandezas diferentes, e confundi-las é erro frequente.

**8.** As 50 linhas diferem entre si pelo valor de `id`, que é chave primária. A projeção descartou todas as colunas exceto `disciplina`, isto é, descartou exatamente aquilo que distinguia as linhas. O que restou foi o valor da disciplina, repetido para as dezessete avaliações de Matemática. SQL trata tabelas como multiconjuntos e conserva as repetições, ao contrário da projeção da álgebra relacional.

**9.** A recusa é provocada pela cláusula `FROM`. Não existe tabela chamada `notas`, apenas `notas_alunos`. A mensagem é `relation "notas" does not exist`. A cláusula `SELECT` sequer chega a ser avaliada, porque a etapa 1 antecede a etapa 5.

**10.** A recusa é provocada pela cláusula `SELECT`. A tabela existe e a etapa 1 é concluída, mas suas colunas são `id`, `aluno_nome`, `turma`, `disciplina`, `nota`, `faltas` e `data_avaliacao`. Não há coluna chamada `media`, e a mensagem é `column "media" does not exist`. A média não é um dado armazenado, e sim um valor calculado a partir de `nota` por uma função de agregação, assunto do arquivo 26.

**11.** O resultado possui uma única coluna, de cabeçalho `disciplina`, contendo os valores `A`, `B` e `C`. A vírgula ausente faz com que `disciplina` seja interpretado como alias da coluna `turma`, e não como uma segunda coluna. A instrução é válida e não produz erro, razão pela qual esse tipo de engano é difícil de localizar. O cabeçalho enganoso agrava o caso, porque anuncia disciplina e entrega turma.

**12.** Cinquenta linhas e duas colunas. A primeira, de cabeçalho `?column?`, contém o texto `turma` repetido em todas as linhas. A segunda contém os valores da coluna `turma`. O literal está entre aspas simples e por isso é texto, não identificador. Escrito entre aspas duplas seria interpretado como nome de coluna.

**13.** `FROM`, `WHERE`, `SELECT`, `ORDER BY`. A cláusula escrita em primeiro lugar é a penúltima a ser avaliada.

**14.** Porque `WHERE` é avaliado na etapa 2 e a projeção ocorre apenas na etapa 5. No momento em que a condição do filtro é verificada, todas as colunas da origem ainda estão disponíveis, e nenhuma foi descartada. O descarte de colunas acontece depois.

---

## 14. Referências

ELMASRI, Ramez. NAVATHE, Shamkant B. *Sistemas de Banco de Dados*. 7. ed. São Paulo: Pearson, 2018. Capítulo 6, seções 6.2 e 6.3.

POSTGRESQL GLOBAL DEVELOPMENT GROUP. *PostgreSQL 17 Documentation*, capítulo 7, Queries. Disponível em `https://www.postgresql.org/docs/17/queries.html`.
