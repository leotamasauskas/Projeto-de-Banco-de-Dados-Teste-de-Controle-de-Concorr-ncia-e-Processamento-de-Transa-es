-- 1. VERIFICAÇÃO E PREPARAÇÃO DAS TABELAS

-- Verificar se a coluna resposta_correta já existe (e remover se necessário)
SET @dbname = DATABASE();
SET @tablename = 'Tentativas';
SET @columnname = 'resposta_correta';
SET @preparedStatement = (SELECT IF(
  EXISTS(
    SELECT * FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME = @tablename
    AND COLUMN_NAME = @columnname
  ),
  'SELECT 1', -- Coluna já existe, não faz nada
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' TEXT')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Modificar a coluna resposta para permitir NULL
ALTER TABLE Tentativas MODIFY COLUMN resposta TEXT NULL;

-- Atualizar o enum de status se necessário
ALTER TABLE Tentativas MODIFY COLUMN status ENUM('CORRETA', 'PARCIALMENTE_CORRETA', 'INCORRETA', 'PENDENTE') DEFAULT 'PENDENTE';

-- 2. INSERÇÃO DAS RESPOSTAS CORRETAS (VERSÃO CORRIGIDA)

START TRANSACTION;

-- Inserir respostas modelo com todos os campos obrigatórios
INSERT INTO Tentativas (equipe_id, questao_id, resposta, resposta_correta, status)
VALUES
(1, 1, 'Resposta modelo Q1', 'Transação ACID passa por: Active → Partially Committed → Committed (ou Failed → Aborted se erro)', 'CORRETA'),
(1, 2, 'Resposta modelo Q2', 'Escalonamento serial executa em sequência; equivalente serial permite concorrência com resultado serializável', 'CORRETA'),
(1, 3, 'Resposta modelo Q3', 'Conflitos comuns: Lost Update, Dirty Read, Unrepeatable Read. Solução: bloqueios adequados', 'CORRETA'),
(1, 4, 'Resposta modelo Q4', 'Escalonamento não-serializável quando há ciclos no grafo de precedência', 'CORRETA'),
(1, 5, 'Resposta modelo Q5', 'Bloqueio X (exclusivo): acesso exclusivo. Bloqueio S (compartilhado): múltiplas leituras', 'CORRETA'),
(1, 6, 'Resposta modelo Q6', 'Conversão S→X pode causar deadlock. Usar quando necessário escrever após ler', 'CORRETA'),
(1, 7, 'Resposta modelo Q7', '2PL: fase de crescimento (adquire bloqueios) e encolhimento (libera bloqueios). Garante serializabilidade', 'CORRETA'),
(1, 8, 'Resposta modelo Q8', 'Deadlock: espera circular. Starvation: transação indefinidamente adiada. Soluções: timeout, detecção de ciclos', 'CORRETA'),
(1, 9, 'Resposta modelo Q9', 'Protocolos timestamp: transação mais antiga tem prioridade. Se violada, aborta a mais nova', 'CORRETA'),
(1, 10, 'Resposta modelo Q10', 'MVCC: leituras sem bloqueios com múltiplas versões. Vantagem: concorrência; Desvantagem: overhead', 'CORRETA')
ON DUPLICATE KEY UPDATE 
    resposta_correta = VALUES(resposta_correta),
    status = VALUES(status);

COMMIT;

-- 3. ATUALIZAÇÃO PARA REMOVER RESPOSTAS MODELO (OPCIONAL)
UPDATE Tentativas 
SET resposta = NULL 
WHERE resposta LIKE 'Resposta modelo Q%' AND equipe_id = 1;

-- 4. CONSULTAS DE VERIFICAÇÃO

-- Verificar respostas corretas cadastradas
SELECT questao_id, resposta_correta, status 
FROM Tentativas 
WHERE equipe_id = 1 
ORDER BY questao_id;

-- Verificar estrutura da tabela
DESCRIBE Tentativas;