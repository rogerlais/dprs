unit vvsConsts;

interface


const
    SUBJECT_TEMPLATE  = 'VVerService - Versão: %s - %s - %s';
	 SWITCH_AUTOCONFIG = 'autoconfig'; //informa que durante as operações de download a janela de interação não será mostrada
    DBG_CLIENT_COMPUTERNAME = 'ZPB999WKS9999';

	 TOKEN_DELIMITER = #13#10;
	 STR_CMD_VERB = 'verb=';
	 STR_VERB_READCONTENT = 'readcontent';
	 STR_END_SESSION_SIGNATURE = '=end_session';
	 STR_BEGIN_SESSION_SIGNATURE = '=start_session';
	 STR_OK_PACK     = 'OK';
	 STR_FAIL_HASH   = 'FAIL HASH';
	 STR_FAIL_SIZE   = 'FAIL SIZE';
	 STR_FAIL_VERB   = 'FAIL VERB';

	 II_SERVER_IDLE  = 0;
	 II_SERVER_ERROR = 1;
	 II_SERVER_BUZY  = 2;
	 II_SERVER_OK    = 3;
	 II_CLIENT_IDLE  = 0;
	 II_CLIENT_ERROR = 1;
	 II_CLIENT_BUZY  = 2;
	 II_CLIENT_OK    = 3;



implementation

end.
