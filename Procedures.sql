DELIMITER //

CREATE PROCEDURE sp_abrir_sessao(
  IN p_id_cliente INT,
  IN p_id_maquina INT,
  OUT p_id_sessao INT
  )

BEGIN 
      DECLARE v_status_pc VARCHAR (15);

DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
     ROLLBACK;
     RESIGNAL;
END;

SELECT STATUS INTO v_status_pc
FROM COMPUTADOR
WHERE ID_MAQUINA = p_id_maquina;

IF v_status_pc != 'DISPONÍVEL' THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Erro: Este computador não está disponível no momento.';
ELSE

START TRANSACTION;

INSERT INTO SESSAO (INICIO_SESSAO, STATUS, ID_CLIENTE, ID_MAQUINA)
VALUES (NOW(), 'aberta', p_id_cliente, p_id_maquina);

SET p_id_sessao = LAST_INSERT_ID();

UPDATE COMPUTADOR
SET STATUS = 'OCUPADO'
WHERE ID_MAQUINA = p_id_maquina;

COMMIT;
END IF;

DELIMITER;

DELIMITER //

CREATE PROCEDURE sp_fechar_sessao(
  IN p_id_sessao INT
  )

BEGIN
     DECLARE v_id_maquina INT;
     DECLARE v_inicio DATETIME;
     DECLARE v_preco_hora DECIMAL (10,2);
     DECLARE v_horas_decorridas DECIMAL (10,4);
     DECLARE v_valor_total DECIMAL (10,2);

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
      ROLLBACK;
      RESIGNAL;
END;

SELECT ID_MAQUINA, INICIO_SESSAO INTO v_id_maquina, v_inicio
FROM SESSAO  
WHERE ID_SESSAO = p_id_sessao AND STATUS = 'aberta';

IF v_id_maquina IS NULL THEN 
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Erro: Sessão não encontrada ou já encerrada.';
ELSE
    SELECT PRECO_HORA INTO v_preco_hora
    FROM COMPUTADOR
    WHERE ID_MAQUINA = v_id_maquina;

SET v_horas_decorridas = TIMESTAMPDIFF(SECOND, v_inicio, NOW()) / 3600.0;
SET v_valor_total = v_horas_decorridas * v_preco_hora;

START TRANSACTION;
UPDATE SESSAO
SET FIM_SESSAO = NOW(),
    VALOR_TOTAL = ROUND(v_valor_total, 2),
    STATUS = 'finalizada'
WHERE ID_SESSAO = p_id_sessao;

UPDATE COMPUTADOR
SET STATUS = 'DISPONIVEL'
WHERE ID_MAQUINA = v_id_maquina;

COMMIT;
END IF;

// 

MITER;






































