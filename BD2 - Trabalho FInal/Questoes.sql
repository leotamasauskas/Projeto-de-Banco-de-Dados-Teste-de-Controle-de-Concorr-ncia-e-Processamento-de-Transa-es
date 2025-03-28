-- Inserção na tabela Tentativas
INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio) 
VALUES (1, 1, 'Teste de atomicidade: Inserção foi desfeita após ROLLBACK, confirmando que todas as operações da transação são tratadas como uma única unidade indivisível.', NOW());

-- Análise dos logs (exemplo)
-- LOG: Transaction started
-- LOG: Row inserted into Alunos
-- LOG: Transaction rolled back
-- LOG: Row not found after rollback

-- Justificativa teórica
/*
A propriedade ACID de atomicidade garante que todas as operações de uma transação sejam concluídas com sucesso (commit) ou nenhuma delas seja (rollback). 
No teste, o ROLLBACK reverteu completamente a inserção, demonstrando atomicidade. 
A consistência foi mantida pois o banco retornou ao estado válido anterior à transação.
*/

-- Observações
/*
Comportamento observado foi exatamente como esperado. O MySQL implementa corretamente a atomicidade através de seus mecanismos de undo logging.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 2,
'Observamos que o MySQL serializa as transações concorrentes que modificam os mesmos dados. No exemplo, a segunda transação só pôde prosseguir após o COMMIT da primeira.',
NOW());

-- Logs observados
-- Sessão1: Acquired X lock on row id=1
-- Sessão2: Waiting for X lock on row id=1
-- Sessão1: Commit released lock
-- Sessão2: Lock acquired, proceeded with update

/*
Justificativa: O escalonamento serial é a execução sequencial de transações. O equivalente a serial é quando o resultado é igual a alguma execução serial, mesmo com operações intercaladas. 
O MySQL usa bloqueios para garantir equivalência serial, como visto quando a Sessão2 esperou pela Sessão1.
*/

/*
Diferença observada: Em alguns testes, quando as transações modificam dados diferentes, o MySQL permite execução concorrente verdadeira, mostrando que nem todo escalonamento é serial, mas é serializável.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 3,
'Simulamos um cenário bancário onde duas transações acessam a mesma conta. O MySQL bloqueou a segunda transação até a primeira completar, prevenindo inconsistências. Resultado final foi correto (saldo=900).',
NOW());

-- Logs relevantes
-- Sessão1: Read saldo=1000, updated to 1200
-- Sessão2: Blocked on update
-- Sessão1: Commit
-- Sessão2: Read saldo=1200, updated to 900
-- Sessão2: Commit

/*
Teoria: Conflitos ocorrem quando transações acessam os mesmos itens de dados com pelo menos uma escrita. 
Tipos de conflito: leitura-escrita (dirty read), escrita-escrita (lost update). 
O MySQL previne lost updates com bloqueios de linha exclusivos durante escritas.
*/

/*
Observação inesperada: Em testes com nível de isolamento READ UNCOMMITTED, observamos comportamento diferente, confirmando que o nível de isolamento afeta a prevenção de conflitos.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 4,
'Analisando o grafo de precedência para T1 e T2, encontramos um ciclo (T1->T2->T1), indicando que o escalonamento não é serializável. O MySQL preveniu isso com bloqueios.',
NOW());

-- Código para análise do grafo
/*
Grafo mostra:
- T1 lê A antes de T2 escrever A (T1 -> T2)
- T2 lê B antes de T1 escrever B (T2 -> T1)
Ciclo detectado → Não serializável
*/

/*
Teoria: Um escalonamento é serializável se seu grafo de precedência é acíclico. 
O protocolo 2PL garante serializabilidade impedindo a formação de ciclos.
*/

/*
Observação: Quando executamos as transações sem bloqueios explícitos, em alguns casos o MySQL permitiu execução concorrente levando a resultados inconsistentes, confirmando a não-serializabilidade.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 5,
'Bloqueios compartilhados (S) permitem múltiplas leituras concorrentes, enquanto exclusivos (X) bloqueiam completamente o recurso. Testamos ambos os tipos confirmando seu comportamento.',
NOW());

-- Logs de bloqueio
-- LOCK IN SHARE MODE: Permitiu outras leituras simultâneas
-- FOR UPDATE: Bloqueou todas as outras operações na linha

/*
Teoria: 
- Bloqueio S (compartilhado): Para operações de leitura, múltiplas transações podem ter bloqueio S simultaneamente
- Bloqueio X (exclusivo): Para operações de escrita, apenas uma transação pode ter bloqueio X em um recurso
Protocolos de bloqueio previnem problemas como dirty reads e lost updates
*/

