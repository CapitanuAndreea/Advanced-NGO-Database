CREATE OR REPLACE PROCEDURE afisare_taskuri
 IS
    v_id_membru TASK.ID_MEMBRU%TYPE;
    
    CURSOR c_membri_activi IS
        SELECT ID_MEMBRU
        FROM MEMBRI_ACTIVI;
    
    CURSOR c_taskuri_membri(p_id_membru TASK.ID_MEMBRU%TYPE) IS
        SELECT *
        FROM TASK
        WHERE ID_MEMBRU = p_id_membru;
        
BEGIN 
    FOR membri_rec IN c_membri_activi LOOP
        v_id_membru := membri_rec.ID_MEMBRU;
        DBMS_OUTPUT.PUT_LINE('ID_MEMBRU: ' || v_id_membru);
        FOR task_rec IN c_taskuri_membri(v_id_membru) LOOP
            DBMS_OUTPUT.PUT_LINE(' TASK ID: ' || task_rec.ID_TASK || ', Status: ' || task_rec.STATUS);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('---------------------');
    END LOOP;
END afisare_taskuri;
/

BEGIN
    afisare_taskuri;
END;
/
