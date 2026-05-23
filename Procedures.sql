DELIMITER //

CREATE PROCEDURE sp_abrir_sessao(
    IN p_id_cliente INT,
    IN p_id_maquina INT,
    OUT p_id_sessao INT
)
BEGIN 
    DECLARE v_status_pc VARCHAR (15);

    -- Handler para dar ROLLBACK em caso de qualquer erro SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
         ROLLBACK;
         RESIGNAL;
    END;

    -- Iniciar a transação antes para garantir atomicidade e evitar concorrência
    START TRANSACTION;

    -- O FOR UPDATE bloqueia o registro até o COMMIT/ROLLBACK
    SELECT STATUS INTO v_status_pc
    FROM COMPUTADOR
    WHERE ID_MAQUINA = p_id_maquina
    FOR UPDATE;

    IF v_status_pc != 'DISPONÍVEL' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Este computador não está disponível no momento.';
    ELSE
        INSERT INTO SESSAO (INICIO_SESSAO, STATUS, ID_CLIENTE, ID_MAQUINA)
        VALUES (NOW(), 'aberta', p_id_cliente, p_id_maquina);

        SET p_id_sessao = LAST_INSERT_ID();

        UPDATE COMPUTADOR
        SET STATUS = 'OCUPADO'
        WHERE ID_MAQUINA = p_id_maquina;

        COMMIT;
    END IF;
END //
DELIMITER ;


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

    START TRANSACTION;

    -- Bloqueia a sessão para edição
    SELECT ID_MAQUINA, INICIO_SESSAO INTO v_id_maquina, v_inicio
    FROM SESSAO  
    WHERE ID_SESSAO = p_id_sessao AND STATUS = 'aberta'
    FOR UPDATE;

    -- Se não achar uma sessão aberta com esse ID
    IF v_id_maquina IS NULL THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Sessão não encontrada ou já encerrada.';
    ELSE
        SELECT PRECO_HORA INTO v_preco_hora
        FROM COMPUTADOR
        WHERE ID_MAQUINA = v_id_maquina;

        -- Calcula o tempo e o valor proporcional
        SET v_horas_decorridas = TIMESTAMPDIFF(SECOND, v_inicio, NOW()) / 3600.0;
        SET v_valor_total = v_horas_decorridas * v_preco_hora;

        UPDATE SESSAO
        SET FIM_SESSAO = NOW(),
            VALOR_TOTAL = ROUND(v_valor_total, 2),
            STATUS = 'finalizada'
        WHERE ID_SESSAO = p_id_sessao;

        UPDATE COMPUTADOR
        SET STATUS = 'DISPONÍVEL' -- Ajustado para bater com o padrão com acento se necessário
        WHERE ID_MAQUINA = v_id_maquina;

        COMMIT;
    END IF;
END //
DELIMITER ;


DELIMITER //

CREATE PROCEDURE sp_registrar_consumo(
    IN p_id_sessao INT,
    IN p_id_produto INT,
    IN p_quantidade INT
)
BEGIN
    DECLARE v_estoque_atual INT;
    DECLARE v_preco_produto DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Captura o estoque e preço travando a linha do produto para evitar venda duplicada sem estoque
    SELECT ESTOQUE, PRECO INTO v_estoque_atual, v_preco_produto 
    FROM PRODUTO 
    WHERE ID_PRODUTO = p_id_produto
    FOR UPDATE;

    -- Validação de Regra de Negócio
    IF v_estoque_atual < p_quantidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Estoque insuficiente para realizar a venda do produto.';
    ELSE
        SET v_subtotal = v_preco_produto * p_quantidade;

        INSERT INTO CONSUMO (QUANTIDADE, SUBTOTAL, ID_SESSAO, ID_PRODUTO)
        VALUES (p_quantidade, v_subtotal, p_id_sessao, p_id_produto);

        UPDATE PRODUTO 
        SET ESTOQUE = ESTOQUE - p_quantidade 
        WHERE ID_PRODUTO = p_id_produto;
        
        COMMIT;
    END IF;
END //
DELIMITER ;


DELIMITER //

CREATE PROCEDURE sp_inscrever_torneio(
    IN p_id_cliente INT,
    IN p_id_torneio INT
)
BEGIN
    DECLARE v_vagas_maximas INT;
    DECLARE v_inscritos_atuais INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Bloqueia o torneio para evitar que ultrapasse o limite em inscrições simultâneas
    SELECT QUANTIDADE_MAXIMA INTO v_vagas_maximas 
    FROM TORNEIO 
    WHERE ID_TORNEIO = p_id_torneio
    FOR UPDATE;

    -- Contar quantas inscrições confirmadas já existem
    SELECT COUNT(*) INTO v_inscritos_atuais 
    FROM INSCRICAO 
    WHERE ID_TORNEIO = p_id_torneio AND STATUS = 'CONFIRMADA';

    -- Validar limite de vagas
    IF v_inscritos_atuais >= v_vagas_maximas THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: O torneio já atingiu o limite máximo de participantes.';
    ELSE
        INSERT INTO INSCRICAO (ID_CLIENTE, ID_TORNEIO)
        VALUES (p_id_cliente, p_id_torneio);
        
        COMMIT;
    END IF;
END //
DELIMITER ;


DELIMITER //

CREATE FUNCTION fn_tempo_sessao(p_id_sessao INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_inicio DATETIME;
    DECLARE v_fim DATETIME;
    DECLARE v_minutos_totais INT;
    DECLARE v_horas INT;
    DECLARE v_minutos_restantes INT;
    
    SELECT INICIO_SESSAO, COALESCE(FIM_SESSAO, NOW()) 
    INTO v_inicio, v_fim
    FROM SESSAO 
    WHERE ID_SESSAO = p_id_sessao;
    
    SET v_minutos_totais = TIMESTAMPDIFF(MINUTE, v_inicio, v_fim);
    SET v_horas = FLOOR(v_minutos_totais / 60);
    SET v_minutos_restantes = v_minutos_totais % 60;
    
    RETURN CONCAT(v_horas, 'h ', v_minutos_restantes, 'min');
END //
DELIMITER ;


DELIMITER //

CREATE FUNCTION fn_faturamento_dia(p_data DATE)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    -- Corrigido: Removida a palavra "TOTAL" que quebrava a sintaxe
    DECLARE v_faturamento DECIMAL(10,2);
    
    SELECT SUM(VALOR_TOTAL) INTO v_faturamento
    FROM SESSAO
    WHERE DATE(FIM_SESSAO) = p_data AND STATUS = 'finalizada';
    
    RETURN COALESCE(v_faturamento, 0.00);
END //
DELIMITER ;


DELIMITER //

CREATE FUNCTION fn_categoria_cliente(p_id_cliente INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_pontos INT;
    DECLARE v_categoria VARCHAR(20);
    
    SELECT SALDO_PONTOS INTO v_pontos 
    FROM CLIENTE 
    WHERE ID_CLIENTE = p_id_cliente;
    
    IF v_pontos >= 300 THEN
        SET v_categoria = 'Ouro';
    ELSEIF v_pontos >= 100 THEN
        SET v_categoria = 'Prata';
    ELSE
        SET v_categoria = 'Bronze';
    END IF;
    
    RETURN v_categoria;
END //
DELIMITER ;