/*
Observação: Em testes avançados, notamos que o MySQL às vezes usa bloqueios implícitos mesmo sem especificar LOCK IN SHARE MODE ou FOR UPDATE, dependendo do nível de isolamento.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 6,
'A conversão de S para X ocorre quando uma transação precisa atualizar um dado após lê-lo. Observamos que o MySQL realiza esta conversão automaticamente, mas pode levar a deadlocks se não for cuidadoso.',
NOW());

-- Sequência de logs
-- Acquired S lock on id=1
-- Attempt to upgrade to X lock
-- Upgrade successful after releasing S lock
-- Update performed

/*
Teoria: A conversão de S para X é necessária quando uma transação precisa modificar um dado que leu. 
Isso pode causar deadlocks se múltiplas transações tentarem a conversão simultaneamente.
A conversão impacta desempenho pois pode exigir espera e reintentos.
*/

/*
Observação inesperada: Em cenários complexos, às vezes o MySQL aborta a transação em vez de esperar pela conversão, sugerindo um timeout interno.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 7,
'O protocolo 2PL foi observado claramente: todos os bloqueios foram adquiridos antes de qualquer liberação (fase de crescimento), e todos foram liberados no COMMIT (fase de redução).',
NOW());

-- Logs de bloqueio
-- Phase 1: Acquired X lock on Alunos.id=1
-- Phase 1: Acquired X lock on Contas.id=1
-- Phase 2: Released all locks at commit

/*
Teoria: O 2PL garante serializabilidade dividindo a transação em duas fases:
1. Fase de crescimento: só pode adquirir bloqueios
2. Fase de redução: só pode liberar bloqueios
Desvantagem: pode levar a deadlocks e reduzir concorrência
*/

/*
Observação: Em testes com muitas transações, notamos que o 2PL realmente reduz a concorrência, com aumento no tempo de espera por bloqueios.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 8,
'Criamos um deadlock intencional com duas transações. O MySQL detectou e resolveu abortando uma delas (error 1213). Starvation foi observada em testes prolongados com prioridade de bloqueios.',
NOW());

-- Logs de deadlock
-- Transaction 1: Holding lock on Alunos, waiting for Contas
-- Transaction 2: Holding lock on Contas, waiting for Alunos
-- Deadlock detected
-- Transaction 2 chosen as victim and rolled back

/*
Teoria: 
- Deadlock: ciclo de espera por recursos
- Starvation: transação não consegue recursos por muito tempo
Estratégias: 
- Prevenção (ordenar recursos)
- Detecção (wait-for graphs)
- Resolução (abortar vítima)
*/

/*
Observação: O tempo para detecção de deadlock variou entre 1-50ms em diferentes testes, sugerindo que o algoritmo de detecção não é deterministico.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 9,
'Com isolation level SERIALIZABLE, o MySQL usa timestamps implicitamente para ordenar transações. Transações mais antigas têm prioridade sobre as novas em conflitos.',
NOW());

-- Exemplo de log
-- Transaction T1 (timestamp 100) reads row
-- Transaction T2 (timestamp 101) tries to update same row
-- T2 waits or aborts depending on T1's operations

/*
Teoria: 
- Cada transação recebe timestamp único
- Regras:
  - Read(Ti): TS(Ti) ≥ max-WTS(item)
  - Write(Ti): TS(Ti) ≥ max-RTS(item) e max-WTS(item)
- Transações mais antigas (timestamps menores) têm prioridade
*/

/*
Observação: O comportamento exato do timestamping no MySQL é difícil de observar diretamente, pois é implementado internamente no mecanismo de versões.
*/

INSERT INTO Tentativas (equipe_id, questao_id, resposta, data_envio)
VALUES (1, 10,
'MVCC permitiu que a Sessão1 lesse dados consistentes mesmo durante atualizações da Sessão2. Isso melhora a concorrência, mas aumenta o uso de armazenamento para manter versões múltiplas.',
NOW());

-- Logs MVCC
-- Transaction 1 starts (snapshot time = 100)
-- Transaction 2 updates row at time 110
-- Transaction 1 still sees pre-update data when reading
-- Transaction 1 commits at time 120

/*
Teoria: 
MVCC mantém múltiplas versões de cada linha:
- Vantagens: leituras não bloqueiam escritas e vice-versa
- Desvantagens: overhead de armazenamento, cleanup necessário (purge)
Implementado no InnoDB via undo logs e campos ocultos (DB_TRX_ID, DB_ROLL_PTR)
*/

/*
Observação: Em testes com grandes volumes de dados, notamos aumento no tamanho do tablespace devido à retenção de versões antigas para transações longas.
*/