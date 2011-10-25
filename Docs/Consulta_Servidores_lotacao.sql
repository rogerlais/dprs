/* listagem das unidades validas */
/*
select cd,ds,sigla_unid_tse,cod_unid_super from unidade_tse where sit_unid in ('OF','C','OT','ON','OS')
*/




select siglas.sigla_unid_tse, nomes.nom, nomes.e_mail, nomes.e_mail_externo, serv.FONE_LOT_SERVIDOR, serv.MAT_SERVIDOR, serv.COD_UNID_TSE, serv.DT_INI_LOTACAO, serv.DT_FIM_LOTACAO
from 
    srh2.servidor nomes, srh2.unidade_tse siglas, srh2.lotacao serv
left join 
( select mat_servidor, max( dt_ini_lotacao ) llotacao from srh2.lotacao 
    where 
        ( dt_fim_lotacao is null ) 
    group by mat_servidor ) lot 
on 
    ( lot.mat_servidor = serv.mat_servidor ) and ( lot.llotacao = serv.dt_ini_lotacao )
where
    (dt_fim_lotacao is null ) and ( nomes.mat_servidor = serv.mat_servidor ) and ( siglas.cd = serv.COD_UNID_TSE )
order by 1,2;
