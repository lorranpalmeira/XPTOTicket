CREATE OR REPLACE PACKAGE BODY consinco_itf
/* Formatted on 19/06/2017 09:57:22 (QP5 v5.262) */
AS
    -- Purpose: Interface de operaçoes financeiras UniverseBR -> Consinco
    -- MODIFICATION HISTORY
    -- Person      Date        Comments
    -- ---------   ----------  -------------------------------------------
    -- MMoreira     30/04/2015  Criação
    -- Pezetta      21/03/2016  Ajuste de historicos e alteracao para enviar movimentos abertos de caixa.
    -- Pezetta      01/04/2016  Ajuste no tamanho dos campos para gravar na tabela consinco.ctx_lanctoimportacao

    --- Variaveis

    mcount   NUMBER;


    PROCEDURE consinco_sage_bancario_del (ptiporegistro    VARCHAR2,
                                          pmvc_contador    NUMBER)
    IS
        mmsn_error   VARCHAR2 (300);
    BEGIN
        --Envio o estorno dos lancamentos excluidos no UniverseBR

        BEGIN
            FOR mvc_estorno
                IN (SELECT ctl.*
                      FROM consinco_fi_intctacor_ctl ctl
                     WHERE     mvc_contador = pmvc_contador
                           AND tiporegistro = ptiporegistro)
            LOOP
                BEGIN
                    BEGIN
                        INSERT INTO consinco.fi_integractacor (tiporegistro,
                                                               origem,
                                                               chaveorigem,
                                                               nroempresa,
                                                               dtalancamento,
                                                               codconta,
                                                               creditodebito,
                                                               tipooperacao,
                                                               nrodocumento,
                                                               historico,
                                                               vlrlancamento,
                                                               justcancel,
                                                               situacao,
                                                               dtaintegrado,
                                                               seqlancto,
                                                               nroprocesso,
                                                               seqintctacor,
                                                               usualteracao)
                            VALUES (
                                       'C',                    -- TIPOREGISTRO
                                       'XRT',                        -- ORIGEM
                                       mvc_estorno.mvc_contador, --CHAVEORIGEM
                                       mvc_estorno.nroempresa,   -- NROEMPRESA
                                       mvc_estorno.dtalancamento, -- DTALANCAMENTO
                                          mvc_estorno.ban_codigo
                                       || '#'
                                       || mvc_estorno.age_codigo
                                       || '#'
                                       || mvc_estorno.cnt_codigo,  -- CODCONTA
                                       mvc_estorno.creditodebito, -- CREDITODEBITO,
                                       mvc_estorno.tdp_codigo, -- TIPOOPERACAO
                                       mvc_estorno.nrodocumento, -- NRODOCUMENTO
                                       mvc_estorno.historico,     -- HISTORICO
                                       ABS (mvc_estorno.vlrlancamento), -- VLRLANCAMENTO
                                       NULL,                      --JUSTCANCEL
                                       'P',                        -- SITUACAO
                                       NULL,                    --DTAINTEGRADO
                                       NULL,                       --SEQLANCTO
                                       NULL,                     --NROPROCESSO
                                       NULL,                   -- SEQINTCTACOR
                                       'XRT'                    --USUALTERACAO
                                            );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar retorno de cta corrente na tabela da consinco fi_integractacor@consinco'
                                               || mmsn_error,
                                                  'mvc_contador = '
                                               || pmvc_contador,
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;
                END;

                COMMIT;
            END LOOP;
        END;
    END;

    -- fim da procedure consinco_sage_bancario_del

    PROCEDURE consinco_sage_bancario_updt (ptiporegistro    VARCHAR2,
                                           pmvc_contador    NUMBER)
    IS
        --Variaveis
        mnroempresa         mov_compromisso.pfj_codigo%TYPE;
        mnroempresamae      mov_compromisso.pfj_codigo%TYPE;
        mseqctacordebito    consinco_fi_intctacor_ctl.seqctacordebito%TYPE;
        mseqctacorcredito   consinco_fi_intctacor_ctl.seqctacorcredito%TYPE;
        mcod_fornec_pgt     conta_corrente.cod_fornec_pgt%TYPE;
        mcodoperacao        consinco_fi_intctacor_ctl.codoperacao%TYPE;
        mhistorico          mov_compromisso.historico%TYPE;
        mdoc_origem         mov_compromisso.doc_origem%TYPE;
        mmsn_error          VARCHAR2 (300);
        mcreditodebito      VARCHAR2 (1);
    --Reenvio dos lancamentos que foram alterados no UniverseBR
    BEGIN
        FOR mvc_alteracao
            IN (SELECT mvc.data_caixa,
                       mvc.pfj_codigo,
                       (  NVL (DECODE (mmi_ent_sai,  'E', 1,  'S', -1), 1)
                        * (mvc.valor * mvc.taxa_conversao_corr))
                           valor, -- VIDAL 30012017 - Acrescentada taxa de conversão de moedas
                       mvc.alterado_em,
                       ctl.seqintctacor,
                       nro_linha,
                       mvb.ban_codigo,
                       mvb.age_codigo,
                       mvb.cnt_codigo,
                       mvb.tdp_codigo,
                       mvb.mvb_contador,
                       mvc.mvc_contador,
                       mvc.mmi_ent_sai,
                       mvc.incluido_por,
                       ctl.historico
                  FROM mov_compromisso mvc,
                       consinco_fi_intctacor_ctl ctl,
                       mov_bancario mvb
                 WHERE     ctl.tiporegistro = ptiporegistro
                       AND ctl.mvc_contador = pmvc_contador
                       AND ctl.mvc_contador = mvc.mvc_contador
                       AND mvc.mvb_contador = mvb.mvb_contador)
        LOOP
            BEGIN
                DELETE FROM consinco_fi_intctacor_ctl
                 WHERE mvc_contador = mvc_alteracao.mvc_contador;

                SELECT DISTINCT SUBSTR (historico, 1, 15)
                  INTO mhistorico
                  FROM mov_compromisso
                 WHERE     mvb_contador = mvc_alteracao.mvb_contador
                       AND ROWNUM = 1;

                BEGIN
                    SELECT DISTINCT doc_origem
                      INTO mdoc_origem
                      FROM mov_compromisso
                     WHERE     mvc_contador = mvc_alteracao.mvc_contador
                           AND ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mdoc_origem := NULL;
                END;

                IF UPPER (mvc_alteracao.mmi_ent_sai) = 'E'
                THEN
                    mcreditodebito := 'C';
                ELSE
                    mcreditodebito := 'D';
                END IF;


                BEGIN
                    INSERT INTO consinco_fi_intctacor_ctl (seqintctacor,
                                                           tiporegistro,
                                                           nroempresamae,
                                                           nroempresa,
                                                           dtalancamento,
                                                           seqctacordebito,
                                                           seqctacorcredito,
                                                           codoperacao,
                                                           historico,
                                                           vlrlancamento,
                                                           nrodocumento,
                                                           seriedocumento,
                                                           reflancamento,
                                                           codespecie,
                                                           seqlancto1,
                                                           seqlancto2,
                                                           origem,
                                                           nroprocesso,
                                                           usualteracao,
                                                           tipoctacordb,
                                                           tipocodpessoadb,
                                                           codpessoadb,
                                                           tipoctacorcr,
                                                           tipocodpessoacr,
                                                           codpessoacr,
                                                           mvc_contador,
                                                           estorno_flag,
                                                           alterado_em,
                                                           alterado_por,
                                                           nro_linha,
                                                           mvb_contador,
                                                           tdp_codigo,
                                                           linkerpext,
                                                           ban_codigo,
                                                           age_codigo,
                                                           cnt_codigo,
                                                           creditodebito)
                        VALUES (
                                   NULL,                       -- SEQINTTITULO
                                   'I',                        -- TIPOREGISTRO
                                   mnroempresamae,            -- nroempresamae
                                   mvc_alteracao.pfj_codigo, --mnroempresa,                  -- NROEMPRESA --VIDAL 30082017 ACRESCENTADO O PFJ_CODIGO
                                   mvc_alteracao.data_caixa,  -- DTALANCAMENTO
                                   mseqctacordebito,        -- seqctacordebito
                                   mseqctacorcredito,      -- seqctacorcredito
                                   mcodoperacao,                -- CODOPERACAO
                                   SUBSTR (mvc_alteracao.historico, 1, 100), -- HISTORICO
                                   ABS (mvc_alteracao.valor), -- VLRLANCAMENTO
                                   NVL (
                                       SUBSTR (mdoc_origem,
                                               5,
                                               LENGTH (mdoc_origem)),
                                       mvc_alteracao.mvb_contador), -- NRODOCUMENTO
                                   NULL, -- mvc_alteracao.mvb_contador, -- SERIEDOCUMENTO
                                   ' ',                       -- REFLANCAMENTO
                                   'CTACOR',                     -- CODESPECIE
                                   NULL,                         -- SEQLANCTO1
                                   NULL,                         -- SEQLANCTO2
                                   'XRT',                            -- ORIGEM
                                   NULL,                        -- NROPROCESSO
                                   'SAGE_XRT',                 -- USUALTERACAO
                                   'E',                        -- TIPOCTACORDB
                                   '1',                     -- TIPOCODPESSOADB
                                   NULL,                        -- CODPESSOADB
                                   'E',                        -- TIPOCTACORCR
                                   '1',                     -- TIPOCODPESSOACR
                                   NULL,                        -- CODPESSOACR
                                   mvc_alteracao.mvb_contador,
                                   'N',
                                   mvc_alteracao.alterado_em,
                                   mvc_alteracao.incluido_por,
                                   consinco_seq.NEXTVAL,
                                   mvc_alteracao.mvb_contador,
                                   mvc_alteracao.tdp_codigo,
                                   mvc_alteracao.mvb_contador,
                                   mvc_alteracao.ban_codigo,
                                   mvc_alteracao.age_codigo,
                                   mvc_alteracao.cnt_codigo,
                                   mcreditodebito);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        mmsn_error := SUBSTR (SQLERRM, 1, 200);

                        BEGIN
                            INSERT INTO consinco_sage_itf_log
                                VALUES (
                                              'Erro para gravar dados de cta corrente na tabela de controle consinco_fi_intctacor_ctl '
                                           || mmsn_error,
                                              'mvb_contador = '
                                           || mvc_alteracao.mvc_contador,
                                           SYSDATE);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                END;

                BEGIN
                    INSERT INTO consinco.fi_integractacor (tiporegistro,
                                                           origem,
                                                           chaveorigem,
                                                           nroempresa,
                                                           dtalancamento,
                                                           codconta,
                                                           creditodebito,
                                                           tipooperacao,
                                                           nrodocumento,
                                                           historico,
                                                           vlrlancamento,
                                                           justcancel,
                                                           situacao,
                                                           dtaintegrado,
                                                           seqlancto,
                                                           nroprocesso,
                                                           seqintctacor,
                                                           usualteracao)
                        VALUES (
                                   'I',                        -- TIPOREGISTRO
                                   'XRT',                            -- ORIGEM
                                   mvc_alteracao.mvc_contador,   --CHAVEORIGEM
                                   mvc_alteracao.pfj_codigo,     -- NROEMPRESA
                                   mvc_alteracao.data_caixa,  -- DTALANCAMENTO
                                      mvc_alteracao.ban_codigo
                                   || '#'
                                   || mvc_alteracao.age_codigo
                                   || '#'
                                   || mvc_alteracao.cnt_codigo,
                                   -- CODCONTA
                                   mcreditodebito,           -- CREDITODEBITO,
                                   mvc_alteracao.tdp_codigo,   -- TIPOOPERACAO
                                   NVL (
                                       SUBSTR (mdoc_origem,
                                               5,
                                               LENGTH (mdoc_origem)),
                                       mvc_alteracao.mvb_contador), -- NRODOCUMENTO
                                   mvc_alteracao.historico,       -- HISTORICO
                                   ABS (mvc_alteracao.valor), -- VLRLANCAMENTO
                                   NULL,                          --JUSTCANCEL
                                   'P',                            -- SITUACAO
                                   NULL,                        --DTAINTEGRADO
                                   NULL,                           --SEQLANCTO
                                   NULL,                         --NROPROCESSO
                                   NULL,                       -- SEQINTCTACOR
                                   'XRT'                       -- USUALTERACAO
                                        );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        mmsn_error := SUBSTR (SQLERRM, 1, 200);

                        BEGIN
                            INSERT INTO consinco_sage_itf_log
                                VALUES (
                                              'Erro para gravar dados de cta corrente na tabela da fi_integractacor@consinco '
                                           || mmsn_error,
                                              'mvb_contador = '
                                           || mvc_alteracao.mvc_contador,
                                           SYSDATE);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                END;
            END;
        END LOOP;

        COMMIT;
    END;

    -- Fim da procedure consinco_sage_bancario_updt

    PROCEDURE consinco_sage_bancario_insert
    IS
        --Variaveis
        mdata_controle   DATE;
        mhistorico       mov_compromisso.historico%TYPE;
        mdoc_origem      mov_compromisso.doc_origem%TYPE;
        malterado_em     mov_compromisso.alterado_em%TYPE;
        mmsn_error       VARCHAR2 (300) := ' ';
        mcreditodebito   VARCHAR2 (1);
        mvalor           mov_compromisso.valor%TYPE;
    BEGIN
        SELECT MAX (alterado_em) INTO mdata_controle FROM consinco_tesouraria;

        IF mdata_controle IS NULL
        THEN
            mdata_controle := SYSDATE - 3;
        END IF;

        DELETE FROM consinco_sage_itf_log
         WHERE msn_error LIKE '%CONSINCO_TDP_CAIXA%';

         commit;

        FOR l_cxa
            IN (SELECT mvb.age_codigo,
                       mvb.ban_codigo,
                       mvb.cnt_codigo,
                       mvb.data_caixa,
                       mvb.data_competencia,
                       mvb.data_pagamento,
                       mvb.doc_pagador,
                       mvb.pfj_codigo,
                       mvb.tdp_codigo,
                       mvb.temperatura,
                       (  NVL (DECODE (mvc.mmi_ent_sai,  'E', 1,  'S', -1),
                               1)
                        * (mvc.valor + NVL (ajuste.valor_do_ajuste, 0)))
                           valor,
                       mvb.mvb_contador,
                       mvc.mvc_contador,
                       mvc.mmi_ent_sai,
                       mvc.doc_origem,
                       mvc.historico,
                       mvc.origem_processo,
                       mvc.taxa_conversao_corr,
                       tdp.consinco_tdp_caixa,
                       ajuste.eh_come_cotas
                  FROM mov_compromisso mvc
                       INNER JOIN mov_bancario mvb
                           ON mvc.mvb_contador = mvb.mvb_contador
                       LEFT JOIN consinco_tdp_caixa tdp
                           ON mvb.tdp_codigo = tdp.consinco_tdp_caixa
                       LEFT JOIN
                       (SELECT p.mvc_contador mvc_da_parcela_origem,
                               c.valor valor_do_ajuste, p.eh_come_cotas
                          FROM mov_compromisso c, parcela p
                         WHERE     c.par_contador IS NOT NULL
                               AND c.par_contador = p.par_contador) ajuste
                           ON mvc.mvc_contador = ajuste.mvc_da_parcela_origem
                 WHERE     mvc.origem_sistema = 'GEF'
                       --AND alterado_em > mdata_controle
                       AND mvc.alterado_em >
                               TO_DATE ('01/06/2017', 'dd/mm/rrrr')
                       AND mvc.temperatura = -1
                       /*IGNORAR MOVIMENTOS DE AJUSTES*/
                       AND mvc.par_contador IS NULL
                       AND NOT EXISTS
                               (SELECT par_tipo
                                  FROM parcela par
                                 WHERE     par.mvc_contador =
                                               mvc.mvc_contador
                                       AND par.par_tipo LIKE 'IR_%'
                                       AND EXISTS
                                               (SELECT mdo_tipo
                                                  FROM operacao o
                                                 WHERE     o.opr_numero =
                                                               par.opr_numero
                                                       AND o.mdo_tipo = 'A'))
                       AND NOT EXISTS
                               (SELECT con.mvc_contador
                                  FROM consinco_tesouraria con
                                 WHERE     con.mvc_contador =
                                               mvc.mvc_contador
                                       AND alterado_em >= mvc.alterado_em))
        LOOP
            -- Insere o log
            IF (l_cxa.consinco_tdp_caixa IS NULL)
            THEN
                MERGE INTO consinco_sage_itf_log a
                 USING DUAL
                    ON (    DUAL.dummy IS NOT NULL
                        AND a.origem_pk = l_cxa.mvc_contador)
                WHEN NOT MATCHED
                THEN
                    INSERT (msn_error, origem_pk, log_data)
                    VALUES (
                                  'Instrumento bancário '
                               || l_cxa.tdp_codigo
                               || ' Não cadastrado da tabela de depara CONSINCO_TDP_CAIXA. '
                               || 'Favor realizar o cadastro e aguardar a próxima execução da interface.',
                               l_cxa.mvc_contador,
                               SYSDATE);
            ELSE
                SELECT COUNT (1)
                  INTO mcount
                  FROM parcela
                 WHERE mvc_contador_par = l_cxa.mvc_contador;

                IF     NVL (l_cxa.historico, 'XPTO') LIKE '%JUR%'
                   AND l_cxa.origem_processo = 'APL'
                THEN
                    BEGIN
                     
                               SELECT mvc.valor
                               INTO mvalor
                               FROM mov_compromisso mvc, parcela par
                               WHERE     mvc.mvc_contador = par.mvc_contador
                                     AND mvc.doc_origem = l_cxa.doc_origem
                                     AND par.par_tipo LIKE 'IR_%'
									 AND mvc.data_pagamento = l_cxa.data_pagamento
									 
									 IF par.eh_come_cotas ='S' THEN
										AND PAR.EH_COME_COTAS = 'S'
									 
									 ELSE
										AND PAR.EH_COME_COTAS != 'S'
									 
									 END IF;
                              
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            NULL;
                    END;

                    IF mvalor IS NOT NULL
                    THEN
                        l_cxa.valor := l_cxa.valor - mvalor;
                    END IF;
                END IF;

                --



                IF mcount = 0
                THEN
                    SELECT COUNT (1)
                      INTO mcount
                      FROM parcela
                     WHERE mvc_contador = l_cxa.mvc_contador;
                END IF;

                IF mcount = 0
                THEN
                    BEGIN
                        SELECT DISTINCT historico
                          INTO mhistorico
                          FROM mov_compromisso
                         WHERE     mvb_contador = l_cxa.mvb_contador
                               AND ROWNUM = 1;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mhistorico := NULL;
                    END;
                ELSE
                    BEGIN
                        SELECT    LPAD (o.con_codigo, 15, '0')
                               || '#'
                               || LPAD (o.opr_numero, 5, '0')
                               || '#'
                               || (SELECT LPAD (COUNT (1), 3, '0')
                                     FROM parcela
                                    WHERE     opr_numero = o.opr_numero
                                          AND par_tipo = p.par_tipo
                                          AND par_ent_sai = 'S'
                                          AND valor_pago <> 0)
                               || '/'
                               || (SELECT LPAD (COUNT (1), 3, '0')
                                     FROM parcela
                                    WHERE     opr_numero = o.opr_numero
                                          AND par_tipo = p.par_tipo
                                          AND par_ent_sai = 'S')
                               || '#'
                               || p.par_tipo
                               || '#'
                               || o.mdo_codigo
                               || '#'
                               || SUBSTR (d.historico,
                                          1,
                                          INSTR (d.historico, '-', 1) - 1)
                          INTO mhistorico
                          FROM operacao o, parcela p, mov_compromisso d
                         WHERE     (   p.mvc_contador = l_cxa.mvc_contador
                                    OR p.mvc_contador_par =
                                           l_cxa.mvc_contador)
                               AND o.opr_numero = p.opr_numero
                               AND d.mvc_contador = p.mvc_contador;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mhistorico := NULL;
                    END;
                END IF;

                BEGIN
                    SELECT DISTINCT doc_origem
                      INTO mdoc_origem
                      FROM mov_compromisso
                     WHERE mvb_contador = l_cxa.mvb_contador AND ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mdoc_origem := NULL;
                END;

                SELECT alterado_em
                  INTO malterado_em
                  FROM mov_compromisso
                 WHERE mvc_contador = l_cxa.mvc_contador;

                BEGIN
                    INSERT INTO consinco_tesouraria (age_codigo,
                                                     ban_codigo,
                                                     cnt_codigo,
                                                     conta_contabil,
                                                     data_caixa,
                                                     data_competencia,
                                                     data_pagamento,
                                                     doc_origem,
                                                     doc_pagador,
                                                     emitido_flag,
                                                     historico,
                                                     man_aut,
                                                     origem_pk,
                                                     origem_sistema,
                                                     pfj_codigo,
                                                     tdo_codigo,
                                                     tdp_codigo,
                                                     temperatura,
                                                     valor,
                                                     pfj_origem_destino,
                                                     pfj_emitente,
                                                     mvb_contador,
                                                     mvc_contador,
                                                     alterado_em,
                                                     alterado_por,
                                                     imported_flag,
                                                     nro_linha,
                                                     mmi_ent_sai)
                    VALUES (l_cxa.age_codigo,
                            l_cxa.ban_codigo,
                            l_cxa.cnt_codigo,
                            NULL,
                            l_cxa.data_caixa,
                            l_cxa.data_competencia,
                            l_cxa.data_pagamento,
                            mdoc_origem,
                            l_cxa.doc_pagador,
                            'N',
                            --EMITIDO_FLAG
                            mhistorico,
                            NULL,
                            NULL,
                            NULL,
                            l_cxa.pfj_codigo,
                            NULL,
                            l_cxa.tdp_codigo,
                            l_cxa.temperatura,
                            (l_cxa.valor * l_cxa.taxa_conversao_corr), -- VIDAL 30012017 acrescentado taxa de conversao da moeda
                            NULL,
                            NULL,
                            l_cxa.mvb_contador,
                            l_cxa.mvc_contador,
                            malterado_em,
                            NULL,
                            'N',
                            consinco_seq.NEXTVAL,
                            l_cxa.mmi_ent_sai);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        mmsn_error := SUBSTR (SQLERRM, 1, 200);

                        BEGIN
                            INSERT INTO consinco_sage_itf_log
                                VALUES (
                                              'Erro para gravar dados de cta corrente na tabela intermediaria consinco_tesouraria '
                                           || mmsn_error,
                                              'mvb_contador = '
                                           || l_cxa.mvc_contador,
                                           SYSDATE);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                END;
            END IF;
        END LOOP;

        COMMIT;

        BEGIN
            FOR l_fi_intctacor IN (SELECT *
                                     FROM consinco_tesouraria
                                    WHERE imported_flag = 'N')
            LOOP
                BEGIN
                    mcreditodebito := NULL;


                    IF UPPER (l_fi_intctacor.mmi_ent_sai) = 'E'
                    THEN
                        mcreditodebito := 'C';
                    ELSE
                        mcreditodebito := 'D';
                    END IF;



                    BEGIN
                        INSERT
                          INTO consinco_fi_intctacor_ctl (seqintctacor,
                                                          tiporegistro,
                                                          nroempresamae,
                                                          nroempresa,
                                                          dtalancamento,
                                                          seqctacordebito,
                                                          seqctacorcredito,
                                                          codoperacao,
                                                          historico,
                                                          vlrlancamento,
                                                          nrodocumento,
                                                          seriedocumento,
                                                          reflancamento,
                                                          codespecie,
                                                          seqlancto1,
                                                          seqlancto2,
                                                          origem,
                                                          nroprocesso,
                                                          usualteracao,
                                                          tipoctacordb,
                                                          tipocodpessoadb,
                                                          codpessoadb,
                                                          tipoctacorcr,
                                                          tipocodpessoacr,
                                                          codpessoacr,
                                                          mvc_contador,
                                                          estorno_flag,
                                                          alterado_em,
                                                          alterado_por,
                                                          nro_linha,
                                                          mvb_contador,
                                                          tdp_codigo,
                                                          linkerpext,
                                                          ban_codigo,
                                                          age_codigo,
                                                          cnt_codigo,
                                                          creditodebito)
                            VALUES (
                                       NULL,                   -- SEQINTTITULO
                                       'I',                    -- TIPOREGISTRO
                                       NULL,                  -- nroempresamae
                                       l_fi_intctacor.pfj_codigo, -- NROEMPRESA
                                       l_fi_intctacor.data_caixa, -- DTALANCAMENTO
                                       NULL,                -- seqctacordebito
                                       NULL,               -- seqctacorcredito
                                       NULL,                    -- CODOPERACAO
                                       NVL (l_fi_intctacor.historico,
                                            'Lançamento caixa SAGE XRT'), -- HISTORICO
                                       ABS (l_fi_intctacor.valor), -- VLRLANCAMENTO
                                       NVL (
                                           SUBSTR (
                                               l_fi_intctacor.doc_origem,
                                               5,
                                               LENGTH (
                                                   l_fi_intctacor.doc_origem)),
                                           l_fi_intctacor.mvb_contador), -- NRODOCUMENTO
                                       NULL, -- substr(l_fi_intctacor.mvc_contador, 1, 6), -- SERIEDOCUMENTO
                                       ' ',                   -- REFLANCAMENTO
                                       'CTACOR',                 -- CODESPECIE
                                       NULL,                     -- SEQLANCTO1
                                       NULL,                     -- SEQLANCTO2
                                       'SAGE_XRT',                   -- ORIGEM
                                       NULL,                    -- NROPROCESSO
                                       'XRT',                  -- USUALTERACAO
                                       'E',                    -- TIPOCTACORDB
                                       '1',                 -- TIPOCODPESSOADB
                                       NULL,                    -- CODPESSOADB
                                       'E',                    -- TIPOCTACORCR
                                       '1',                 -- TIPOCODPESSOACR
                                       NULL,                    -- CODPESSOACR
                                       l_fi_intctacor.mvc_contador,
                                       'N',
                                       l_fi_intctacor.alterado_em,
                                       l_fi_intctacor.alterado_por,
                                       consinco_seq.NEXTVAL,
                                       l_fi_intctacor.mvb_contador,
                                       l_fi_intctacor.tdp_codigo,
                                       l_fi_intctacor.mvc_contador,
                                       l_fi_intctacor.ban_codigo,
                                       l_fi_intctacor.age_codigo,
                                       l_fi_intctacor.cnt_codigo,
                                       mcreditodebito);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de cta corrente na tabela de controle consinco_fi_intctacor_ctl '
                                               || mmsn_error,
                                                  'mvb_contador = '
                                               || l_fi_intctacor.mvc_contador,
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;

                    COMMIT;

                    BEGIN
                        INSERT INTO consinco.fi_integractacor (tiporegistro,
                                                               origem,
                                                               chaveorigem,
                                                               nroempresa,
                                                               dtalancamento,
                                                               codconta,
                                                               creditodebito,
                                                               tipooperacao,
                                                               nrodocumento,
                                                               historico,
                                                               vlrlancamento,
                                                               justcancel,
                                                               situacao,
                                                               dtaintegrado,
                                                               seqlancto,
                                                               nroprocesso,
                                                               seqintctacor,
                                                               usualteracao)
                            VALUES (
                                       'I',                    -- TIPOREGISTRO
                                       'XRT',                        -- ORIGEM
                                       l_fi_intctacor.mvc_contador, --CHAVEORIGEM
                                       l_fi_intctacor.pfj_codigo, -- NROEMPRESA
                                       l_fi_intctacor.data_caixa, -- DTALANCAMENTO
                                          l_fi_intctacor.ban_codigo
                                       || '#'
                                       || l_fi_intctacor.age_codigo
                                       || '#'
                                       || l_fi_intctacor.cnt_codigo,
                                       -- CODCONTA
                                       mcreditodebito,       -- CREDITODEBITO,
                                       l_fi_intctacor.tdp_codigo, -- TIPOOPERACAO
                                       NVL (
                                           SUBSTR (
                                               l_fi_intctacor.doc_origem,
                                               5,
                                               LENGTH (
                                                   l_fi_intctacor.doc_origem)),
                                           l_fi_intctacor.mvb_contador), -- NRODOCUMENTO
                                       NVL (l_fi_intctacor.historico,
                                            'Lançamento caixa SAGE XRT'), -- HISTORICO
                                       ABS (l_fi_intctacor.valor), -- VLRLANCAMENTO
                                       NULL,                      --JUSTCANCEL
                                       'P',                        -- SITUACAO
                                       NULL,                    --DTAINTEGRADO
                                       NULL,                       --SEQLANCTO
                                       NULL,                     --NROPROCESSO
                                       NULL,                   -- SEQINTCTACOR
                                       'XRT'                   -- USUALTERACAO
                                            );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de cta corrente na tabela da CONSINCO fi_integractacor@consinco '
                                               || mmsn_error,
                                                  'mvb_contador = '
                                               || l_fi_intctacor.mvc_contador,
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;
                END;

                UPDATE consinco_tesouraria
                   SET imported_flag = 'S'
                 WHERE mvb_contador = l_fi_intctacor.mvb_contador;
            END LOOP;

            COMMIT;

            --envio alteracao
            BEGIN
                FOR mvb_alteracao
                    IN (SELECT mvc.mvc_contador
                          FROM mov_compromisso mvc,
                               consinco_fi_intctacor_ctl ctl
                         WHERE     mvc.mvc_contador = ctl.mvc_contador
                               AND mvc.origem_sistema = 'GEF'
                               AND mvc.temperatura = -1
                               AND mvc.alterado_em >
                                         TO_DATE (TO_CHAR (SYSDATE),
                                                  'DD/MM/RRRR')
                                       - 2
                               AND mvc.alterado_em > ctl.alterado_em
                               AND (     /*alterou valor  alterou data_Caixa*/
                                    ABS (mvc.valor) <>
                                           ABS (ctl.vlrlancamento)
                                    OR mvc.data_caixa <> ctl.dtalancamento))
                LOOP
                    BEGIN
                        consinco_sage_bancario_del (
                            'I',
                            mvb_alteracao.mvc_contador);
                        COMMIT;
                        consinco_sage_bancario_updt (
                            'I',
                            mvb_alteracao.mvc_contador);
                        COMMIT;
                    END;
                END LOOP;

                COMMIT;
            END;

            BEGIN
                FOR mvc_estorno
                    IN (SELECT *
                          FROM consinco_fi_intctacor_ctl ctl
                         WHERE     NOT EXISTS
                                       (SELECT mvc.mvc_contador
                                          FROM mov_compromisso mvc
                                         WHERE mvc.mvc_contador =
                                                   ctl.mvc_contador)
                               AND estorno_flag = 'N')
                LOOP
                    BEGIN
                        consinco_sage_bancario_del ('I',
                                                    mvc_estorno.mvc_contador);
                    END;

                    UPDATE consinco_fi_intctacor_ctl
                       SET estorno_flag = 'S'
                     WHERE     mvc_contador = mvc_estorno.mvc_contador
                           AND tiporegistro = mvc_estorno.tiporegistro;
                END LOOP;

                COMMIT;
            END;
        END;
    END;

    -- Fim da procedure consinco_sage_bancario_insert


    PROCEDURE consinco_efetiva
    IS
        --DECLARE
        icont               INTEGER;
        error               VARCHAR2 (2000);
        mmvc_id             mov_compromisso.mvc_contador%TYPE;
        logid               NUMBER;
        mcode               NUMBER;
        insert_mva          BOOLEAN;
        mlot_numero         mov_aberto_itf.lot_numero%TYPE;
        morigem_pk          mov_aberto_itf.origem_pk%TYPE;
        morigem_sistema     mov_aberto_itf.origem_sistema%TYPE;
        mmvc_mov            mov_compromisso.mvc_contador%TYPE;
        mmvc_contador       mov_compromisso.mvc_contador%TYPE;
        mtemperatura        mov_aberto_itf.temperatura%TYPE;
        mmvb_contador       mov_bancario.mvb_contador%TYPE;
        mcontabiliza        mov_bancario.contabilizado_flag%TYPE;
        mconciliado         mov_bancario.conciliado_flag%TYPE;
        mefetiva_real       syn_sistema_externo.efetiva_real%TYPE;
        mefetiva_previsto   syn_sistema_externo.efetiva_previsto%TYPE;
        mmmi_codigo         conta_financeira.mmi_codigo%TYPE;
        mtdp_codigo         tipo_de_documento_pagador.tdp_codigo%TYPE;
        mban_codigo         mov_aberto.ban_codigo%TYPE;
        mage_codigo         mov_aberto.age_codigo%TYPE;
        mcnt_codigo         mov_aberto.cnt_codigo%TYPE;
    -- Main
    BEGIN
        --Faço a limpeza da tabela de log de importação, e a mesma será alimentada novamente durante o processo:
        DELETE FROM consinco_logerros_itf;

        --Faço a limpeza da tabela de log de efetivação, e a mesma será alimentada novamente durante o processo:
        DELETE FROM log_efetiva_lote;

        -- NAO PROCESSO OS MOVIMENTOS DE PO SEM DATAS... AGUARDANDO CONSINCO (RC 153824)
        UPDATE mov_aberto_itf
           SET imported_flag = 'E'
         WHERE     origem_sistema = 'PO'
               AND data_caixa IS NULL
               AND data_pagamento IS NULL
               AND data_competencia IS NULL
               AND UPPER (NVL (imported_flag, 'N')) = 'N';

        COMMIT;
        --Gero o número do lote que será importado.
        mlot_numero := get_contador ('L');

        FOR l_itf
            IN (SELECT *
                  FROM mov_aberto_itf i
                 WHERE     NVL (imported_flag, 'N') = 'N'
                       AND i.origem_sistema <> 'GEF'
                ORDER BY mva_contador_itf)
        LOOP
            insert_mva := TRUE;

            -- Faço o depara das contas financeiras
            IF l_itf.tdo_codigo IN ('CHEQUE',
                                    'CHQDEV',
                                    'CHQPG',
                                    'CHQPRA',
                                    'CHQVIS')
            THEN                                                           ---
                BEGIN
                    SELECT mmi_codigo
                      INTO mmmi_codigo
                      FROM cf_x_cc
                     --WHERE conta_contabil = l_itf.informacoes_contabeis;
                     WHERE conta_contabil =
                                  l_itf.informacoes_contabeis
                               || '#'
                               || l_itf.tdo_codigo
                               || '#'
                               || l_itf.tdp_codigo;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        SELECT mmi_codigo
                          INTO mmmi_codigo
                          FROM syn_sistema_externo
                         WHERE origem_sistema = l_itf.origem_sistema;
                END;
            ELSE
                BEGIN                                                  ---- mm
                    SELECT mmi_codigo
                      INTO mmmi_codigo
                      FROM cf_x_cc
                     --WHERE conta_contabil = l_itf.informacoes_contabeis;
                     WHERE conta_contabil =
                                  l_itf.informacoes_contabeis
                               || '#'
                               || l_itf.tdo_codigo;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        SELECT mmi_codigo
                          INTO mmmi_codigo
                          FROM syn_sistema_externo
                         WHERE origem_sistema = l_itf.origem_sistema;
                END;                                                    --- mm
            END IF;

            -- ALTERADO EM 22/06/16 INCLUIR DESCRICAO DA OPERACAO NO DE-PARA
            -- abaixo o conteúdo enviado pela interface na mov_Aberto_itf
            -- tdp_codigo (ITF) = Descricao da operacao (Consinco) = opr_reduzida_consinco (Depara)
            -- tdo_codigo (ITF) = Especie               (Consinco) = tdp_codigo_origem (Depara)

            BEGIN
                SELECT DISTINCT tdp_codigo_destino
                  INTO mtdp_codigo
                  FROM consinco_depara_instrumento
                 WHERE     UPPER (TRIM (tdp_codigo_origem)) =
                               UPPER (TRIM (l_itf.tdo_codigo))
                       AND UPPER (TRIM (opr_reduzida_consinco)) =
                               UPPER (TRIM (l_itf.tdp_codigo));
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    mtdp_codigo := NULL;
            END;

            IF mtdp_codigo IS NULL
            THEN
                BEGIN
                    SELECT tdp_codigo_destino
                      INTO mtdp_codigo
                      FROM consinco_depara_instrumento
                     WHERE     UPPER (TRIM (tdp_codigo_origem)) =
                                   UPPER (TRIM (l_itf.tdo_codigo))
                           AND opr_reduzida_consinco IS NULL;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mtdp_codigo := l_itf.tdo_codigo;
                END;
            END IF;

            IF l_itf.origem_sistema IN ('AP', 'AR', 'PO')
            THEN
                l_itf.tdp_codigo := l_itf.tdo_codigo;
            ELSE
                mtdp_codigo := l_itf.tdp_codigo;
            END IF;

            --Faço o DEPARA dos dados bancários
            BEGIN
                SELECT bco_sage, age_sage, cc_sage
                  INTO mban_codigo, mage_codigo, mcnt_codigo
                  FROM bco_consinco_x_sage
                 WHERE     bco_consinco = l_itf.ban_codigo
                       AND age_consinco = l_itf.age_codigo
                       AND cc_consinco = l_itf.cnt_codigo;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    mban_codigo := l_itf.ban_codigo;
                    mage_codigo := l_itf.age_codigo;
                    mcnt_codigo := l_itf.cnt_codigo;
            END;

            BEGIN
                IF     l_itf.ban_codigo IS NOT NULL
                   AND l_itf.age_codigo IS NOT NULL
                   AND l_itf.cnt_codigo IS NOT NULL
                THEN
                    INSERT INTO bco_consinco_x_sage (bco_consinco,
                                                     age_consinco,
                                                     cc_consinco,
                                                     bco_sage,
                                                     age_sage,
                                                     cc_sage)
                    VALUES (l_itf.ban_codigo,
                            l_itf.age_codigo,
                            l_itf.cnt_codigo,
                            NULL,
                            NULL,
                            NULL);

                    COMMIT;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF (   mban_codigo IS NULL
                OR mage_codigo IS NULL
                OR mcnt_codigo IS NULL)
            THEN
                mban_codigo := l_itf.ban_codigo;
                mage_codigo := l_itf.age_codigo;
                mcnt_codigo := l_itf.cnt_codigo;
            END IF;


            IF l_itf.origem_sistema IN ('AP', 'AR', 'PO')
            THEN
                l_itf.dff_01 := l_itf.cec_codigo;
                l_itf.cec_codigo := l_itf.dff_02;

                --> mtdp_codigo := l_itf.tdo_codigo;

                -- Pego a empresa pelo o cadastro da conta corrente.
                BEGIN
                    SELECT pfj_codigo
                      INTO l_itf.pfj_codigo
                      FROM conta_corrente
                     WHERE     ban_codigo = mban_codigo
                           AND age_codigo = mage_codigo
                           AND cnt_codigo = mcnt_codigo;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        l_itf.pfj_codigo := l_itf.pfj_codigo;
                END;
            END IF;



            -- Insiro os dados na tabela mov_aberto
            BEGIN
                INSERT INTO mov_aberto (mva_contador,
                                        cec_codigo,
                                        mmi_transferencia,
                                        pfj_endereco,
                                        pfj_numero,
                                        pfj_cep,
                                        pfj_complemento,
                                        pfj_cpf,
                                        pfj_uf,
                                        pfj_descricao,
                                        pfj_cidade,
                                        ban_codigo,
                                        age_codigo,
                                        cnt_codigo,
                                        tdp_codigo,
                                        doc_pagador,
                                        prefix_doc_pagador,
                                        man_aut,
                                        ban_emitente,
                                        age_emitente,
                                        cnt_emitente,
                                        pfj_codigo,
                                        pfj_emitente,
                                        tdo_codigo,
                                        ind_codigo_real,
                                        valor_original,
                                        valor,
                                        lot_numero,
                                        doc_origem,
                                        historico,
                                        mmi_reciprocidade,
                                        data_efetivacao,
                                        data_contabilizacao,
                                        conta_contabil,
                                        temperatura,
                                        origem_sistema,
                                        origem_pk,
                                        taxa_conversao_corr,
                                        taxa_conversao_cnt,
                                        pfj_origem_destino,
                                        mmi_codigo,
                                        cnc_emitente,
                                        informacoes_contabeis,
                                        conta_contabil_transferencia,
                                        status,
                                        finalidade,
                                        data_caixa,
                                        data_competencia,
                                        ind_codigo_ccc,
                                        data_pagamento,
                                        controle_interno,
                                        origem_processo,
                                        taxa_conversao_corr_fixa,
                                        taxa_conversao_cnt_fixa,
                                        mva_contador_par,
                                        origem_contabil,
                                        mmi_ent_sai,
                                        job_id,
                                        autorizado_0_por,
                                        autorizado_1_por,
                                        autorizado_0_em,
                                        autorizado_1_em,
                                        dff_01,
                                        dff_02,
                                        dff_03,
                                        dff_04,
                                        dff_05,
                                        status_aprovacao,
                                        sol_id,
                                        par_contador_liq,
                                        moeda_codigo,
                                        pfj_nome,
                                        pfj_tipo)
                VALUES (seq_mva.NEXTVAL,
                        l_itf.cec_codigo,                        --cec_codigo,
                        NULL,
                        --l_itf.mmi_transferencia,
                        --NULL,                                --l_itf.pfj_nome,
                        NULL,                            --l_itf.pfj_endereco,
                        NULL,                              --l_itf.pfj_numero,
                        NULL,                                 --l_itf.pfj_cep,
                        NULL,                         --l_itf.pfj_complemento,
                        NULL,                                 --l_itf.pfj_cpf,
                        NULL,                                  --l_itf.pfj_uf,
                        NULL,                           --l_itf.pfj_descricao,
                        NULL,                              --l_itf.pfj_cidade,
                        -- NULL,                               --l_itf.pfj_tipo,
                        mban_codigo,                             --ban_codigo,
                        mage_codigo,                             --age_codigo,
                        mcnt_codigo,
                        --cnt_codigo,
                        mtdp_codigo,
                        --tdp_codigo,
                        l_itf.doc_pagador,
                        --l_itf.doc_pagador,
                        NULL,
                        --l_itf.prefix_doc_pagador,

                        --NULL                                  --memitido_flag,
                        'N',                                 -- l_itf.man_aut,
                        NULL,                            --l_itf.ban_emitente,
                        NULL,                            --l_itf.age_emitente,
                        NULL,                            --l_itf.cnt_emitente,
                        LPAD (l_itf.pfj_codigo, 3, 0),
                        --pfj_codigo,
                        NULL,                            --l_itf.pfj_emitente,
                        NULL,                              --l_itf.tdo_codigo,
                        'BRA-BRL/BRL',                      --ind_codigo_real,
                        l_itf.valor_original,                --valor_original,
                        l_itf.valor,
                        --valor,
                        mlot_numero,
                        --lot_numero,
                        l_itf.doc_origem,                  --l_itf.doc_origem,
                        l_itf.historico,
                        --historico,
                        0,
                        --l_itf.mmi_reciprocidade,
                        SYSDATE,                      --l_itf.data_efetivacao,
                        l_itf.data_contabilizacao,
                        --data_contabilizacao,
                        NULL,                                --conta_contabil,
                        l_itf.temperatura,                      --temperatura,
                        TRIM (l_itf.origem_sistema),
                        --origem_sistema,
                        TRIM (l_itf.origem_pk),                   --origem_pk,
                        l_itf.taxa_conversao_corr,
                        --taxa_conversao_corr,
                        l_itf.taxa_conversao_cnt,        --taxa_conversao_cnt,
                        NULL,
                        --l_itf.pfj_origem_destino,
                        mmmi_codigo,
                        --mmi_codigo,
                        NULL,                            --l_itf.cnc_emitente,
                        --l_itf.conta_contabil,
                        l_itf.informacoes_contabeis,
                        NULL,                  --conta_contabil_transferencia,
                        '05_A_EFETIVAR',                            -- status,
                        NULL,                              --l_itf.finalidade,
                        l_itf.data_caixa,                        --data_caixa,
                        l_itf.data_competencia,
                        --data_competencia,
                        NULL,
                        --l_itf.ind_codigo_ccc,
                        l_itf.data_pagamento,                --data_pagamento,
                        NULL,                              --controle_interno,
                        l_itf.origem_processo,
                        --origem_processo,
                        'S',                 --l_itf.taxa_conversao_corr_fixa,
                        'N',                        --taxa_conversao_cnt_fixa,
                        0,                                 --mva_contador_par,
                        NULL,                               --origem_contabil,
                        NULL,                                   --mmi_ent_sai,
                        0,                                           --job_id,
                        NULL,                              --autorizado_0_por,
                        NULL,                              --autorizado_1_por,
                        NULL,                               --autorizado_0_em,
                        NULL,                               --autorizado_1_em,
                        l_itf.dff_01,                               -- dff_01,
                        NULL,                                       -- dff_02,
                        NULL,                                       -- dff_03,
                        'N',                                        -- dff_04,
                        NULL,                                       -- dff_05,
                        NULL,                              --status_aprovacao,
                        0,                                          -- sol_id,
                        0,
                        l_itf.moeda_codigo,
                        l_itf.pfj_nome,
                        '4');

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    BEGIN
                        insert_mva := FALSE;
                        icont := icont + 1;
                        error := TO_CHAR (SQLERRM);

                        INSERT
                          INTO consinco_logerros_itf (linha,
                                                      data,
                                                      mva_contador_itf)
                            VALUES (
                                          'Seq: '
                                       || TO_CHAR (icont, '00000')
                                       || ' -Origem_PK:'
                                       || l_itf.origem_pk
                                       || '-'
                                       || 'Erro:'
                                       || SUBSTR (error, 1, 255),
                                       TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                       l_itf.mva_contador_itf);
                    END;

                    COMMIT;
            END;

            --IF insert_mva THEN
            UPDATE mov_aberto_itf
               SET imported_flag = 'S', imported_at = SYSDATE
             WHERE mva_contador_itf = l_itf.mva_contador_itf;

            --END IF;

            COMMIT;
        END LOOP;

        -- Pre-Efetivação dos movimentos.
        FOR l_mva IN (SELECT *
                        FROM mov_aberto
                       WHERE origem_sistema <> 'GEF' AND dff_04 = 'N'
                      ORDER BY mva_contador)
        LOOP
            icont := 0;
            morigem_pk := l_mva.origem_pk;
            morigem_sistema := l_mva.origem_sistema;

            BEGIN
                SELECT COUNT (*)
                  INTO mmvc_mov
                  FROM mov_compromisso
                 WHERE     origem_sistema = l_mva.origem_sistema
                       AND origem_pk = l_mva.origem_pk;

                IF mmvc_mov > 0
                THEN
                    SELECT mvc_contador
                      INTO mmvc_contador
                      FROM mov_compromisso
                     WHERE     origem_pk = l_mva.origem_pk
                           AND origem_sistema = l_mva.origem_sistema
                           AND temperatura = -1;
                END IF;

                IF mmvc_contador IS NOT NULL
                THEN
                    IF mtemperatura = '-1'
                    THEN
                        SELECT mvb_contador
                          INTO mmvb_contador
                          FROM mov_compromisso
                         WHERE mvc_contador = mmvc_contador;
                    END IF;
                END IF;

                --Faço a limpeza dos movimentos que estão sendo reenviados.
                IF mmvb_contador IS NOT NULL
                THEN
                    SELECT contabilizado_flag, conciliado_flag
                      INTO mcontabiliza, mconciliado
                      FROM mov_bancario
                     WHERE mvb_contador = mmvb_contador;

                    IF mcontabiliza = 'S' OR mconciliado = 'S'
                    THEN
                        NULL;
                    ELSE
                        altera_mov (mmvc_contador,
                                    0,
                                    FALSE,
                                    TRUE);
                    END IF;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
            END;

            BEGIN
                SELECT efetiva_real, efetiva_previsto
                  INTO mefetiva_real, mefetiva_previsto
                  FROM syn_sistema_externo
                 WHERE TRIM (origem_sistema) = TRIM (l_mva.origem_sistema);
            EXCEPTION
                WHEN OTHERS
                THEN
                    mefetiva_real := 'A';
                    mefetiva_previsto := 'A';
            END;

            --Efetivação dos movimentos importados
            IF l_mva.mmi_codigo IS NOT NULL AND icont = 0
            THEN
                IF    (l_mva.temperatura = -1 AND mefetiva_real = 'E')
                   OR (l_mva.temperatura <> -1 AND mefetiva_previsto = 'E')
                THEN
                    BEGIN
                        mmvc_id := efetiva_mov_c (l_mva.mva_contador, 1);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mcode := SQLCODE;
                            error := SQLERRM;
                            logid := get_contador ('r');

                            INSERT INTO log_efetiva_lote (log_contador,
                                                          mva_contador,
                                                          lot_numero,
                                                          valor,
                                                          historico,
                                                          data_efetivacao,
                                                          data_processamento,
                                                          code,
                                                          errm)
                            VALUES (logid,
                                    l_mva.mva_contador,
                                    l_mva.lot_numero,
                                    l_mva.valor,
                                    l_mva.historico,
                                    l_mva.data_efetivacao,
                                    SYSDATE,
                                    mcode,
                                    error);

                            UPDATE mov_aberto
                               SET dff_04 = 'S'
                             WHERE mva_contador = l_mva.mva_contador;

                            COMMIT;
                    END;
                ELSE
                    UPDATE mov_aberto
                       SET dff_04 = 'S'
                     WHERE mva_contador = l_mva.mva_contador;

                    COMMIT;
                END IF;
            ELSE
                UPDATE mov_aberto
                   SET dff_04 = 'S'
                 WHERE mva_contador = l_mva.mva_contador;

                COMMIT;
            END IF;
        END LOOP;

        COMMIT;
    END;

    --- Fim da Procedure  consinco_efetiva
    --- Fim da Procedure  consinco_efetiva
    PROCEDURE consinco_sage_ctb (p_lote VARCHAR2)
    IS
        mseq                 NUMBER;
        mhistorico           VARCHAR2 (100);
        mconta_contabil      mov_contabil.conta_contabil%TYPE;
        mpfj_agente          operacao.pfj_agente%TYPE;
        mcec_codigo_dev      mov_contabil_itc.cec_codigo%TYPE;
        msegment_deb         mov_contabil_itc.conta_contabil%TYPE;
        mcec_codigo_cred     mov_contabil_itc.cec_codigo%TYPE;
        msegment_cred        mov_contabil_itc.conta_contabil%TYPE;
        mpfj_codigo          mov_contabil_itc.pfj_codigo%TYPE;
        mpfj_codigo_opr      mov_contabil_itc.pfj_codigo%TYPE;
        mpfj_filial          composicao_de_hierarquia.pfj_pai%TYPE;
        mcontacr             mov_contabil_itc.cnt_cont_credito%TYPE;
        mcontadeb            mov_contabil_itc.cnt_cont_debito%TYPE;
        mpfj_ger             mov_contabil.pfj_codigo%TYPE;
        msegment_cred_ger    mov_contabil_itc.conta_contabil%TYPE;
        msegment_deb_ger     mov_contabil_itc.conta_contabil%TYPE;
        mban_codigo_ent      operacao.ban_codigo_ent%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mage_codigo_ent      operacao.age_codigo_ent%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mcnt_codigo_ent      operacao.cnt_codigo_ent%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mban_codigo_sai      operacao.ban_codigo_sai%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mage_codigo_sai      operacao.age_codigo_sai%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mcnt_codigo_sai      operacao.cnt_codigo_sai%TYPE; -- VARIAVEL CRIADA 23/11/2015 MM
        mcon_codigo          operacao.con_codigo%TYPE;       -- VIDAL 04042017
        mmdo_codigo          operacao.con_codigo%TYPE;       -- VIDAL 04042017
        mcritica_retorno     VARCHAR2 (1);
        merro_insert         VARCHAR2 (250);
        mcodentidadedb       VARCHAR2 (50);
        mcodentidadecr       VARCHAR2 (50);
        mcodentidadedb_ger   VARCHAR2 (50);
        mcodentidadecr_ger   VARCHAR2 (50);
        insere_mvt           VARCHAR2 (1);
    -- Purpose: Interface Contabil - SAGE XRT com a CONSINCO
    -- Insert em tabela.
    --
    -- MODIFICATION HISTORY
    -- Person      Date        Comments
    -- ---------   ----------  -------------------------------------------
    -- Marcos M.   30/04/2015   Criação
    -- Geraldo L.  30/04/2015   Validação
    BEGIN
        -- Faço a exclusao dos lotes concelados no XRT
        DELETE FROM mov_contabil_itc itc
         WHERE NOT EXISTS
                   (SELECT lote
                      FROM mov_contabil mvt
                     WHERE mvt.lote = itc.lote);

        -- MM 04/03/2016 Faço a limpeza da tabela de log de execução da rotina da CONSINCO.
        --DELETE FROM ctb;  --VIDAL 24/02/2017 removida exclusao do log do execução para analise de execução da rotina

        COMMIT;

        --pesquisa a tabela mov_contabil para gerar dados de carga na mov_contabil_itc

        --VIDAL 01032017 EFETUADO SEPARAÇÃO DO CODIGO PARA BUSCA DE TIPOS (PRI, JUR E IR), SENDO ENVIADO O VALOR DO TIPO (JUROS+IR) JUNTOS NA PRIMEIRA PARTE DO CODIGO
        --E DEMAIS TIPOS NA SEGUNDA PARTE DESTE CODIGO APOS O UNION.

        BEGIN
            FOR l_mvt
                IN (SELECT mvt_contador,
                           pfj_codigo,
                           opr_numero,
                           sop_contador,
                           data,
                           ind_codigo,
                           cnt_cont_credito,
                           cnt_cont_debito,
                           conta_contabil,
                           credito_debito,
                           valor,                             --vidal 01032017
                           taxa_conversao_corr,
                           tipo,
                           mvt_contador_origem,
                           critica,
                           lote,
                           status,
                           mvc_contador,
                           (SELECT    LPAD (o.con_codigo, 15, '0')
                                   || '#'
                                   || LPAD (o.opr_numero, 5, '0')
                                   || '#'
                                   || (SELECT LPAD (COUNT (1), 3, '0')
                                         FROM parcela
                                        WHERE     opr_numero = o.opr_numero
                                              AND par_tipo = p.par_tipo
                                              AND par_ent_sai = 'S'
                                              AND valor_pago <> 0)
                                   || '/'
                                   || (SELECT LPAD (COUNT (1), 3, '0')
                                         FROM parcela
                                        WHERE     opr_numero = o.opr_numero
                                              AND par_tipo = p.par_tipo
                                              AND par_ent_sai = 'S')
                                   || '#'
                                   || '#'
                                   || p.par_tipo
                                   || '#'
                                   || o.mdo_codigo
                                   || '#'
                                   || SUBSTR (
                                          d.historico,
                                          1,
                                          INSTR (d.historico, ' - ', 1) - 1)
                              FROM operacao o, parcela p, mov_contabil d
                             WHERE     d.mvt_contador = mvt.mvt_contador
                                   AND p.opr_numero = mvt.opr_numero
                                   AND o.opr_numero = p.opr_numero
                                   AND p.par_tipo = mvt.tipo
                                   AND ROWNUM = 1)
                               AS historico,
                           par_contabil,
                           seq_arq,
                           map_contador,
                           origem_contabil,
                           ban_codigo,
                           age_codigo,
                           cnt_codigo,
                           data_original,
                           apropriacao_caixa,
                           hp_codigo,
                           gerado_por,
                           aprovado_por,
                           origem_processo
                      FROM mov_contabil mvt
                     WHERE     status = 'I'
                           AND lote = p_lote
                           AND apropriacao_caixa = 'A'
                           AND (historico NOT LIKE '%Ajuste%') -- Fabio 080217  filtrado para nao buscar linhas com historico AJUSTE
                           AND NOT EXISTS
                                   (SELECT DISTINCT itc.par_contabil
                                      FROM mov_contabil_itc itc
                                     WHERE     lote = p_lote
                                           AND itc.par_contabil =
                                                   mvt.par_contabil))
            --carrega na mov_contabil_itc os dados pesquisados na tabela mov_contabil

            LOOP
                BEGIN
                    INSERT INTO mov_contabil_itc (mvt_contador_itc,
                                                  pfj_codigo,
                                                  opr_numero,
                                                  sop_contador,
                                                  data,
                                                  ind_codigo,
                                                  cnt_cont_credito,
                                                  cnt_cont_debito,
                                                  conta_contabil,
                                                  credito_debito,
                                                  valor,
                                                  taxa_conversao_corr,
                                                  tipo,
                                                  mvt_contador_origem,
                                                  critica,
                                                  lote,
                                                  status,
                                                  mvc_contador,
                                                  historico,
                                                  par_contabil,
                                                  seq_arq,
                                                  map_contador,
                                                  origem_contabil,
                                                  ban_codigo,
                                                  age_codigo,
                                                  cnt_codigo,
                                                  data_original,
                                                  apropriacao_caixa,
                                                  hp_codigo,
                                                  gerado_por,
                                                  aprovado_por,
                                                  origem_processo)
                    VALUES (l_mvt.mvt_contador,
                            l_mvt.pfj_codigo,
                            l_mvt.opr_numero,
                            l_mvt.sop_contador,
                            l_mvt.data,
                            l_mvt.ind_codigo,
                            l_mvt.cnt_cont_credito,
                            l_mvt.cnt_cont_debito,
                            l_mvt.conta_contabil,
                            l_mvt.credito_debito,
                            l_mvt.valor,
                            l_mvt.taxa_conversao_corr,
                            l_mvt.tipo,
                            l_mvt.mvt_contador_origem,
                            l_mvt.critica,
                            l_mvt.lote,
                            l_mvt.status,
                            l_mvt.mvc_contador,
                            l_mvt.historico,
                            l_mvt.par_contabil,
                            l_mvt.seq_arq,
                            l_mvt.map_contador,
                            l_mvt.origem_contabil,
                            l_mvt.ban_codigo,
                            l_mvt.age_codigo,
                            l_mvt.cnt_codigo,
                            l_mvt.data_original,
                            l_mvt.apropriacao_caixa,
                            l_mvt.hp_codigo,
                            l_mvt.gerado_por,
                            l_mvt.aprovado_por,
                            l_mvt.origem_processo);
                END;
            END LOOP;

            COMMIT;
        END;

        --atualiza as contas de credito e debito na mov_contabil_itc conforme a conta contabil

        UPDATE mov_contabil_itc
           SET cnt_cont_credito = conta_contabil
         WHERE credito_debito = 'C' AND lote = p_lote;

        COMMIT;

        UPDATE mov_contabil_itc
           SET cnt_cont_debito = conta_contabil
         WHERE credito_debito = 'D' AND lote = p_lote;

        COMMIT;

        -- Inicia o loop

        FOR l_itc IN (SELECT pfj_codigo,
                             data,
                             par_contabil,
                             cnt_cont_debito,
                             cec_codigo,
                             cnt_cont_credito,
                             valor,
                             historico,
                             taxa_conversao_corr,
                             mvt_contador_itc,
                             opr_numero,
                             conta_contabil,
                             lote,
                             credito_debito
                        FROM mov_contabil_itc
                       WHERE status = 'I' AND lote = p_lote
                      ORDER BY par_contabil)
        LOOP
            BEGIN
                mpfj_agente := NULL;
                msegment_cred := NULL;
                msegment_deb := NULL;
                mban_codigo_ent := NULL;
                mage_codigo_ent := NULL;
                mcnt_codigo_ent := NULL;
                mmdo_codigo := NULL;
                mcodentidadedb := NULL;
                mcodentidadecr := NULL;
                mcodentidadedb_ger := NULL;
                mcodentidadecr_ger := NULL;
                merro_insert := NULL;
                insere_mvt := 'S';

                -- Faço o depara de agente por entidade
                BEGIN
                    SELECT pfj_agente ---- 23/11/2015 MM FORAM ADICIONADOS OS CAMPOS BANCO AGÊNCIA E CONTA
                                     ,
                           ban_codigo_ent,
                           age_codigo_ent,
                           cnt_codigo_ent,
                           mdo_codigo,
                           pfj_codigo
                      INTO mpfj_agente,
                           mban_codigo_ent,
                           mage_codigo_ent,
                           mcnt_codigo_ent,
                           mmdo_codigo,
                           mpfj_codigo_opr
                      FROM operacao
                     WHERE opr_numero = l_itc.opr_numero;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mpfj_agente := NULL;
                END;

                IF    mban_codigo_ent IS NULL
                   OR mage_codigo_ent IS NULL
                   OR mcnt_codigo_ent IS NULL
                THEN
                    BEGIN
                        SELECT pfj_agente ---- 23/11/2015 MM FORAM ADICIONADOS OS CAMPOS BANCO AGÊNCIA E CONTA
                                         ,
                               ban_codigo_sai,
                               age_codigo_sai,
                               cnt_codigo_sai,
                               mdo_codigo,
                               pfj_codigo
                          INTO mpfj_agente,
                               mban_codigo_ent,
                               mage_codigo_ent,
                               mcnt_codigo_ent,
                               mmdo_codigo,
                               mpfj_codigo_opr
                          FROM operacao
                         WHERE opr_numero = l_itc.opr_numero;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            mpfj_agente := NULL;
                    END;
                END IF;


                --Tratamento de conta debito
                BEGIN
                    SELECT conta_contabil,
                           historico,
                           SUBSTR (cnt_cont_debito,
                                     INSTR (cnt_cont_debito,
                                            '.',
                                            1,
                                            2)
                                   + 1,
                                     (LENGTH (cnt_cont_debito) - 2)
                                   - INSTR (cnt_cont_debito,
                                            '.',
                                            1,
                                            2)
                                   - 2)
                               segment_deb,
                           SUBSTR (cnt_cont_debito,
                                     INSTR (cnt_cont_debito,
                                            '.',
                                            1,
                                            1)
                                   + 1,
                                     (LENGTH (cnt_cont_debito) - 1)
                                   - INSTR (cnt_cont_debito,
                                            '.',
                                            1,
                                            2)
                                   - 2)
                               cec_codigo_dev,
                           cnt_cont_debito
                      INTO mconta_contabil,
                           mhistorico,
                           msegment_deb,
                           mcec_codigo_dev,
                           mcontadeb
                      FROM mov_contabil_itc
                     WHERE     status = 'I'
                           AND lote = p_lote
                           --AND credito_debito = 'D'
                           AND par_contabil = l_itc.par_contabil
                           AND mvt_contador_itc = l_itc.mvt_contador_itc;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;


                BEGIN
                    SELECT conta_contabil,
                           historico,
                           SUBSTR (cnt_cont_credito,
                                     INSTR (cnt_cont_credito,
                                            '.',
                                            1,
                                            2)
                                   + 1,
                                     (LENGTH (cnt_cont_credito) - 2)
                                   - INSTR (cnt_cont_credito,
                                            '.',
                                            1,
                                            2)
                                   - 2),
                           SUBSTR (cnt_cont_credito,
                                     INSTR (cnt_cont_credito,
                                            '.',
                                            1,
                                            1)
                                   + 1,
                                     (LENGTH (cnt_cont_credito) - 1)
                                   - INSTR (cnt_cont_credito,
                                            '.',
                                            1,
                                            2)
                                   - 2),
                           cnt_cont_credito
                      INTO mconta_contabil,
                           mhistorico,
                           msegment_cred,
                           mcec_codigo_cred,
                           mcontacr
                      FROM mov_contabil_itc
                     WHERE     status = 'I'
                           AND lote = p_lote
                           --AND credito_debito = 'C'
                           AND par_contabil = l_itc.par_contabil
                           AND mvt_contador_itc = l_itc.mvt_contador_itc;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;



                IF mcec_codigo_dev = '000'
                THEN
                    mcec_codigo_dev := NULL;
                END IF;

                IF mcec_codigo_cred = '000'
                THEN
                    mcec_codigo_cred := NULL;
                END IF;

                --Pego a empresa correta para enviar

                BEGIN
                    SELECT DISTINCT pfj_pai
                      INTO mpfj_filial
                      FROM composicao_de_hierarquia
                     WHERE     pfj_codigo = l_itc.pfj_codigo
                           AND pfj_pai IS NOT NULL;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mpfj_filial := NULL;
                END;

                IF mpfj_filial IS NULL
                THEN
                    mpfj_codigo := l_itc.pfj_codigo;
                    mpfj_filial := l_itc.pfj_codigo;
                ELSE
                    mpfj_codigo := mpfj_filial;
                    mpfj_filial := l_itc.pfj_codigo;
                END IF;

                IF l_itc.credito_debito = 'D'
                THEN
                    msegment_cred := NULL;
                    mcodentidadecr := NULL;

                    IF mmdo_codigo = 'MUTUO'
                    THEN
                        mcodentidadedb :=
                               mpfj_agente
                            || '#'
                            || msegment_deb
                            || '#'
                            || mpfj_codigo_opr;
                    ELSE
                        mcodentidadedb :=
                               mpfj_agente
                            || '#'
                            || msegment_deb
                            || '#'
                            || mban_codigo_ent
                            || '#'
                            || mage_codigo_ent
                            || '#'
                            || mcnt_codigo_ent;
                    END IF;
                ELSE
                    msegment_deb := NULL;
                    mcodentidadedb := NULL;

                    IF mmdo_codigo = 'MUTUO'
                    THEN
                        mcodentidadecr :=
                               mpfj_agente
                            || '#'
                            || msegment_cred
                            || '#'
                            || mpfj_codigo_opr;
                    ELSE
                        mcodentidadecr :=
                               mpfj_agente
                            || '#'
                            || msegment_cred
                            || '#'
                            || mban_codigo_ent
                            || '#'
                            || mage_codigo_ent
                            || '#'
                            || mcnt_codigo_ent;
                    END IF;
                END IF;


                -- insiro conta fiscal

                BEGIN
                    INSERT INTO consinco.ct_integralancto (seqintegracao,
                                                           nroempresa,
                                                           filial,
                                                           datalancamento,
                                                           usualteracao,
                                                           origem,
                                                           chaveorigem,
                                                           loteorigem,
                                                           nroprocorigem,
                                                           valor,
                                                           historico,
                                                           nroarquivodocto,
                                                           contadb,
                                                           codentidadedb,
                                                           centrocustodb,
                                                           contacr,
                                                           codentidadecr,
                                                           centrocustocr,
                                                           situacao,
                                                           dtaintegrado,
                                                           lote,
                                                           nroprocesso,
                                                           msgerro)
                        VALUES (
                                   NULL,                      -- SEQINTEGRACAO
                                   SUBSTR (mpfj_codigo, 1, 3),   -- NROEMPRESA
                                   SUBSTR (mpfj_filial, 1, 3),        --FILIAL
                                   l_itc.data,              --  datalancamento
                                   'XRT',                      -- USUALTERACAO
                                   'XRT',                             --ORIGEM
                                      SUBSTR (mpfj_codigo, 1, 3)
                                   || '#'
                                   || l_itc.mvt_contador_itc,    --CHAVEORIGEM
                                   l_itc.lote,                    --LOTEORIGEM
                                   l_itc.par_contabil,         --NROPROCORIGEM
                                   l_itc.valor,                        --VALOR
                                   TRIM (SUBSTR (l_itc.historico, 1, 250)), -- historico
                                   l_itc.par_contabil,       --NROARQUIVODOCTO
                                   msegment_deb,                     --CONTADB
                                   mcodentidadedb,             --CODENTIDADEDB
                                   mcec_codigo_dev,            --CENTROCUSTODB
                                   msegment_cred,                    --CONTACR
                                   mcodentidadecr,             --CODENTIDADECR
                                   mcec_codigo_cred,           --CENTROCUSTOCR
                                   'P',                             --SITUACAO
                                   NULL,                        --DTAINTEGRADO
                                   NULL,                               -- LOTE
                                   NULL,                        -- NROPROCESSO
                                   NULL                             -- MSGERRO
                                       );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        insere_mvt := 'N';
                        merro_insert := SUBSTR (SQLERRM, 1, 100);

                        UPDATE mov_contabil
                           SET critica =
                                      'Erro para gravar o lançamento FISCAL  mvt_contador: '
                                   || l_itc.mvt_contador_itc
                                   || ' na tabela da Consinco consinco.ct_integralanctodados. '
                                   || 'Mensagem de erro:  '
                                   || merro_insert
                         WHERE mvt_contador = l_itc.mvt_contador_itc;

                        UPDATE mov_contabil_itc
                           SET critica =
                                      'Erro para gravar o lançamento FISCAL  mvt_contador: '
                                   || l_itc.mvt_contador_itc
                                   || ' na tabela da Consinco consinco.ct_integralanctodados. '
                                   || 'Mensagem de erro:  '
                                   || merro_insert
                         WHERE mvt_contador_itc = l_itc.mvt_contador_itc;
                END;

                IF insere_mvt = 'S'
                THEN
                    UPDATE mov_contabil_itc
                       SET status = 'C'
                     WHERE mvt_contador_itc = l_itc.mvt_contador_itc;

                    UPDATE mov_contabil
                       SET status = 'C'
                     WHERE mvt_contador = l_itc.mvt_contador_itc;
                END IF;

                COMMIT;

                -- insiro conta gerencial
                BEGIN
                    SELECT empresa_ger
                      INTO mpfj_ger
                      FROM consinco_emp_fis_x_emp_ger
                     WHERE empresa_fis = mpfj_codigo;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        mpfj_ger := 'XXX';
                END;



                BEGIN
                    SELECT DISTINCT pfj_pai
                      INTO mpfj_filial
                      FROM composicao_de_hierarquia
                     WHERE pfj_codigo = mpfj_ger AND pfj_pai IS NOT NULL;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mpfj_filial := NULL;
                END;

                IF mpfj_filial IS NULL
                THEN
                    mpfj_codigo := mpfj_ger;
                    mpfj_filial := mpfj_ger;
                ELSE
                    mpfj_codigo := mpfj_filial;
                    mpfj_filial := mpfj_ger;
                END IF;

                BEGIN
                    SELECT conta_contabil_ger
                      INTO msegment_deb_ger
                      FROM consinco_ctb_fis_x_ctb_ger
                     WHERE conta_contabil_fis = msegment_deb;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        msegment_deb_ger := '11111111';
                END;

                BEGIN
                    SELECT conta_contabil_ger
                      INTO msegment_cred_ger
                      FROM consinco_ctb_fis_x_ctb_ger
                     WHERE conta_contabil_fis = msegment_cred;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        msegment_cred_ger := '22222222';
                END;


                IF mcec_codigo_dev = '000'
                THEN
                    mcec_codigo_dev := NULL;
                END IF;

                IF mcec_codigo_cred = '000'
                THEN
                    mcec_codigo_cred := NULL;
                END IF;

                IF LENGTH (mcec_codigo_dev) > 6
                THEN
                    mcec_codigo_dev := '901';
                END IF;

                IF LENGTH (mcec_codigo_cred) > 6
                THEN
                    mcec_codigo_dev := '901';
                END IF;

                IF l_itc.credito_debito = 'D'
                THEN
                    msegment_cred_ger := NULL;
                    mcodentidadecr_ger := NULL;

                    IF mmdo_codigo = 'MUTUO'
                    THEN
                        mcodentidadedb_ger :=
                               mpfj_agente
                            || '#'
                            || SUBSTR (msegment_deb_ger, 1, 15)
                            || '#'
                            || mpfj_codigo_opr;
                    ELSE
                        mcodentidadedb_ger :=
                               mpfj_agente
                            || '#'
                            || SUBSTR (msegment_deb_ger, 1, 15)
                            || '#'
                            || mban_codigo_ent
                            || '#'
                            || mage_codigo_ent
                            || '#'
                            || mcnt_codigo_ent;
                    END IF;
                ELSE
                    msegment_deb_ger := NULL;
                    mcodentidadedb_ger := NULL;

                    IF mmdo_codigo = 'MUTUO'
                    THEN
                        mcodentidadecr_ger :=
                               mpfj_agente
                            || '#'
                            || SUBSTR (msegment_cred_ger, 1, 15)
                            || '#'
                            || mpfj_codigo_opr;
                    ELSE
                        mcodentidadecr_ger :=
                               mpfj_agente
                            || '#'
                            || SUBSTR (msegment_cred_ger, 1, 15)
                            || '#'
                            || mban_codigo_ent
                            || '#'
                            || mage_codigo_ent
                            || '#'
                            || mcnt_codigo_ent;
                    END IF;
                END IF;

                BEGIN
                    merro_insert := NULL;
                    insere_mvt := 'S';

                    INSERT INTO consinco.ct_integralancto (seqintegracao,
                                                           nroempresa,
                                                           filial,
                                                           datalancamento,
                                                           usualteracao,
                                                           origem,
                                                           chaveorigem,
                                                           loteorigem,
                                                           nroprocorigem,
                                                           valor,
                                                           historico,
                                                           nroarquivodocto,
                                                           contadb,
                                                           codentidadedb,
                                                           centrocustodb,
                                                           contacr,
                                                           codentidadecr,
                                                           centrocustocr,
                                                           situacao,
                                                           dtaintegrado,
                                                           lote,
                                                           nroprocesso,
                                                           msgerro)
                        VALUES (
                                   NULL,                      -- SEQINTEGRACAO
                                   SUBSTR (mpfj_codigo, 1, 3),   -- NROEMPRESA
                                   SUBSTR (mpfj_filial, 1, 3),        --FILIAL
                                   l_itc.data,              --  datalancamento
                                   'XRT',                      -- USUALTERACAO
                                   'XRT',                             --ORIGEM
                                      SUBSTR (mpfj_codigo, 1, 3)
                                   || '#'
                                   || l_itc.mvt_contador_itc,    --CHAVEORIGEM
                                   l_itc.lote,                    --LOTEORIGEM
                                   l_itc.par_contabil,         --NROPROCORIGEM
                                   l_itc.valor,                        --VALOR
                                   TRIM (SUBSTR (l_itc.historico, 1, 250)), -- historico
                                   l_itc.par_contabil,       --NROARQUIVODOCTO
                                   SUBSTR (msegment_deb_ger, 1, 15), --contadb
                                   mcodentidadedb_ger,         --CODENTIDADEDB
                                   mcec_codigo_dev,            --CENTROCUSTODB
                                   SUBSTR (msegment_cred_ger, 1, 15), -- contacr
                                   mcodentidadecr_ger,         --CODENTIDADECR
                                   mcec_codigo_cred,           --CENTROCUSTOCR
                                   'P',                             --SITUACAO
                                   NULL,                        --DTAINTEGRADO
                                   NULL,                               -- LOTE
                                   NULL,                        -- NROPROCESSO
                                   NULL                             -- MSGERRO
                                       );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        merro_insert := SUBSTR (SQLERRM, 1, 100);
                        insere_mvt := 'N';

                        UPDATE mov_contabil
                           SET critica =
                                      'Erro para gravar o lançamento GERENCIAL  mvt_contador: '
                                   || l_itc.mvt_contador_itc
                                   || ' na tabela da Consinco consinco.ct_integralanctodados. '
                                   || 'Mensagem de erro:  '
                                   || merro_insert
                         WHERE mvt_contador = l_itc.mvt_contador_itc;

                        UPDATE mov_contabil_itc
                           SET critica =
                                      'Erro para gravar o lançamento GERENCIAL  mvt_contador: '
                                   || l_itc.mvt_contador_itc
                                   || ' na tabela da Consinco consinco.ct_integralanctodados. '
                                   || 'Mensagem de erro:  '
                                   || merro_insert
                         WHERE mvt_contador_itc = l_itc.mvt_contador_itc;
                END;

                IF insere_mvt = 'S'
                THEN
                    UPDATE mov_contabil_itc
                       SET status = 'C'
                     WHERE mvt_contador_itc = l_itc.mvt_contador_itc;

                    UPDATE mov_contabil
                       SET status = 'C'
                     WHERE mvt_contador = l_itc.mvt_contador_itc;
                END IF;

                COMMIT;
            END;
        END LOOP;
    END;

    --Fim da procedure consinco_sage_ctb



    --Fim da procedure consinco_sage_ctb

    PROCEDURE consinco_sage_titulo_mensal
    IS
        -- Variaveis
        pnseq                 NUMBER;
        pnseq1                NUMBER;
        pnseq2                NUMBER;
        pnseq_estorno         NUMBER;
        mnroempresa           mov_compromisso.pfj_codigo%TYPE;
        mnroempresamae        mov_compromisso.pfj_codigo%TYPE;
        mpfj_codigo           operacao.pfj_codigo%TYPE;
        mpfj_agente           operacao.pfj_agente%TYPE;
        mcgc                  pessoa.cgc%TYPE;
        mcodoperacao          NUMBER;
        mvlroriginal          NUMBER;
        mvalorreal            NUMBER;
        mcont_parcelas        NUMBER;
        mcont_parcelas_ctl    NUMBER;
        morigem_pk            VARCHAR2 (50);
        mpar_contador         NUMBER;
        mimportado            BOOLEAN DEFAULT FALSE;
        mfirst_day            DATE;
        mseqtitulo            fi_inttitulo_consinco_ctl.seqtitulo%TYPE;
        mcont_par             NUMBER;
        mvalor_ind_correcao   parcela.valor_ind_correcao%TYPE;
        mmsn_error            VARCHAR2 (300);
        mcodespecie           fi_inttitulo_consinco_ctl.codespecie%TYPE;
        mmdo_codigo           operacao.mdo_codigo%TYPE;
        mcont_par_venc        NUMBER;
    BEGIN
        UPDATE fi_inttitulo_consinco_ctl
           SET inserido_flag = 'S'
         WHERE inserido_flag = 'N';

        --faço o calculo das operações antes do envio
        FOR l_calc1
            IN (SELECT DISTINCT par.opr_numero
                  FROM parcela par, operacao opr
                 WHERE     par.valor_pago = 0
                       AND par_data >= TO_DATE (SYSDATE, 'dd/mm/rrrr')
                       AND opr.opr_numero = par.opr_numero
                       AND opr.mdo_tipo <> 'A'
                       AND opr.calculada_flag = 'N'
                       AND opr.encerrada_flag = 'N'
                ORDER BY par.opr_numero)
        LOOP
            BEGIN
                calcula_opr (l_calc1.opr_numero, 1);
            END;
        END LOOP;

        COMMIT;

        SELECT TO_DATE ('01/' || TO_CHAR (SYSDATE, 'mm/yyyy'), 'dd/mm/yyyy')
          INTO mfirst_day
          FROM DUAL;

        --IF mfirst_day = TO_DATE (SYSDATE, 'dd/mm/rrrr')
        --THEN
        FOR l_calc
            IN (SELECT DISTINCT par.opr_numero
                  FROM parcela par, operacao opr
                 WHERE     par.valor_pago = 0
                       AND par_data >= TO_DATE (SYSDATE, 'dd/mm/rrrr')
                       AND opr.opr_numero = par.opr_numero
                       AND opr.mdo_tipo <> 'A'
                       AND opr.encerrada_flag = 'N'
                ORDER BY par.opr_numero)
        LOOP
            -- mcont_par := 1;

            FOR l_opr1
                IN (SELECT SUM (par.valor_valido) valor_valido,
                           par.opr_numero,
                           par.data_financeira,
                           par.par_data,
                           par.valor_calc,
                           par.valor_pago,
                           par.pfj_agente
                      FROM parcela par
                     WHERE     par.valor_pago = 0
                           AND par_data >= TO_DATE (SYSDATE, 'dd/mm/rrrr')
                           AND par.opr_numero = l_calc.opr_numero
                    GROUP BY par.opr_numero,
                             par.data_financeira,
                             par.par_data,
                             par.valor_calc,
                             par.valor_pago,
                             par.pfj_agente
                    ORDER BY par.par_data)
            LOOP
                BEGIN
                    SELECT pfj_codigo
                      INTO mpfj_codigo
                      FROM operacao
                     WHERE opr_numero = l_calc.opr_numero;

                    SELECT MAX (par_contador)
                      INTO mpar_contador
                      FROM parcela
                     WHERE     data_financeira = l_opr1.data_financeira
                           AND opr_numero = l_opr1.opr_numero;

                    --AND par_tipo = 'PRI';
                    SELECT MAX (valor_ind_correcao)
                      INTO mvalor_ind_correcao
                      FROM parcela
                     WHERE par_contador = mpar_contador;

                    --recupero o numero de parcelas armazenado na tabela de controle
                    BEGIN
                        SELECT nro_parcelas
                          INTO mcont_parcelas_ctl
                          FROM fi_inttitulo_consinco_ctl
                         WHERE opr_numero = l_opr1.opr_numero AND ROWNUM = 1;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            mcont_parcelas_ctl := NULL;
                    END;

                    --Insiro os dados nas tabelas da consinco e tabelas de controle
                    BEGIN
                        INSERT INTO consinco_operacoes (opr_numero,
                                                        data_financeira,
                                                        par_data,
                                                        valor_calc,
                                                        valor_valido,
                                                        valor_pago,
                                                        pfj_agente,
                                                        pfj_codigo,
                                                        imported_flag,
                                                        origem_pk,
                                                        par_contador)
                            VALUES (
                                       l_opr1.opr_numero,
                                       l_opr1.data_financeira,
                                       l_opr1.par_data,
                                       l_opr1.valor_calc,
                                       TRUNC (
                                             l_opr1.valor_valido
                                           * mvalor_ind_correcao,
                                           2),
                                       l_opr1.valor_pago,
                                       l_opr1.pfj_agente,
                                       mpfj_codigo,
                                       'N',
                                          'OPR#'
                                       || l_opr1.opr_numero
                                       || 'DTAFI#'
                                       || TO_CHAR (l_opr1.data_financeira,
                                                   'ddmmrrrr'),
                                       mpar_contador);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de operacoes na tabela intermediaria consinco_operacoes '
                                               || mmsn_error,
                                                  'Origem_pk = '
                                               || 'OPR#'
                                               || l_opr1.opr_numero
                                               || 'DTAFI#'
                                               || TO_CHAR (
                                                      l_opr1.data_financeira,
                                                      'ddmmrrrr'),
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;
                END;

                COMMIT;
            END LOOP;                                                -- l_opr1
        END LOOP;                                                    -- l_calc

        FOR opr_dist IN (SELECT DISTINCT opr_numero
                           FROM consinco_operacoes
                          WHERE imported_flag = 'N'
                         ORDER BY opr_numero)
        LOOP
            --recupero a quantidade de parcelas da operação
            SELECT (COUNT (DISTINCT data_financeira) - 1)
              INTO mcont_parcelas
              FROM parcela
             WHERE opr_numero = opr_dist.opr_numero;

            --recupero a quantidade de parcelas da operação vencidas
            SELECT COUNT (DISTINCT data_financeira)
              INTO mcont_par_venc
              FROM parcela
             WHERE opr_numero = opr_dist.opr_numero AND par_data <= SYSDATE;

            mcont_par := mcont_par_venc;

            FOR l_opr
                IN (SELECT *
                      FROM consinco_operacoes
                     WHERE     imported_flag = 'N'
                           AND opr_numero = opr_dist.opr_numero
                    ORDER BY par_data)
            LOOP
                BEGIN
                    morigem_pk := NULL;

                    BEGIN
                        SELECT DISTINCT
                               ctl.origem_pk, ctl.vlroriginal, seqtitulo
                          INTO morigem_pk, mvlroriginal, mseqtitulo
                          FROM fi_inttitulo_consinco_ctl ctl
                         WHERE     ctl.origem_pk = l_opr.origem_pk
                               AND ctl.opr_numero = l_opr.opr_numero;
                    EXCEPTION
                        WHEN TOO_MANY_ROWS
                        THEN
                            SELECT DISTINCT
                                   ctl.origem_pk, MAX (ctl.vlroriginal)
                              INTO morigem_pk, mvlroriginal
                              FROM fi_inttitulo_consinco_ctl ctl
                             WHERE     ctl.origem_pk = l_opr.origem_pk
                                   AND ctl.opr_numero = l_opr.opr_numero
                            GROUP BY ctl.origem_pk;
                        WHEN NO_DATA_FOUND
                        THEN
                            morigem_pk := NULL;
                            mvlroriginal := NULL;
                    END;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        morigem_pk := NULL;
                        mvlroriginal := NULL;
                END;

                IF l_opr.valor_valido > mvlroriginal
                THEN
                    mcodoperacao := 36;
                ELSE
                    mcodoperacao := 37;
                END IF;

                consinco.pkg_financeiro.fip_buscaseqfi (pnseq);
                consinco.pkg_financeiro.fip_buscaseqfi (pnseq1);
                consinco.pkg_financeiro.fip_buscaseqfi (pnseq2);

                SELECT nroempresa, nroempresamae
                  INTO mnroempresa, mnroempresamae
                  FROM consinco.fi_parametro a
                 WHERE a.nroempresa = mpfj_codigo;

                SELECT pfj_codigo, pfj_agente
                  INTO mpfj_codigo, mpfj_agente
                  FROM operacao
                 WHERE opr_numero = l_opr.opr_numero;

                SELECT cgc
                  INTO mcgc
                  FROM pessoa
                 WHERE pfj_codigo = mpfj_agente;

                mcgc :=
                    SUBSTR (
                        REPLACE (REPLACE (REPLACE (mcgc, '.'), '-'), '/'),
                        1,
                        12);

                --recupero a modelo para enviar para a consinco como codedpecie
                SELECT mdo_codigo
                  INTO mmdo_codigo
                  FROM operacao
                 WHERE opr_numero = l_opr.opr_numero;

                BEGIN
                    SELECT especie
                      INTO mcodespecie
                      FROM consinco_modelo_x_especie
                     WHERE modelo = mmdo_codigo;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        mcodespecie := 'DUPP';

                        INSERT INTO consinco_modelo_x_especie
                        VALUES (mmdo_codigo, mcodespecie);
                END;

                COMMIT;

                -- Envio das parcelas alteradas
                IF     morigem_pk = l_opr.origem_pk
                   AND mvlroriginal <> l_opr.valor_valido
                THEN
                    DELETE FROM fi_inttitulo_consinco_ctl
                     WHERE origem_pk = l_opr.origem_pk;

                    DELETE FROM fi_inttituloope_consinco_ctl
                     WHERE origem_pk = l_opr.origem_pk;

                    DELETE FROM consinco_operacoes
                     WHERE     origem_pk = l_opr.origem_pk
                           AND imported_flag = 'N';

                    COMMIT;
                    mvalorreal := l_opr.valor_valido - mvlroriginal;

                    BEGIN
                        BEGIN
                            INSERT
                              INTO fi_inttitulo_consinco_ctl (
                                       seqinttitulo,
                                       tiporegistro,
                                       nroempresamae,
                                       nroempresa,
                                       codespecie,
                                       tipocodpessoa,
                                       codpessoa,
                                       tipocodpessoanota,
                                       codpessoanota,
                                       nrotitulo,
                                       serietitulo,
                                       nroparcela,
                                       nrodocumento,
                                       seriedoc,
                                       vlroriginal,
                                       dtaemissao,
                                       dtavencimento,
                                       tipovencoriginal,
                                       observacao,
                                       tituloemitido,
                                       seqctacorrente,
                                       titulocaixa,
                                       tiponegociacao,
                                       dtamovimento,
                                       situacao,
                                       seqtitulo,
                                       usualteracao,
                                       sitjuridica,
                                       nroprocesso,
                                       codcarteira,
                                       estorno_flag,
                                       opr_numero,
                                       nro_parcelas,
                                       data_financeira,
                                       origem_pk,
                                       inserido_flag)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           '8',
                                           --TIPOREGISTRO
                                           mnroempresa,        --NROEMPRESAMAE
                                           mnroempresamae,        --NROEMPRESA
                                           mcodespecie,           --CODESPECIE
                                           '2',
                                           --TIPOCODPESSOA
                                           mcgc,                   --CODPESSOA
                                           '2',            --TIPOCODPESSOANOTA
                                           mcgc,               --CODPESSOANOTA
                                           l_opr.opr_numero,       --NROTITULO
                                           'XRT',
                                           --SERIETITULO
                                           mcont_par,             --NROPARCELA
                                           l_opr.opr_numero,    --NRODOCUMENTO
                                           l_opr.opr_numero,
                                           --SERIEDOC
                                           l_opr.valor_valido,
                                           --VLRORIGINAL
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAEMISSAO
                                           l_opr.par_data,
                                           --DTAVENCIMENTO
                                           'P',
                                           --TIPOVENCORIGINAL
                                           l_opr.opr_numero,      --OBSERVACAO
                                           'S',
                                           --TITULOEMITIDO
                                           NULL,              --SEQCTACORRENTE
                                           'T',                  --TITULOCAIXA
                                           'BLT',             --TIPONEGOCIACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAMOVIMENTO
                                           NULL,                    --SITUACAO
                                           pnseq1,                 --SEQTITULO
                                           'SAGE_XRT',          --USUALTERACAO
                                           'N',                  --SITJURIDICA
                                           pnseq2,               --NROPROCESSO
                                           'S',                  --codcarteira
                                           'N',
                                           l_opr.opr_numero,
                                           mcont_parcelas,
                                           l_opr.data_financeira,
                                              'OPR#'
                                           || l_opr.opr_numero
                                           || 'DTAFI#'
                                           || TO_CHAR (l_opr.data_financeira,
                                                       'ddmmrrrr'),
                                           'N');
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela intermediaria consinco_operacoes '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;

                        BEGIN
                            INSERT
                              INTO fi_inttituloope_consinco_ctl (
                                       seqinttitulo,
                                       codoperacao,
                                       vlroperacao,
                                       anotacao,
                                       seqtitoperacao,
                                       dtaoperacao,
                                       dtacontabilizacao,
                                       nrotitulo,
                                       origem_pk)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           mcodoperacao,         --CODOPERACAO
                                           l_opr.valor_valido,
                                              --VLROPERACAO
                                              l_opr.opr_numero
                                           || '/'
                                           || l_opr.par_tipo,
                                           --ANOTACAO
                                           pnseq1,
                                           --SEQTITOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           mpar_contador,
                                              --DTACONTABILIZACAO
                                              'OPR#'
                                           || l_opr.opr_numero
                                           || 'DTAFI#'
                                           || TO_CHAR (l_opr.data_financeira,
                                                       'ddmmrrrr'));

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de operacoes na tabela de controle fi_inttituloope_consinco_ctl '
                                               || mmsn_error,
                                                  'Origem_pk = '
                                               || 'OPR#'
                                               || l_opr.opr_numero
                                               || 'DTAFI#'
                                               || TO_CHAR (
                                                      l_opr.data_financeira,
                                                      'ddmmrrrr'),
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                        END;

                        COMMIT;

                        BEGIN
                            INSERT
                              INTO consinco.fi_inttitulo (seqinttitulo,
                                                          tiporegistro,
                                                          nroempresamae,
                                                          nroempresa,
                                                          codespecie,
                                                          tipocodpessoa,
                                                          codpessoa,
                                                          tipocodpessoanota,
                                                          codpessoanota,
                                                          nrotitulo,
                                                          serietitulo,
                                                          nroparcela,
                                                          nrodocumento,
                                                          seriedoc,
                                                          vlroriginal,
                                                          dtaemissao,
                                                          dtavencimento,
                                                          tipovencoriginal,
                                                          observacao,
                                                          tituloemitido,
                                                          seqctacorrente,
                                                          titulocaixa,
                                                          tiponegociacao,
                                                          dtamovimento,
                                                          situacao,
                                                          seqtitulo,
                                                          usualteracao,
                                                          sitjuridica,
                                                          nroprocesso,
                                                          codcarteira)
                            VALUES (pnseq,                      --SEQINTTITULO
                                    '8',
                                    --TIPOREGISTRO
                                    mnroempresa,               --NROEMPRESAMAE
                                    mnroempresamae,               --NROEMPRESA
                                    mcodespecie,                  --CODESPECIE
                                    '2',
                                    --TIPOCODPESSOA
                                    mcgc,                          --CODPESSOA
                                    '2',                   --TIPOCODPESSOANOTA
                                    mcgc,                      --CODPESSOANOTA
                                    l_opr.opr_numero,              --NROTITULO
                                    'XRT',
                                    --SERIETITULO
                                    mcont_par,                    --NROPARCELA
                                    l_opr.opr_numero,           --NRODOCUMENTO
                                    l_opr.opr_numero,
                                    --SERIEDOC
                                    l_opr.valor_valido,
                                    --VLRORIGINAL
                                    TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                    --DTAEMISSAO
                                    l_opr.par_data,
                                    --DTAVENCIMENTO
                                    'P',
                                    --TIPOVENCORIGINAL
                                    l_opr.opr_numero,             --OBSERVACAO
                                    'S',
                                    --TITULOEMITIDO
                                    NULL,                     --SEQCTACORRENTE
                                    'T',                         --TITULOCAIXA
                                    'BLT',                    --TIPONEGOCIACAO
                                    TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                    --DTAMOVIMENTO
                                    NULL,                           --SITUACAO
                                    mseqtitulo,                    --SEQTITULO
                                    'SAGE_XRT',                 --USUALTERACAO
                                    'N',                         --SITJURIDICA
                                    pnseq2,                      --NROPROCESSO
                                    'S'                          --codcarteira
                                       );
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttitulo '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;

                        BEGIN
                            INSERT
                              INTO consinco.fi_inttituloope (
                                       seqinttitulo,
                                       codoperacao,
                                       vlroperacao,
                                       anotacao,
                                       seqtitoperacao,
                                       dtaoperacao,
                                       dtacontabilizacao)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           mcodoperacao,         --CODOPERACAO
                                           ABS (mvalorreal),
                                              --VLROPERACAO
                                              l_opr.opr_numero
                                           || '/'
                                           || l_opr.par_tipo,
                                           --ANOTACAO
                                           pnseq1,
                                           --SEQTITOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr') --DTACONTABILIZACAO
                                                                          );
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttituloope '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;
                    END;

                    COMMIT;
                -- mcont_par := mcont_par + 1;
                -- Envio das parcelas novas
                ELSIF morigem_pk IS NULL
                THEN
                    BEGIN
                        BEGIN
                            INSERT
                              INTO fi_inttitulo_consinco_ctl (
                                       seqinttitulo,
                                       tiporegistro,
                                       nroempresamae,
                                       nroempresa,
                                       codespecie,
                                       tipocodpessoa,
                                       codpessoa,
                                       tipocodpessoanota,
                                       codpessoanota,
                                       nrotitulo,
                                       serietitulo,
                                       nroparcela,
                                       nrodocumento,
                                       seriedoc,
                                       vlroriginal,
                                       dtaemissao,
                                       dtavencimento,
                                       tipovencoriginal,
                                       observacao,
                                       tituloemitido,
                                       seqctacorrente,
                                       titulocaixa,
                                       tiponegociacao,
                                       dtamovimento,
                                       situacao,
                                       seqtitulo,
                                       usualteracao,
                                       sitjuridica,
                                       nroprocesso,
                                       codcarteira,
                                       estorno_flag,
                                       opr_numero,
                                       nro_parcelas,
                                       data_financeira,
                                       origem_pk,
                                       inserido_flag)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           '1',
                                           --TIPOREGISTRO
                                           mnroempresa,        --NROEMPRESAMAE
                                           mnroempresamae,        --NROEMPRESA
                                           mcodespecie,
                                           --CODESPECIE
                                           '2',                --TIPOCODPESSOA
                                           mcgc,                   --CODPESSOA
                                           '2',            --TIPOCODPESSOANOTA
                                           mcgc,               --CODPESSOANOTA
                                           l_opr.opr_numero,       --NROTITULO
                                           'XRT',
                                           --SERIETITULO
                                           mcont_par,             --NROPARCELA
                                           l_opr.opr_numero,    --NRODOCUMENTO
                                           l_opr.opr_numero,
                                           --SERIEDOC
                                           l_opr.valor_valido,
                                           --VLRORIGINAL
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAEMISSAO
                                           l_opr.par_data,
                                           --DTAVENCIMENTO
                                           'P',
                                           --TIPOVENCORIGINAL
                                           l_opr.opr_numero,      --OBSERVACAO
                                           'S',
                                           --TITULOEMITIDO
                                           NULL,              --SEQCTACORRENTE
                                           'T',                  --TITULOCAIXA
                                           'BLT',             --TIPONEGOCIACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAMOVIMENTO
                                           NULL,                    --SITUACAO
                                           pnseq1,                 --SEQTITULO
                                           'SAGE_XRT',          --USUALTERACAO
                                           'N',                  --SITJURIDICA
                                           pnseq2,               --NROPROCESSO
                                           'S',                  --codcarteira
                                           'N',
                                           l_opr.opr_numero,
                                           mcont_parcelas,
                                           l_opr.data_financeira,
                                              'OPR#'
                                           || l_opr.opr_numero
                                           || 'DTAFI#'
                                           || TO_CHAR (l_opr.data_financeira,
                                                       'ddmmrrrr'),
                                           'N');
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela de controle fi_inttitulo_consinco_ctl '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;

                        BEGIN
                            INSERT
                              INTO fi_inttituloope_consinco_ctl (
                                       seqinttitulo,
                                       codoperacao,
                                       vlroperacao,
                                       anotacao,
                                       seqtitoperacao,
                                       dtaoperacao,
                                       dtacontabilizacao,
                                       nrotitulo,
                                       origem_pk)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           '16',                 --CODOPERACAO
                                           l_opr.valor_valido,
                                              --VLROPERACAO
                                              l_opr.opr_numero
                                           || '/'
                                           || l_opr.par_tipo,
                                           --ANOTACAO
                                           pnseq,
                                           --SEQTITOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           mpar_contador,
                                              --DTACONTABILIZACAO
                                              'OPR#'
                                           || l_opr.opr_numero
                                           || 'DTAFI#'
                                           || TO_CHAR (l_opr.data_financeira,
                                                       'ddmmrrrr'));
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela de controle fi_inttituloope_consinco_ctl '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;

                        COMMIT;

                        BEGIN
                            INSERT
                              INTO consinco.fi_inttitulo (seqinttitulo,
                                                          tiporegistro,
                                                          nroempresamae,
                                                          nroempresa,
                                                          codespecie,
                                                          tipocodpessoa,
                                                          codpessoa,
                                                          tipocodpessoanota,
                                                          codpessoanota,
                                                          nrotitulo,
                                                          serietitulo,
                                                          nroparcela,
                                                          nrodocumento,
                                                          seriedoc,
                                                          vlroriginal,
                                                          dtaemissao,
                                                          dtavencimento,
                                                          tipovencoriginal,
                                                          observacao,
                                                          tituloemitido,
                                                          seqctacorrente,
                                                          titulocaixa,
                                                          tiponegociacao,
                                                          dtamovimento,
                                                          situacao,
                                                          seqtitulo,
                                                          usualteracao,
                                                          sitjuridica,
                                                          nroprocesso,
                                                          codcarteira)
                            VALUES (pnseq,                      --SEQINTTITULO
                                    '1',
                                    --TIPOREGISTRO
                                    mnroempresa,               --NROEMPRESAMAE
                                    mnroempresamae,               --NROEMPRESA
                                    mcodespecie,
                                    --CODESPECIE
                                    '2',                       --TIPOCODPESSOA
                                    mcgc,                          --CODPESSOA
                                    '2',                   --TIPOCODPESSOANOTA
                                    mcgc,                      --CODPESSOANOTA
                                    l_opr.opr_numero,              --NROTITULO
                                    'XRT',
                                    --SERIETITULO
                                    mcont_par,                    --NROPARCELA
                                    l_opr.opr_numero,           --NRODOCUMENTO
                                    l_opr.opr_numero,
                                    --SERIEDOC
                                    l_opr.valor_valido,
                                    --VLRORIGINAL
                                    TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                    --DTAEMISSAO
                                    l_opr.par_data,
                                    --DTAVENCIMENTO
                                    'P',
                                    --TIPOVENCORIGINAL
                                    l_opr.opr_numero,             --OBSERVACAO
                                    'S',
                                    --TITULOEMITIDO
                                    NULL,                     --SEQCTACORRENTE
                                    'T',                         --TITULOCAIXA
                                    'BLT',                    --TIPONEGOCIACAO
                                    TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                    --DTAMOVIMENTO
                                    NULL,                           --SITUACAO
                                    pnseq1,                        --SEQTITULO
                                    'SAGE_XRT',                 --USUALTERACAO
                                    'N',                         --SITJURIDICA
                                    pnseq2,                      --NROPROCESSO
                                    'S'                          --codcarteira
                                       );
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttitulo '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;

                        BEGIN
                            INSERT
                              INTO consinco.fi_inttituloope (
                                       seqinttitulo,
                                       codoperacao,
                                       vlroperacao,
                                       anotacao,
                                       seqtitoperacao,
                                       dtaoperacao,
                                       dtacontabilizacao)
                                VALUES (
                                           pnseq,               --SEQINTTITULO
                                           '16',                 --CODOPERACAO
                                           l_opr.valor_valido,
                                              --VLROPERACAO
                                              l_opr.opr_numero
                                           || '/'
                                           || l_opr.par_tipo,
                                           --ANOTACAO
                                           pnseq1,
                                           --SEQTITOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr'),
                                           --DTAOPERACAO
                                           TO_DATE (SYSDATE, 'dd/mm/rrrr') --DTACONTABILIZACAO
                                                                          );
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                mmsn_error := SUBSTR (SQLERRM, 1, 200);

                                BEGIN
                                    INSERT INTO consinco_sage_itf_log
                                        VALUES (
                                                      'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttituloope '
                                                   || mmsn_error,
                                                      'Origem_pk = '
                                                   || 'OPR#'
                                                   || l_opr.opr_numero
                                                   || 'DTAFI#'
                                                   || TO_CHAR (
                                                          l_opr.data_financeira,
                                                          'ddmmrrrr'),
                                                   SYSDATE);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                        END;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                --mcont_par := mcont_par + 1;
                ELSIF     morigem_pk = l_opr.origem_pk
                      AND mvlroriginal = l_opr.valor_valido
                THEN
                    mimportado := TRUE;

                    DELETE FROM consinco_operacoes
                     WHERE     origem_pk = l_opr.origem_pk
                           AND imported_flag = 'N';

                    COMMIT;
                END IF;

                UPDATE consinco_operacoes
                   SET imported_flag = 'S'
                 WHERE     par_contador = l_opr.par_contador
                       AND imported_flag = 'N'
                       AND origem_pk = l_opr.origem_pk;

                COMMIT;

                IF mimportado = FALSE
                THEN
                    DELETE fi_inttitulo_consinco_ctl
                     WHERE     inserido_flag = 'S'
                           AND origem_pk = l_opr.origem_pk;

                    COMMIT;
                --mcont_par := mcont_par + 1;
                END IF;

                mcont_par := mcont_par + 1;
            END LOOP;
        END LOOP;

        --Envio o estorno da parcelas
        BEGIN
            FOR estorno_opr
                IN (SELECT ctl.seqinttitulo,
                           ctl.tiporegistro,
                           ctl.nroempresamae,
                           ctl.nroempresa,
                           ctl.codespecie,
                           ctl.tipocodpessoa,
                           ctl.codpessoa,
                           ctl.tipocodpessoanota,
                           ctl.codpessoanota,
                           ctl.nrotitulo,
                           ctl.serietitulo,
                           ctl.nroparcela,
                           ctl.nrodocumento,
                           ctl.seriedoc,
                           ctl.vlroriginal,
                           ctl.dtaemissao,
                           ctl.dtavencimento,
                           ctl.tipovencoriginal,
                           ctl.observacao,
                           ctl.tituloemitido,
                           ctl.seqctacorrente,
                           ctl.titulocaixa,
                           ctl.tiponegociacao,
                           ctl.dtamovimento,
                           ctl.situacao,
                           ctl.seqtitulo,
                           ctl.usualteracao,
                           ctl.sitjuridica,
                           oope.seqinttitulo seqinttitulo_oope,
                           oope.codoperacao,
                           oope.vlroperacao,
                           oope.anotacao,
                           oope.seqtitoperacao,
                           oope.dtaoperacao,
                           oope.dtacontabilizacao,
                           ctl.origem_pk
                      FROM fi_inttitulo_consinco_ctl ctl,
                           fi_inttituloope_consinco_ctl oope
                     WHERE     ctl.nrotitulo = ctl.nrotitulo
                           AND ctl.seqinttitulo = oope.seqinttitulo
                           AND ctl.estorno_flag = 'N'
                           AND NOT EXISTS
                                   (SELECT 1
                                      FROM parcela par
                                     WHERE    'OPR#'
                                           || par.opr_numero
                                           || 'DTAFI#'
                                           || TO_CHAR (par.data_financeira,
                                                       'ddmmrrrr') =
                                               ctl.origem_pk))
            LOOP
                BEGIN
                    consinco.pkg_financeiro.fip_buscaseqfi (pnseq_estorno);

                    BEGIN
                        INSERT INTO consinco.fi_inttitulo (seqinttitulo,
                                                           tiporegistro,
                                                           nroempresamae,
                                                           nroempresa,
                                                           codespecie,
                                                           tipocodpessoa,
                                                           codpessoa,
                                                           tipocodpessoanota,
                                                           codpessoanota,
                                                           nrotitulo,
                                                           serietitulo,
                                                           nroparcela,
                                                           nrodocumento,
                                                           seriedoc,
                                                           vlroriginal,
                                                           dtaemissao,
                                                           dtavencimento,
                                                           tipovencoriginal,
                                                           observacao,
                                                           tituloemitido,
                                                           seqctacorrente,
                                                           titulocaixa,
                                                           tiponegociacao,
                                                           dtamovimento,
                                                           situacao,
                                                           seqtitulo,
                                                           usualteracao,
                                                           sitjuridica,
                                                           nroprocesso,
                                                           codcarteira)
                        VALUES (pnseq_estorno,                  --SEQINTTITULO
                                '2',
                                --TIPOREGISTRO
                                estorno_opr.nroempresamae,
                                --NROEMPRESAMAE
                                estorno_opr.nroempresa,
                                --NROEMPRESA
                                'DUPP',                           --CODESPECIE
                                '2',                           --TIPOCODPESSOA
                                estorno_opr.codpessoa,             --CODPESSOA
                                '2',
                                --TIPOCODPESSOANOTA
                                estorno_opr.codpessoanota,     --CODPESSOANOTA
                                estorno_opr.nrotitulo,             --NROTITULO
                                estorno_opr.serietitulo,
                                --SERIETITULO
                                estorno_opr.nroparcela,           --NROPARCELA
                                estorno_opr.nrodocumento,       --NRODOCUMENTO
                                estorno_opr.seriedoc,
                                --SERIEDOC
                                estorno_opr.vlroriginal,
                                --VLRORIGINAL
                                estorno_opr.dtaemissao,
                                --DTAEMISSAO
                                estorno_opr.dtavencimento,
                                --DTAVENCIMENTO
                                'P',
                                --TIPOVENCORIGINAL
                                estorno_opr.observacao,           --OBSERVACAO
                                'S',                           --TITULOEMITIDO
                                NULL,
                                --SEQCTACORRENTE
                                'T',                             --TITULOCAIXA
                                'BLT',                        --TIPONEGOCIACAO
                                estorno_opr.dtamovimento,
                                --DTAMOVIMENTO
                                NULL,
                                --SITUACAO
                                estorno_opr.seqtitulo,             --SEQTITULO
                                'SAGE_XRT',
                                --USUALTERACAO
                                'N',                             --SITJURIDICA
                                pnseq2,                          --NROPROCESSO
                                'S'                              --codcarteira
                                   );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttitulo '
                                               || mmsn_error,
                                                  'Origem_pk = '
                                               || estorno_opr.origem_pk,
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;

                    COMMIT;

                    BEGIN
                        INSERT
                          INTO consinco.fi_inttituloope (seqinttitulo,
                                                         codoperacao,
                                                         vlroperacao,
                                                         anotacao,
                                                         seqtitoperacao,
                                                         dtaoperacao,
                                                         dtacontabilizacao)
                        VALUES (estorno_opr.seqinttitulo_oope,
                                --SEQINTTITULO
                                '16',
                                --CODOPERACAO
                                estorno_opr.vlroperacao,
                                --VLROPERACAO
                                estorno_opr.anotacao,
                                --ANOTACAO
                                estorno_opr.seqtitoperacao,
                                --SEQTITOPERACAO
                                estorno_opr.dtaoperacao,
                                --DTAOPERACAO
                                estorno_opr.dtacontabilizacao --DTACONTABILIZACAO
                                                             );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            mmsn_error := SUBSTR (SQLERRM, 1, 200);

                            BEGIN
                                INSERT INTO consinco_sage_itf_log
                                    VALUES (
                                                  'Erro para gravar dados de operacoes na tabela da consinco consinco.fi_inttituloope '
                                               || mmsn_error,
                                                  'Origem_pk = '
                                               || estorno_opr.origem_pk,
                                               SYSDATE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                    END;
                END;

                UPDATE fi_inttitulo_consinco_ctl
                   SET estorno_flag = 'S'
                 WHERE origem_pk = estorno_opr.origem_pk;

                COMMIT;
            END LOOP;
        END;

        COMMIT;
    -- END IF;

    END;                       -- fim da procedure consinco_sage_titulo_mensal
END;
