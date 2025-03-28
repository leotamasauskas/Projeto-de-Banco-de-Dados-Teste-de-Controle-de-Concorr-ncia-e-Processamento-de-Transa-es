-- 1. Primeiro verifique se as matrículas já existem
SELECT * FROM Alunos WHERE matricula IN ('20221114004', '20221114002');

-- 2. Se existirem, atualize os dados desses registros
UPDATE Alunos SET
    nome = 'Leonardo de Oliveira Tamasauskas',
    email = CONCAT('leonardo.tamasauskas', '@icen.ufpa.com.br')
WHERE matricula = '20221114004';

UPDATE Alunos SET
    nome = 'Geovana Kelly Cascaes Saldanha',
    email = CONCAT('geovana.saldanha',  '@icen.ufpa.com.br')
WHERE matricula = '20221114002';

-- 3. Se não existirem, insira normalmente
INSERT INTO Alunos (nome, email, matricula)
SELECT * FROM (
    SELECT 'Leonardo de Oliveira Tamasauskas' AS nome, 
           CONCAT('leonardo.tamasauskas',  '@icen.ufpa.com.br') AS email,
           '20221114004' AS matricula
) AS tmp
WHERE NOT EXISTS (
    SELECT 1 FROM Alunos WHERE matricula = '20221114004'
) LIMIT 1;

INSERT INTO Alunos (nome, email, matricula)
SELECT * FROM (
    SELECT 'Geovana Kelly Cascaes Saldanha' AS nome, 
           CONCAT('geovana.saldanha',  '@icen.ufpa.com.br') AS email,
           '20221114002' AS matricula
) AS tmp
WHERE NOT EXISTS (
    SELECT 1 FROM Alunos WHERE matricula = '20221114002'
) LIMIT 1;

-- 4. Verifique os resultados
SELECT * FROM Alunos WHERE matricula IN ('20221114004', '20221114002');