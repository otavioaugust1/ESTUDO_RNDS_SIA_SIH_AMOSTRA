select 
 a.nu_cpf_paciente,
 a.nu_cns_paciente,
 a.co_sigtap,
 a.sg_uf_estab_executante, 
 a.co_municipio_estab_executante, 
 a.co_cnes_estab_executante,
 TO_CHAR(a.dt_solicitacao,'DD/MM/YYYY') AS data_solicitacao,
 TO_CHAR(a.dt_autorizacao,'DD/MM/YYYY') AS data_autorizacao,
 TO_CHAR(a.dt_execucao,'DD/MM/YYYY') AS data_execucao, 
 a.st_vida_paciente,
 a.st_solicitacao,
 a.id_registro_sistema_origem,
 a.ds_sistema_origem 
 FROM  
    dbra.tb_ra a 
WHERE  
    a.st_documento_rnds = 'final'                               -- Documento final ou última alteração no RNDS
    AND a.dt_agendamento BETWEEN TO_DATE('01/07/2024', 'DD/MM/YYYY') AND TO_DATE('30/06/2025', 'DD/MM/YYYY')