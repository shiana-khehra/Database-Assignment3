-- Part 1
CREATE OR REPLACE FUNCTION func_permissions_okay
	RETURN VARCHAR2
	IS
	  lv_permission VARCHAR2(2);
BEGIN
	SELECT COUNT(*)
	INTO lv_permission
	FROM USER_TAB_PRIVS
	WHERE privilege = 'EXECUTE' AND table_name = 'UTL_FILE';
	
	IF lv_permission > 0 THEN
	RETURN 'Y';
	ELSE
	RETURN 'N';
	END IF;
EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

-- Part 2
CREATE OR REPLACE TRIGGER payroll_load_trg
	BEFORE INSERT ON payroll_load
	FOR EACH ROW
DECLARE
	v_desc VARCHAR2(100);
BEGIN
	v_desc := CONCAT('Payroll processed for employee ' , :NEW.employee_id);
	INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, :NEW.payroll_date, v_desc, 4045, 'D', :NEW.amount);
	INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, :NEW.payroll_date, v_desc, 2050, 'C', :NEW.amount);
	:NEW.status := 'G';
EXCEPTION
	WHEN OTHERS THEN
	:NEW.status := 'B';
END;
/
	
-- Part 3
CREATE OR REPLACE PROCEDURE proc_month_end
IS
	CURSOR account_cur IS
	SELECT * 
	FROM account
	WHERE account_type_code = 'EX' OR account_type_code = 'RE';
BEGIN
	FOR account_rec IN account_cur LOOP
		IF account_rec.account_balance > 0 THEN
			IF account_rec.account_type_code = 'RE' THEN
				INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, SYSDATE, 'Month end processing executed', account_rec.account_no, 'D', account_rec.account_balance);
				INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, SYSDATE, 'Month end processing executed', 5555, 'C', account_rec.account_balance);
			ELSE 
				INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, SYSDATE, 'Month end processing executed', account_rec.account_no, 'C', account_rec.account_balance);
				INSERT INTO new_transactions VALUES (wkis_seq.NEXTVAL, SYSDATE, 'Month end processing executed', 5555, 'D', account_rec.account_balance);
			END IF;
		END IF;
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

-- Part 4	
CREATE OR REPLACE PROCEDURE proc_export_csv
	(p_alias IN VARCHAR2,
	 p_file_name IN VARCHAR2)
IS
	v_fhandle UTL_FILE.FILE_TYPE;
	v_uppercase_alias VARCHAR2(200);
	CURSOR new_trans_cur IS
	SELECT *
	FROM new_transactions;
BEGIN
	v_uppercase_alias := UPPER(p_alias);
	v_fhandle := UTL_FILE.FOPEN(v_uppercase_alias, p_file_name, 'w' );
	UTL_FILE.PUT(v_fhandle,','|| 'Transaction_no');
    UTL_FILE.PUT(v_fhandle,','|| 'Transaction_date');
    UTL_FILE.PUT(v_fhandle,','|| 'Description');
    UTL_FILE.PUT(v_fhandle,','|| 'Account_no');
	UTL_FILE.PUT(v_fhandle,','|| 'Transaction_type');
	UTL_FILE.PUT(v_fhandle,','|| 'Transaction_amount');
	UTL_FILE.NEW_LINE(v_fhandle);
	FOR new_trans_rec IN new_trans_cur LOOP
		UTL_FILE.PUT(v_fhandle,','||new_trans_rec.transaction_no);
        UTL_FILE.PUT(v_fhandle,','||new_trans_rec.transaction_date);
        UTL_FILE.PUT(v_fhandle,','||new_trans_rec.description);
        UTL_FILE.PUT(v_fhandle,','||new_trans_rec.account_no);
		UTL_FILE.PUT(v_fhandle,','||new_trans_rec.transaction_type);
		UTL_FILE.PUT(v_fhandle,','||new_trans_rec.transaction_amount);
        UTL_FILE.NEW_LINE(v_fhandle);
	END LOOP;
	UTL_FILE.FCLOSE(v_fhandle);
EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLCODE || ' - ' || SQLERRM);
END;
/	